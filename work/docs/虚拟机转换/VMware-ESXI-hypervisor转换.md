# VMware-ESXi-hypervisor虚拟机转换

所有的VMware平台的windows虚拟机都需要先卸载`VMware-tools`。

输出到ovirt参考：[VMware-ova转换](VMware-ova转换.md)

尽量使用ova或vmx的输入方式，因为它们比本篇的方法更快且需要的空间也更少。

可以先使用[virt-v2v-copy-to-local(1)](http://libguestfs.org/virt-v2v-copy-to-local.1.html)拷贝虚拟机从hypervisor到本地文件，然后转换它。

### 1. URI

```shell
 esx://root@esxi.example.com?no_verify=1
```

`?no_verify=1`参数用于取消TLS证书检查。

### 2. 测试libvirt到ESXi hypervisor的连接

使用`virsh`工具：

```shell
 $ virsh -c esx://root@esxi.example.com?no_verify=1 list --all
 Enter root's password for esxi.example.com: ***
  Id    Name                           State
 ----------------------------------------------------
  -     guest                          shut off
```

### 3. 复制虚拟机到本地

使用libvirt URI的`-ic`选项，复制一个虚拟机到本地：

```shell
 $ virt-v2v-copy-to-local -ic esx://root@esxi.example.com?no_verify=1 guest
```

创建*guest.xml*, *guest-disk1*, ...

可使用`--password-file <file>`选项，实际使用中该选项只能代替一次密码输入，可是有多达三次密码输入。

### 4. 执行 virt-v2v 转换

```shell
 $ virt-v2v -i libvirtxml guest.xml -o local -os /var/tmp
```

### 5. 清理

删掉 *guest.xml* 、 *guest-disk** 文件