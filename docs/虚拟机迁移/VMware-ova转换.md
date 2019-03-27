# VMware-ova虚拟机转换

所有的VMware平台的windows虚拟机都需要先卸载`VMware-tools`。

## 创建ova

创建ova文件有两种方式。第一种是通过界面的导出ovf，ovf形式导出为文件夹，ova形式导出为文件。第二种是使用VMware的专有工具`ovftool`：

```shell
 ovftool --noSSLVerify \
   vi://USER:PASSWORD@esxi.example.com/VM \
   VM.ova
```

连接到vCenter：

```shell
 ovftool  --noSSLVerify \
   vi://USER:PASSWORD@vcenter.example.com/DATACENTER-NAME/vm/VM \
   VM.ova
```

对于Active Directory-aware验证，你必须以ascii十六进制代码（\）的形式表达@字符：

```shell
 vi://DOMAIN%5cUSER:PASSWORD@...
```

## 挂载目录

1. Linux安装挂载工具

        yum install cifs-utils

2. 挂载windows目录

        mount.cifs [//172.16.2.27/ova](notion://172.16.2.27/ova) /tmp/ova_tmp -o user=phy,pass=KVM.123456

    挂载失败使用加上参数：

        mount.cifs //172.16.2.27/ova ova_tmp/ -o user=phy,pass=KVM.123456,sec=ntlm

## 执行转换

1. 输出到ovirt的选项

        virt-v2v -i ova guest.ova \
           -o rhv-upload -oc https://ovirt-engine.example.com/ovirt-engine/api \
           -os ovirt-data -op /tmp/ovirt-admin-password -of raw \
           -oo rhv-cafile=/tmp/ca.pem -oo rhv-direct \
           --bridge ovirtmgmt

    通过REST API直接上传客户机到oVirt或RHV，要求 **`oVirt/RHV ≥ 4.2`**

    1. 指定`-o rhv-upload`
    2. `-oc` https://ovirt-engine.example.com/ovirt-engine/api?username=admin@internal

        可向URL添加用户名或端口号，如果没有指定用户名则使用`admin@internal`

    3. `-of` raw

        只能输出raw格式的磁盘

    4. `-op` password-file

        用于连接ovirt-engine的密码文件。该文件应包含完整的密码，末尾不能有换行符，权限改为0600。

    5. `-os` ovirt-data

        存储域

    6. `-oo` rhv-cafile=ca.pem

        ca.pem文件（证书颁发机构），从ovirt-engine上的`/etc/pki/ovirt-engine/ca.pem`复制。

    7. `-oo` rhv-cluster=CLUSTERNAME

        集群的名字。默认使用`Default`

    8. `-oo` rhv-direct

        表示会直接上传磁盘到ovirt-node，否则通过ovirt-engine代理上传磁盘。直接上传要求网络能访问到node。非直接上传的方式会有点慢，但是能在所有的情况下使用。

    9. `-oo` rhv-verifypeer

         通过针对颁发机构检查服务器的证书来验证oVirt/RHV服务器的身份。

2. 输出到ovirt（老方法）

      本节说明只适用于`-o rhv`输出模式。

      如果你使用RHV-M用户界面的virt-v2v，那么在后台使用`-o vdsm`输出模式由vdsm管理导入。

      你必须指定`-o rhv`和`-os`选项指明RHV-M的导出域。也可以指定NFS服务器和挂载点，例如*-os rhv-storage:/rhv/export*，或者先挂载然后指定挂载点，例如*-os /tmp/mnt*。**不要指向数据域**。

      不支持`-oo`、`-op`选项，不需要`-oc`选项。

3. 实际操作

**准备环境**

```shell
#安装pip
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
#安装ovirtsdk4模块
yum install gcc libxml2-devel python-devel
pip install ovirt-engine-sdk-python==4.2.5
```

**进行转换**

```shell
virt-v2v -v -x -i ova ova_190319140049/centos2.ova -o rhv -os 172.16.2.124:/home/exports -of raw/qcow2 -bridge ovirtmgmt 2>&1 | tee virt-v2v-ovirt.log
```

**问题**

由于ova不包含网卡的mac地址，所以需要在界面中指定网卡的mac地址，或者直接修改ocml中生成的xml文件，添加mac信息。