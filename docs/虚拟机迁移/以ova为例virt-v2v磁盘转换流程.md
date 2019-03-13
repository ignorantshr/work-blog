### 1.解析命令行

```ocaml
let cmdline, input, output = parse_cmdline () in
```

### 2.获取信息

```ocaml
let source = open_source cmdline input in
```

### 2.1处理输入

```ocaml
let source = input#source () in
```

日志：

```shell
tar -xf 'centos2.ova' -C '/var/tmp/ova.x0YFry'
```

信息日志：

```shell
source name: centos2
hypervisor type: vmware
         memory: 1073741824 (bytes)
       nr vCPUs: 1
     CPU vendor:
      CPU model:
   CPU topology:
   CPU features:
       firmware: bios
        display:
          video:
          sound:
disks:
        /var/tmp/ova.x0YFry/centos2-disk1.vmdk (vmdk) [scsi]
removable media:
        CD-ROM [ide] in slot 0
NICs:
        Bridge "nat" [e1000]
```

### 4.创建overlay磁盘（copy模式独有）

```ocaml
let overlays = create_overlays source.s_disks in
```

日志：

```shell
qemu-img 'create' '-q' '-f' 'qcow2' '-b' '/var/tmp/ova.x0YFry/centos2-disk1.vmdk' '-o' 'compat=1.1,backing_fmt=vmdk' '/var/tmp/v2vovl36099b.qcow2'
```

### 5.初始化target结构体（copy模式独有）

```ocaml
let targets = init_targets cmdline output source overlays in
```

### 6.创建处理器

```ocaml
let g = open_guestfs ~identifier:"v2v" () in
```

### 7.启动appliance、守护进程guestfsd

```ocaml
g#launch ();
```

1. supermin5创建appliance，测试qemu，使用qemu-kvm开启appliance
2. supermin5载入模块；创建设备目录（/dev/**）并挂载；设置网络；分配逻辑卷组
3. libguestfs接收到GUESTFS_LAUNCH_FLAG信号，appliance启动成功

### 8.检测源磁盘，获取信息

```ocaml
let inspect = Inspect_source.inspect_source cmdline.root_choice g in
```

日志：

```shell
i_root = /dev/cl/root
i_type = linux
i_distro = centos
i_arch = x86_64
i_major_version = 7
i_minor_version = 5
i_package_format = rpm
i_package_management = yum
i_product_name = CentOS Linux release 7.5.1804 (Core)
i_product_variant = unknown
i_firmware = BIOS
i_windows_systemroot =
i_windows_software_hive =
i_windows_system_hive =
i_windows_current_control_set =
```

### 9.进行磁盘转换

```ocaml
let guestcaps = do_convert g inspect source output rcaps in
```

日志：

```shell
guestcaps:
rm_f = 0
gcaps_block_bus = virtio-blk
gcaps_net_bus = virtio-net
gcaps_video = qxl
gcaps_arch = x86_64
gcaps_acpi = true
```

9.1 

detect_kernels日志

```shell
kernels offered by the bootloader in this guest (first in list is default):
* kernel 3.10.0-514.el7.x86_64 (x86_64)
        /boot/vmlinuz-3.10.0-514.el7.x86_64 -- kernel_info.ki_vmlinuz
        /boot/initramfs-3.10.0-514.el7.x86_64.img -- kernel_info.ki_initrd
        /boot/config-3.10.0-514.el7.x86_64 -- kernel_info.ki_config_file
        /lib/modules/3.10.0-514.el7.x86_64 -- kernel_info.ki_modpath
        2347 modules found
        virtio: blk=true net=true rng=true balloon=true -- ki.ki_supports_virtio_blk ki.ki_supports_virtio_net 
        pvpanic=true xen=false debug=false -- ki.ki_is_xen_pv_only_kernel ki.ki_is_debug
```

remap_block_devices日志

```shell
block device map:
        sda     -> vda
        xvda    -> vda
...
libguestfs: trace: v2v: aug_get "/files/boot/grub2/device.map/hd0"
libguestfs: trace: v2v: aug_get = "/dev/sda"
libguestfs: trace: v2v: aug_set "/files/boot/grub2/device.map/hd0" "/dev/vda"
```



### 10.减少转换量

```ocaml
g#umount_all ();
do_fstrim g inspect;
```

日志：

```
libguestfs: trace: v2v: fstrim "/"
guestfsd: <= fstrim (0x14e) request length 72 bytes
commandrvf: fstrim -v /sysroot/
/sysroot/: 16 GiB (17179185152 bytes) trimmed
guestfsd: => fstrim (0x14e) took 0.15 secs
libguestfs: trace: v2v: fstrim = 0
```

### 11.关闭守护进程

```ocaml
g#umount_all ();
g#shutdown ();
g#close ();
```

日志：

```shell
umount-all: /proc/mounts: fsname=rootfs dir=/ type=rootfs opts=rw freq=0 passno=0
umount-all: /proc/mounts: fsname=proc dir=/proc type=proc opts=rw,relatime freq=0 passno=0
umount-all: /proc/mounts: fsname=/dev/root dir=/ type=ext2 opts=rw,noatime freq=0 passno=0
umount-all: /proc/mounts: fsname=/proc dir=/proc type=proc opts=rw,relatime freq=0 passno=0
umount-all: /proc/mounts: fsname=/sys dir=/sys type=sysfs opts=rw,relatime freq=0 passno=0
...
libguestfs: sending SIGTERM to process 6353
libguestfs: qemu maxrss 604960K
libguestfs: trace: v2v: shutdown = 0
libguestfs: trace: v2v: close
libguestfs: closing guestfs handle 0x2488810 (state 0)
libguestfs: command: run: rm
libguestfs: command: run: \ -rf /tmp/libguestfsCZ1315
libguestfs: command: run: rm
libguestfs: command: run: \ -rf /tmp/libguestfs5EMQ5o
```

**----------------------------------以下是copy模式独有的步骤-------------------------**

### 12.创建目的磁盘

```ocaml
let targets = 
	if not cmdline.do_copy then targets
	else copy_targets cmdline targets input output in
```

#### 	12.1创建目的磁盘

```ocaml
output#disk_create
	t.target_file t.target_format t.target_overlay.ov_virtual_size
	?preallocation ?compat;
```

日志：

```shell
disk_create "/var/tmp/qemu-vm/centos2-sda" "qcow2" 21474836480 "preallocation:sparse" "compat:1.1"
```
#### 	12.2转换目的磁盘

```ocaml
let cmd = [ "qemu-img"; "convert" ] @
        (if not (quiet ()) then [ "-p" ] else []) @
        [ "-n"; "-f"; "qcow2"; "-O"; t.target_format ] @
        (if cmdline.compressed then [ "-c" ] else []) @
        [ overlay_file; t.target_file ] in

run_command cmd
```

日志：

```shell
qemu-img 'convert' '-p' '-n' '-f' 'qcow2' '-O' 'qcow2' '/var/tmp/v2vovl36099b.qcow2' '/var/tmp/qemu-vm/centos2-sda'
```

### 13.生成xml文件或可执行脚本

```ocaml
output#create_metadata source targets target_buses guestcaps inspect
       target_firmware;
```

日志：

```shell
Creating output metadata
```