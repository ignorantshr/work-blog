copying模式的磁盘转换过程
(**
    There is a progression during conversion: source -> overlay ->
    target: We start with a description of the source VM (or physical
    machine for virt-p2v) with one or more source disks.  We place
    wriable overlay(s) on top of the source disk(s).  We do the
    conversion into the overlay(s).  We copy the overlay(s) to the
    target disk(s).

    (This progression does not apply for [--in-place] conversions
    which happen on the source only.)

    Overlay disks contain a pointer back to source disks.
    Target disks contain a pointer back to overlay disks.
*)
┌──────┐
│source│
│struct│
└──┬───┘
   │    ┌───────┐  ┌───────┐  ┌───────┐
   └────┤ disk1 ├──┤ disk2 ├──┤ disk3 │  Source disks
        └───▲───┘  └───▲───┘  └───▲───┘  (source.s_disks)
            │          │          │
            │          │          │ overlay.ov_source
        ┌───┴───┐  ┌───┴───┐  ┌───┴───┐
        │ ovl1  ├──┤ ovl2  ├──┤ ovl3  │  Overlay disks
        └───▲───┘  └───▲───┘  └───▲───┘
            │          │          │
            │          │          │ target.target_overlay
        ┌───┴───┐  ┌───┴───┐  ┌───┴───┐
        │ targ1 ├──┤ targ2 ├──┤ targ3 │  Target disks
        └───────┘  └───────┘  └───────┘

type source = {
  s_hypervisor : source_hypervisor;     (** Source hypervisor. *)
  s_name : string;                      (** Guest name. *)
  s_orig_name : string;                 (** Original guest name (if we rename
                                            the guest using -on, original is
                                            still saved here). *)
  s_memory : int64;                     (** Memory size (bytes). *)
  s_vcpu : int;                         (** Number of CPUs. *)
  s_features : string list;             (** Machine features. *)
  s_firmware : source_firmware;         (** Firmware (BIOS or EFI). *)
  s_display : source_display option;    (** Guest display. *)
  s_video : source_video option;        (** Video adapter. *)
  s_sound : source_sound option;        (** Sound card. *)
  s_disks : source_disk list;           (** Disk images. *)
  s_removables : source_removable list; (** CDROMs etc. *)
  s_nics : source_nic list;             (** NICs. *)
}
(** The source: metadata, disk images. *)

