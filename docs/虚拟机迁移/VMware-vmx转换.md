# VMware-vmx虚拟机转换

所有的VMware平台的windows虚拟机都需要先卸载`VMware-tools`。

从VMware的vmx文件导入虚拟机。

在以下两种情况下有用：

1. VMware虚拟机存储在单独的NFS服务器并且可以直接挂载NFS存储。
2. 能通过SSH连接到VMware ESXI hypervisor，并有一个含有虚拟机的`/vmfs/volumes`文件夹。

如果有文件夹包含后缀名为`.vmx、.vmxf、.nvram、一个或多个.vmdk`磁盘映像的文件夹，可以使用此方法。就是虚拟机工作目录。

**转换之前先关机**。

输出到ovirt参考：[VMware-ova转换](VMware-ova转换.md)

### 1. 获取存储域

如果不能在本地获取vmx和vmdk，那么必须挂载到转换服务器上面或者在`ESXI hypervisor`设置SSH免密登录。

### 2. 使用ssh-agent设置免密登录

首先打开 EXSI 的 ssh 功能。

然后添加转换服务器的ssh公钥到ESXI hypervisor的`/etc/ssh/keys-root/authorized_keys`，然后验证。

最后执行下面的命令，将私钥托管给`ssh-agent`：

```shell
eval `ssh-agent -s`
ssh-add
```

该模式不支持交互式密码输入，所以必须这样设置。

### 3. 构造SSH URI

构造指向vmx文件的URI。类似于这样：

```shell
ssh://root@esxi.example.com/vmfs/volumes/datastore1/my%20guest/my%20guest.vmx
```

所有的non-ASCII字符都必须转换（例：空格 -> %20）。

若不使用默认的22端口，可在主机名后面加上端口号。

### 4. 导入虚拟机

从本地或NFS导入：

```shell
 $ virt-v2v -i vmx guest.vmx -o local -os /var/tmp
```

通过ssh导入：

```shell
 $ virt-v2v \
     -i vmx -it ssh \
     "ssh://root@esxi.example.com/vmfs/volumes/datastore1/guest/guest.vmx" \
     -o local -os /var/tmp
```

