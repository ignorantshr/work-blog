### 1.解析命令行，初始化输入输出模块

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

### 3.创建overlay磁盘（copy模式独有）

```ocaml
let overlays = create_overlays source.s_disks in
```

日志：

```shell
qemu-img 'create' '-q' '-f' 'qcow2' '-b' '/var/tmp/ova.x0YFry/centos2-disk1.vmdk' '-o' 'compat=1.1,backing_fmt=vmdk' '/var/tmp/v2vovl36099b.qcow2'
```

### 4.初始化target结构体（copy模式独有）

```ocaml
let targets = init_targets cmdline output source overlays in
```

### 5.创建处理器

```ocaml
let g = open_guestfs ~identifier:"v2v" () in
```

### 6.启动appliance、守护进程guestfsd

```ocaml
g#launch ();
```

1. supermin5创建appliance，测试qemu，使用qemu-kvm开启appliance
2. supermin5载入模块；创建设备目录（/dev/**）并挂载；设置网络；分配逻辑卷组
3. libguestfs接收到GUESTFS_LAUNCH_FLAG信号，appliance启动成功

### 7.检测源磁盘，获取信息

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

### 8.估算每个 target disk 的空间要求

```ocaml
  let mpstats = get_mpstats g in
  check_guest_free_space mpstats;
  check_target_free_space mpstats source targets output
```

日志：

```shell
[ 133.5] Checking for sufficient free disk space in the guest
[ 133.5] Estimating space required on target for each disk
mpstats:
mountpoint statvfs /dev/sda1 /boot (xfs):
  bsize=4096 blocks=259584 bfree=224126 bavail=224126
mountpoint statvfs /dev/cl/root / (xfs):
  bsize=4096 blocks=4452864 bfree=4185952 bavail=4185952
estimate_target_size: fs_total_size = 19302187008 [18.0G]
estimate_target_size: source_total_size = 21474836480 [20.0G]
estimate_target_size: ratio = 0.899
estimate_target_size: fs_free = 18063679488 [16.8G]
estimate_target_size: scaled_saving = 16236143164 [15.1G]
estimate_target_size: sda: 5238693316 [4.9G]
```

### 9.进行磁盘转换

```ocaml
let guestcaps = do_convert g inspect source output rcaps in
```

结果日志：

```shell
guestcaps:
rm_f = 0
gcaps_block_bus = virtio-blk
gcaps_net_bus = virtio-net
gcaps_video = qxl
gcaps_arch = x86_64
gcaps_acpi = true
virt-v2v: This guest has virtio drivers installed.
```

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

```shell
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

### 12.分配磁盘到总线

```
let target_buses =
         Target_bus_assignment.target_bus_assignment source targets guestcaps in
```

日志：

```shell
[ 188.3] Assigning disks to buses
virtio-blk slot 0:
target_file = [file] /var/tmp/qemu-vm/centos2-sda
target_format = qcow2
target_estimated_size = 5238693316
target_overlay = /var/tmp/v2vovl36099b.qcow2
target_overlay.ov_source = /var/tmp/ova.x0YFry/centos2-disk1.vmdk
ide slot 0:
        CD-ROM [ide] in slot 0
```

### 13.创建目的磁盘

```ocaml
let targets = 
	if not cmdline.do_copy then targets
	else copy_targets cmdline targets input output in
```

#### 	13.1创建目的磁盘

```ocaml
output#disk_create
	t.target_file t.target_format t.target_overlay.ov_virtual_size
	?preallocation ?compat;
```

日志：

```shell
[ 188.3] Copying disk 1/1 to /var/tmp/qemu-vm/centos2-sda (qcow2)
target_file = [file] /var/tmp/qemu-vm/centos2-sda
target_format = qcow2
target_estimated_size = 5238693316
target_overlay = /var/tmp/v2vovl36099b.qcow2
target_overlay.ov_source = /var/tmp/ova.x0YFry/centos2-disk1.vmdk

disk_create "/var/tmp/qemu-vm/centos2-sda" "qcow2" 21474836480 "preallocation:sparse" "compat:1.1"
```
#### 	13.2转换目的磁盘

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

### 14.生成 metadata 文件

```ocaml
output#create_metadata source targets target_buses guestcaps inspect
       target_firmware;
```

日志：

```shell
Creating output metadata
```

### 15.两种转换模式

**15.1 `copying`模式**：

在这种模式下，磁盘的转换流程是这样的：`source -> overlay -> target`。

1. 获取原VM的一个或多个磁盘source描述。
2. 在源磁盘的上面放可写的叠加磁盘overlay。
3. 在overlay上面做转换。
4. 复制overlay到目标磁盘target。

**15.2 `in place`模式**：不会在目标Hypervisor创建新的虚拟机，而是调整原VM的操作系统以在输入的Hypervisor上运行。

```shell
virt-v2v -ic qemu:///system converted_vm --in-place
```

`virt-v2v`默认使用`copying`模式，在以下场景中可能会用到`in place`模式：

​	一个外来VM已经被导入到基于KVM的Hypervisor上，但是仍然需要在guest上面调整使它运行在新的虚拟硬件上。

​	在这种情况下，假设第三方工具基于原VM配置和内容在支持的基于KVM的Hypervisor中创建了目标VM，但是需要使用更适合KVM的虚拟设备（比如virtio存储网络、网络等）。

**15.3 两种模式的区别**：

|       转换模式       |   copying   | in place |
| :------------------: | :---------: | :------: |
| 是否在源磁盘上做修改 |     否      |    是    |
| 是否创建overlays磁盘 |     是      |    否    |
|  在哪个磁盘上做转换  | overlay磁盘 |  源磁盘  |