let rec main() = 
	解析命令行(*input 是命令行输入参数对象，比如 -i ova centos2.ova；
	output 是命令行输出参数对象，比如 -o local -os /var/tmp/*)
	let cmdline, input, output = parse_cmdline () in
  
	输入输出检查
  	input#precheck ();
  	output#precheck ();

  	解析输入，存储到source结构体中
  	let source = open_source cmdline input in
  	let source = set_source_name cmdline source in
  	let source = set_source_networks_and_bridges cmdline source in

  	设置转换模式
  	let conversion_mode =
    if not cmdline.in_place then (
      check_host_free_space ();
      创建overlays磁盘
      let overlays = create_overlays source.s_disks in
      let targets = init_targets cmdline output source overlays in
      Copying (overlays, targets)
    )
    else In_place in


    创建新的libguestfs处理器，identifier指定工具即 v2v、p2v等处理程序
    let g = open_guestfs ~identifier:"v2v" () in
CONFIG过程
    设置内存、网络
    g#set_memsize (g#get_memsize () * 20 / 5);
    g#set_network true;

  	(match conversion_mode with
  		    			使用 qcow2 overlays 填充 guestfs handle 选项
   		| Copying (overlays, _) -> populate_overlays g overlays
   						使用 source disks 填充 guestfs handle 选项
   		| In_place -> populate_disks g source.s_disks
  	);

LAUNCHING过程
  	启动子进程，执行过程中状态机的由CONFIG变为LAUNCHING。成功的话就会启动daemon，状态变为READY。
  	由C语言调用 libguestfs API 完成
  	g#launch ();

READY之后
	检查源磁盘，返回检测数据
	(*type inspect = {
	  i_root : string;                      (** Root device. *)
	  i_type : string;                      (** Usual inspection fields. *)
	  i_distro : string;
	  i_arch : string;
	  i_major_version : int;
	  i_minor_version : int;
	  i_package_format : string;
	  i_package_management : string;
	  i_product_name : string;
	  i_product_variant : string;
	  i_mountpoints : (string * string) list;
	  i_apps : Guestfs.application2 list;   (** List of packages installed. *)
	  i_apps_map : Guestfs.application2 list StringMap.t;
	    (** This is a map from the app name to the application object.
	        Since RPM allows multiple packages with the same name to be
	        installed, the value is a list. *)
	  i_firmware : i_firmware;
	    (** The list of EFI system partitions for the guest with UEFI,
	        otherwise the BIOS identifier. *)
	  i_windows_systemroot : string;
	  i_windows_software_hive : string;
	  i_windows_system_hive : string;
	  i_windows_current_control_set : string;
	}*)
  	let inspect = Inspect_source.inspect_source cmdline.root_choice g in

  	从挂载点收集设备信息，返回一个映射列表
  	(*{ mp_dev = dev; mp_path = path; mp_statvfs = statvfs; mp_vfs = vfs }, ...*)
  	let mpstats = get_mpstats g in
  	检查虚拟机空间是否足够
  	check_guest_free_space mpstats;

  	估算每个 target disk 的空间要求，填充 target_estimated_size 字段
  	(match conversion_mode with
	   | Copying (_, targets) ->
	       check_target_free_space mpstats source targets output
	   | In_place -> ()
  	);

  	进行磁盘转换
	(* type guestcaps = {
	  gcaps_block_bus : guestcaps_block_type;
	  gcaps_net_bus : guestcaps_net_type;
	  gcaps_video : guestcaps_video_type;

	  gcaps_arch : string;      (** Architecture that KVM must emulate. *)
	  gcaps_acpi : bool;        (** True if guest supports acpi. *)
	} *)
	let guestcaps =
		let rcaps =
			match conversion_mode with
			| Copying _ ->
			 { rcaps_block_bus = None; rcaps_net_bus = None; rcaps_video = None }
			| In_place ->
			 rcaps_from_source source in

		磁盘转换关键代码
    	do_convert g inspect source output rcaps in

    卸载所有的文件系统
    g#umount_all ();

    减少转换量。
	if cmdline.do_copy || cmdline.debug_overlays then (
	    (* Doing fstrim on all the filesystems reduces the transfer size
	     * because unused blocks are marked in the overlay and thus do
	     * not have to be copied.
	     *)
	    message (f_"Mapping filesystem data to avoid copying unused and blank areas");
	    do_fstrim g inspect;
	);
    ？？？
	g#umount_all ();
	与 guestfs_launch 相反，执行后端进程的有序关闭。然后仍然要执行 guestfs_close 
	g#shutdown ();
	关闭连接句柄和释放所有使用的资源
	g#close ();

	(* Copy overlays to target (for [--in-place] this does nothing). *)
	(match conversion_mode with
		| In_place -> ()
		| Copying (overlays, targets) ->
			获取目标固件 TargetBIOS 或 TargetUEFI
		   let target_firmware =
		     get_target_firmware inspect guestcaps source output in

		     为磁盘分配总线(*Virtio_blk、Virtio_SCSI、IDE*)，为多个磁盘分配插槽
		   let target_buses =
		     Target_bus_assignment.target_bus_assignment source targets
		                                                 guestcaps in
		   debug "%s" (string_of_target_buses target_buses);

		   let targets =
		     if not cmdline.do_copy then targets
		     else copy_targets cmdline targets input output in

		   (* Create output metadata. *)
			如果输出方式是 local 的话就不知道什么Hypervisor支持target磁盘支持，所以创建 libvirt xml 文件；qemu则可运行创建脚本
		   output#create_metadata source targets target_buses guestcaps inspect
		                         target_firmware;
		    使用了 --debug-overlays 选项保存overlays磁盘
		   if cmdline.debug_overlays then preserve_overlays overlays source.s_name;

		   delete_target_on_exit := false  (* Don't delete target on exit. *)
	);
三个赋值函数    
and open_source cmdline input =
and set_source_name cmdline source =
amd set_source_networks_and_bridges =

这里调用C语言的函数获取目录
and overlay_dir = (open_guestfs ())#get_cachedir ()

创建overlays磁盘
and create_overlays src_disks =
	对每个源磁盘生成{ ov_overlay_file = overlay_file; ov_sd = sd; ov_virtual_size = vsize; ov_source = source }结构体，变成一个列表
	在 -os指定路径 下使用 qemu-img 生成 overlay磁盘。

初始化target磁盘
and init_targets cmdline output source overlays =
	映射列表：
	(* output#prepare_targets will fill in the target_file field.
     * estimate_target_size will fill in the target_estimated_size field.
     * actual_target_size will fill in the target_actual_size field.*)
	let targets = { target_file = TargetFile ""; target_format = format;
          target_estimated_size = None;
          target_actual_size = None;
          target_overlay = ov }, overlays
    由具体的output_Hypervisor.ml继承output实现其prepare_targets方法完成调用
	output#prepare_targets source targets
	填充 target_file = dir 字段

(* Populate guestfs handle with qcow2 overlays. *)
and populate_overlays g overlays =
  List.iter (
    fun ({ov_overlay_file = overlay_file}) ->
      g#add_drive_opts overlay_file
        ~format:"qcow2" ~cachemode:"unsafe" ~discard:"besteffort"
        ~copyonread:true
  ) overlays

(* Populate guestfs handle with source disks.  Only used for [--in-place]. *)
and populate_disks g src_disks =
  List.iter (
    fun ({s_qemu_uri = qemu_uri; s_format = format}) ->
      g#add_drive_opts qemu_uri ?format ~cachemode:"unsafe"
                          ~discard:"besteffort"
  ) src_disks

(* Collect statvfs information from the guest mountpoints. *)
and get_mpstats g =
  let mpstats = List.map (
    fun (dev, path) ->
      let statvfs = g#statvfs path in
      let vfs = g#vfs_type dev in
      { mp_dev = dev; mp_path = path; mp_statvfs = statvfs; mp_vfs = vfs }
  ) (g#mountpoints ()) in
只是认为的，可能并不存在
(* inspect_get_mountpoints = ["/boot", "/dev/sda1", "/", "/dev/cl/root"] *)
(* mpstats:
mountpoint statvfs /dev/sda1 /boot (xfs):
  bsize=4096 blocks=259584 bfree=224126 bavail=224126
mountpoint statvfs /dev/cl/root / (xfs):
  bsize=4096 blocks=4452864 bfree=4185952 bavail=4185952 *)

(* Conversion can fail if there is no space on the guest filesystems
 * Mainly we care about the root filesystem.
 *)
and check_guest_free_space mpstats =

(*
算法：
 * (1) 计算所有guest文件系统的全部虚拟大小
 * eg: [ "/boot" = 500 MB, "/" = 2.5 GB ], total = 3 GB
 *
 * (2) 计算所有源磁盘的全部虚拟大小
 * eg: [ sda = 1 GB, sdb = 3 GB ], total = 4 GB
 *
 * (3) 转换比例
 * eg. ratio = 3/4
 *
 * (4) 计算出如果可以使用fstrim可以节省多少文件系统空间（小部分情况下会失败）
 * eg. [ "/boot" = 200 MB used, "/" = 1 GB used ], saving = 3 - 1.2 = 1.8
 *
 * (5) 通过转换比例计算出所有源磁盘的节省虚拟大小，然后分配到每一块磁盘得到转换后的大小
 * eg. scaled saving is 1.8 * 3/4 = 1.35     反？？？
 *     sda has 1/4 of total virtual size, so it gets a saving of 1.35/4
 *     sda final estimated size = 1 - (1.35/4) = 0.6625 GB
 *     sdb has 3/4 of total virtual size, so it gets a saving of 3 * 1.35 / 4
 *     sdb final estimate size = 3 - (3*1.35/4) = 1.9875 GB
 *)
and estimate_target_size mpstats targets =

(* Perform the fstrim. *)
and do_fstrim g inspect =
	获取所有的文件系统
	将设备过滤出来(*/dev/sda1、/dev/cl/root*)
	先卸载
	g#unmount_all（）
	再将设备挂载到 / 下，
	let mounted =
        try g#mount_options "discard" dev "/"; true
        with G.Error _ -> false in
	(*mount '-o' 'discard' '/dev/cl/root' '/sysroot//'*)
	然后缩减 / 的空间
	if mounted then (
        try g#fstrim "/"
  	)

