# Xen虚拟机转换

可接受输入来源：`RHEL 5 Xen or SLES and openSUSE Xen hosts`。

输入选项自带`-i libvirt`。

输出到ovirt参考：[VMware-ova转换](VMware-ova转换.md)。

### 1. 使用ssh-agent设置免密登录

添加转换服务器的ssh公钥到Xen主机的`~/.ssh/authorized_keys`，然后验证。

执行下面的命令，将私钥托管给`ssh-agent`：

```shell
eval `ssh-agent -s`
ssh-add
```

该模式不支持交互式密码输入，所以必须这样设置。

随着一些现代ssh实现，禁用了与RHEL 5 sshd交互操作所需的传统加密策略。需要在转换服务器上面启用，先阅读[update-crypto-policies(8)](https://www.mankier.com/8/update-crypto-policies)：

```shell
update-crypto-policies LEGACY
```

### 2. 测试libvirt到Xen主机的连接

使用`virsh`：

```shell
 $ virsh -c xen+ssh://root@xen.example.com list --all
  Id    Name                           State
 ----------------------------------------------------
  0     Domain-0                       running
  -     rhel49-x86_64-pv               shut off
```

你也应该尝试从任意虚拟机复制元数据：

```shell
 $ virsh -c xen+ssh://root@xen.example.com dumpxml rhel49-x86_64-pv
 <domain type='xen'>
   <name>rhel49-x86_64-pv</name>
   [...]
 </domain>
```

**如果上述步骤失败了，那么就不能进行转换！**

**如果虚拟机磁盘位于主机块设备上面，那么转换将失败！**

参考 ["XEN OR SSH CONVERSIONS FROM BLOCK DEVICES"](#xen-or-ssh-conversions-from-block-devices)

### 3. 转换虚拟机

```shell
 $ LIBGUESTFS_BACKEND=direct \
       virt-v2v -ic 'xen+ssh://root@xen.example.com' \
           rhel49-x86_64-pv \
           -o local -os /var/tmp
```

rhel49-x86_64-pv是虚拟机名字，**必须关机**。

### XEN OR SSH CONVERSIONS FROM BLOCK DEVICES

当前virt-v2v的一个缺陷是：如果虚拟机磁盘位于主机的块设备上面，则不能获取Xen的虚拟机（或者任何通过ssh远程定位的虚拟机）。

可以在虚拟机的XML文件中查看是否使用了主机块设备：

```xml
  <disk type='block' device='disk'>
    ...
    <source dev='/dev/VG/guest'/>
```

解决这个问题的办法是先使用`virt-v2v-copy-to-local`复制虚拟机到转换服务器，再使用`virt-v2v`进行转换。此时就需要有足够的空间存储整个复制的虚拟机。

```shell
 virt-v2v-copy-to-local -ic xen+ssh://root@xen.example.com guest
 virt-v2v -i libvirtxml guest.xml -o local -os /var/tmp
 rm guest.xml guest-disk*
```