(* Estimate space required on target for each disk.  Note this is a max. *)
and check_target_free_space mpstats source targets output =
  message (f_"Estimating space required on target for each disk");
  let targets = estimate_target_size mpstats targets in

  output#check_target_free_space source targets

(* Conversion. *)
and do_convert g inspect source output rcaps =
	从inspect获取名字与转换函数，
	convert就是 i_type = linux 字段对应的 convert_linux.ml 模块的 convert 函数
	(*conversion_name = linux*)
	let conversion_name, convert =
    	try Modules_list.find_convert_module inspect

    磁盘转换，详见 convert_linux.ml
	let guestcaps =
    	convert g inspect source (output :> Types.output_settings) rcaps in

    返回guestcaps
    guestcaps

(* Does the guest require UEFI on the target? *)
and get_target_firmware inspect guestcaps source output =
	检查 guest 是否需要 BIOS 或 UEFI 来启动
	由子类获取支持的固件，比如 output_local#supported_firmware
	let supported_firmware = output#supported_firmware in
	检查目标固件

(* Copy the source (really, the overlays) to the output. *)
and copy_targets cmdline targets input output =
	打印复制磁盘信息(*Copying disk 1/1 to /var/tmp/centos2-sda (qcow2)*)
	检查一下qemu引起的磁盘bug
	确定磁盘类型，兼容性（compat，qcow2独有）
	创建target空磁盘，通过 qemu-img create 创建
	output#disk_create
        t.target_file t.target_format t.target_overlay.ov_virtual_size
        ?preallocation ?compat;
    构建磁盘转换命令并执行 qemu-img convert overlay target
    获取真实大小
    actual_target_size


(* Update the target_actual_size field in the target structure. *)
and actual_target_size target =
	填充target结构体中的 target_actual_size 字段


convert_linux.ml
let rec convert (g : G.guestfs) inspect source output rcaps =
	对inspect中的参数做检查
	(*操作系统类型、操作系统所属版本（RHEL、SUSE、Debian）、包管理器*)
	初始化Augeas（软件配置管理库）
	g#aug_init "/" 1;

	清理 RPM数据库
	Array.iter g#rm_f (g#glob_expand "/var/lib/rpm/__db.00?");

	检查安装的 bootloader 并得到一个对象
	(*class virtual bootloader = object
	  method virtual name : string
	  method virtual augeas_device_patterns : string list
	  method virtual list_kernels : string list
	  method virtual set_default_kernel : string -> unit
	  method set_augeas_configuration () = false
	  method virtual configure_console : unit -> unit
	  method virtual remove_console : unit -> unit
	  method update () = ()
	end*)
	let bootloader = Linux_bootloaders.detect_bootloader g inspect in

	检测bootloader安装和提供了哪些内核
	(* type kernel_info = {
	  ki_app : G.application2;
	  ki_name : string;
	  ki_version : string;
	  ki_arch : string;
	  ki_vmlinuz : string;
	  ki_vmlinuz_stat : G.statns;
	  ki_initrd : string option;
	  ki_modpath : string;
	  ki_modules : string list;
	  ki_supports_virtio_blk : bool;
	  ki_supports_virtio_net : bool;
	  ki_is_xen_pv_only_kernel : bool;
	  ki_is_debug : bool;
	  ki_config_file : string option;
	} *)
	let bootloader_kernels =
    Linux_kernels.detect_kernels g inspect family bootloader in

    ------------------------------Conversion 阶段---------------------------

    检测 Augeas 是否在读取 bootloader 的配置文件
    let augeas_grub_configuration () =
	    if bootloader#set_augeas_configuration () then
	      Linux.augeas_reload g

	缩减配置函数 unconfigure_xxx
	and unconfigure_xen () = ...
	and unconfigure_vbox () = 
	and unconfigure_vmware () =
		关闭 vmware的 yum 仓库
		卸载 VMware Tools
	and unconfigure_citrix () =
	and unconfigure_kudzu () =
	and unconfigure_prltools () = ...

	配置内核函数
	and configure_kernel () =
		如果只有了xen的内核，报错
		找出 best_kernel 内核(*意味着支持virtio、non-debug、版本最高的内核*)
		将其置为第一个，即默认启动内核
		bootloader#set_default_kernel best_kernel.ki_vmlinuz
		通过 Augeas 更新 /etc/sysconfig/kernel 文件中的 DEFAULTKERNEL 字段 为 best_kernel 的 ki_name 值

	(*即使内核已经安装完成，也会有不支持virtio的initrd存在，所以需要重新构建*)
	重新生成initrd函数
	and rebuild_initrd kernel =
		获取域virtio有关的模块
		移动老的initrd
		g#mv initrd (initrd ^ ".pre-v2v");

		dracut and mkinitrd 需要内核版本
		let mkinitrd_kv =
	        let modpath = kernel.ki_modpath in
		        match last_part_of modpath '/' with
		        | Some x -> x

	    构建 dracut 命令
		let run_dracut_command dracut_path = ...
		构建 update-initramfs 命令
		let run_update_initramfs_command () = ...
		if 存在 dracut 命令：
			执行 dracut 命令创建 initramfs-3.10.0-514.el7.x86_64.img
			(* libguestfs: trace: v2v: command "/sbin/dracut --verbose --add-drivers virtio virtio_ring virtio_blk virtio_scsi virtio_net virtio_pci /boot/initramfs-3.10.0-514.el7.x86_64.img 3.10.0-514.el7.x86_64" *)
		else if family = `SUSE_family && 存在 mkinitrd 命令
			执行 mkinitrd
		else if family = `Debian_family
			执行 run_update_initramfs_command
		else if 存在 mkinitrd
			执行 mkinitrd

	配置控制台函数
	and configure_console () =
		更改 /etc/securetty 文件中的 xvc0 或 hvc0 为 ttyS0

	移除控制台函数
	(* target不支持serial console的情况 *)
	and remove_console () =
		删掉 /etc/securetty 文件中的 xvc0 或 hvc0

	and supports_acpi () =
		RHEL版本的3.x操作系统不支持 acpi

	and get_display_driver () =
		if family = `SUSE_family then Cirrus else QXL

	配置显示驱动函数
  	and configure_display_driver video =
  		驱动名称
    	let video_driver = match video with QXL -> "qxl" | Cirrus -> "cirrus" in

    	查找 /etc/X11/xorg.conf 或 /etc/X11/XF86Config
    	let xorg_conf = ...
    	更新驱动配置文件 xorg_conf ^ /Device

    配置内核模块函数
	and configure_kernel_modules block_type net_type =
		搜索匹配函数
		let augeas_modprobe query =
			从下面的这些文件中搜索匹配 query 的东东
			let paths = [
		        "/files/etc/conf.modules/alias";        (* modules_conf.aug *)
		        "/files/etc/modules.conf/alias";
		        "/files/etc/modprobe.conf/alias";       (* modprobe.aug *)
		        "/files/etc/modprobe.conf.local/alias";
		        "/files/etc/modprobe.d/*/alias";
		      ] in

		找到现在调用的是哪个 /etc/modprobe.conf
		and discover_modpath () =

		(* Update 'alias eth0 ...'. *)
		let paths = augeas_modprobe ". =~ regexp('eth[0-9]+')" in
		...
		List.iter (
	      fun path -> g#aug_set (path ^ "/modulename") net_device
	    ) paths;


	    (* Update 'alias scsi_hostadapter ...' *)
	    let paths = augeas_modprobe ". =~ regexp('scsi_hostadapter.*')" in
    	(match block_type with
    	| Virtio_blk | Virtio_SCSI ->
    		if paths <> []
    			转换第一个 scsi_hostadapter 到 virtio，删掉其余的
    		else
    			添加一个 scsi_hostadapter
    	| IDE -> 
    	(* There is no scsi controller in an IDE guest. *)
	      List.iter (fun path -> ignore (g#aug_rm path)) (List.rev paths)
	    );

	    对xen的模块发出不知如何处理的警告
	    let xen_modules = [ "xennet"; "xen-vnif"; "xenblk"; "xen-vbd" ] in

	重新映射块设备函数
	遍历启动配置文件，替换诸如 "hda" 为 "vda" 之类
	and remap_block_devices block_type =
		获取ide设备名字前缀：hd 或 sd
		let ide_block_prefix = ...

		转换之后设备名称前缀
		let block_prefix_after_conversion =
	      match block_type with
	      | Virtio_blk -> "vd"
	      | Virtio_SCSI -> "sd"
	      | IDE -> ide_block_prefix in

	    映射源磁盘和目的磁盘的名称
	    let map =
		    mapi（
	    		let source_dev = block_prefix_before_conversion ^ drive_name i in
	      		let target_dev = block_prefix_after_conversion ^ drive_name i in
	          	source_dev, target_dev
          	）source.s_disks in

        Xen 虚拟机比较特殊
        let map = map @
	      mapi (
	        fun i disk ->
	          "xvd" ^ drive_name i, block_prefix_after_conversion ^ drive_name i
	      ) source.s_disks in

	    是否存在以下路径
	    let paths = ["/files/etc/fstab/*/spec";
	    "/files" ^ grub_config ^ "/*/kernel/root";
    	"/files" ^ grub_config ^ "/*/kernel/resume";
		"/files/boot/grub/device.map/*[label() != \"#comment\"]";
    	"/files/etc/sysconfig/grub/boot";] in

    	let paths =
      		List.flatten (List.map Array.to_list (List.map g#aug_match paths)) in

      	获取新的设备名称
      	let rec replace_if_device path value =
      		从 map 中找出与 device 相关的一对
      		let replace device = ...

      		if String.find path "GRUB_CMDLINE" >= 0 then (
      			(* Handle grub2 resume=<dev> specially. *)
		        if Str.string_match rex_resume value 0 then (
		          let start = Str.matched_group 1 value
		          and device = Str.matched_group 2 value
		          and end_ = Str.matched_group 3 value in
		          let device = replace_if_device path device in
		          start ^ device ^ end_
		        )
		        else value
      		)
      		(* Str.string_match: 是否从指定位置开始，有匹配到的字符串子串
  			   Str.matched_group： 多个匹配的第n个子串 *)
      		else if Str.string_match rex_device_cciss_p value 0 then (
				let device = Str.matched_group 1 value
				and part = Str.matched_group 2 value in
				"/dev/" ^ replace device ^ part
			)
			else if Str.string_match rex_device_cciss value 0 then (
				let device = Str.matched_group 1 value in
				"/dev/" ^ replace device
			)
			else if Str.string_match rex_device_p value 0 then (
				let device = Str.matched_group 1 value
				and part = Str.matched_group 2 value in
				"/dev/" ^ replace device ^ part
			)
			else if Str.string_match rex_device value 0 then (
				let device = Str.matched_group 1 value in
				"/dev/" ^ replace device
			)
			else (* doesn't look like a known device name *)
				value
			in

		let changed = ref false in
		磁盘名称发生了变化，改变配置
	    List.iter (
	      fun path ->
	        let value = g#aug_get path in
	        let new_value = replace_if_device path value in

	        if value <> new_value then (
	          g#aug_set path new_value;
	          changed := true
	        )
	    ) paths;

	    if !changed then (
	      g#aug_save ();

	      (* Make sure the bootloader is up-to-date. *)
	      bootloader#update ();

	      Linux.augeas_reload g
	    );

	    (* Delete blkid caches if they exist, since they will refer to the old
	     * device names.  blkid will rebuild these on demand.
	     *
	     * Delete the LVM cache since it will contain references to the
	     * old devices (RHBZ#1164853).
	     *)
	    List.iter g#rm_f [
	      "/etc/blkid/blkid.tab"; "/etc/blkid.tab";
	      "/etc/lvm/cache/.cache"
	    ];
  	in

  	依次执行上述函数
  	augeas_grub_configuration ();

	unconfigure_xen ();
	unconfigure_vbox ();
	unconfigure_vmware ();
	unconfigure_citrix ();
	unconfigure_kudzu ();
	unconfigure_prltools ();

	配置内核
	let kernel = configure_kernel () in

	serial_console
	if output#keep_serial_console then (
		configure_console ();
		bootloader#configure_console ();
	) else (
		remove_console ();
		bootloader#remove_console ();
	);

	let acpi = supports_acpi () in

  	let video =
	    match rcaps.rcaps_video with
	    | None -> get_display_driver ()
	    | Some video -> video in

  	let block_type =
	    match rcaps.rcaps_block_bus with
	    | None -> if kernel.ki_supports_virtio_blk then Virtio_blk else IDE
	    | Some block_type -> block_type in

  	let net_type =
	    match rcaps.rcaps_net_bus with
	    | None -> if kernel.ki_supports_virtio_net then Virtio_net else E1000
	    | Some net_type -> net_type in

	配置显示驱动
  	configure_display_driver video;
  	重新映射设备
	remap_block_devices block_type;
	配置内核模块
  	configure_kernel_modules block_type net_type;
  	重新生成initrd
  	rebuild_initrd kernel;

  	重新配置 SELinux
	SELinux_relabel.relabel g;


	let guestcaps = {
		gcaps_block_bus = block_type;
		gcaps_net_bus = net_type;
		gcaps_video = video;
		gcaps_arch = Utils.kvm_arch inspect.i_arch;
		gcaps_acpi = acpi;
	} in

	返回 guestcaps
	guestcaps



名词解释：
virt-v2v命令：
	create [-f fmt] [-o options] filename [size]
	   Create the new disk image filename of size size and format fmt. Depending on the file
	   format, you can add one or more options that enable additional features of this format.

	   If the option backing_file is specified, then the image will record only the
	   differences from backing_file. No size needs to be specified in this case. backing_file
	   will never be modified unless you use the "commit" monitor command (or qemu-img
	   commit).

	backing_file
	   File name of a base image (see create subcommand)

linux命令：
	udevadm
	    Send control commands or test the device manager.

	parted
	    Apply COMMANDs with PARAMETERS to DEVICE.