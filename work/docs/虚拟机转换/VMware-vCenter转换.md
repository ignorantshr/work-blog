# VMware-vCenter虚拟机转换

从`VMware vCenter`转换虚拟机到`ovirt`平台。

**要求**：vCenter >= 5.0

举例场景：

> 有一个VMware vCenter服务器，地址是`vcenter.example.com`，一个数据中心`Datacenter`，和一个`ESXi hypervisor`叫做`esxi`。要转换的虚拟机叫`vmware_guest`。

```shell
 virt-v2v -ic vpx://vcenter.example.com/Datacenter/esxi vmware_guest \
   -o rhv-upload -oc https://ovirt-engine.example.com/ovirt-engine/api \
   -os ovirt-data -op /tmp/ovirt-admin-password -of raw \
   -oo rhv-cafile=/tmp/ca.pem -oo rhv-direct \
   --bridge ovirtmgmt
```

输出到ovirt参考：[VMware-ova转换](VMware-ova转换.md)

## 输入模式

默认使用libvirt从vCenter获取信息，所以使用该模式时默认添加`-i libvirt`选项。

## 1. vCenter：从windows客户机移除`VMware-tools`

对于windows客户机，在转换之前需要将`VMware-tools`移除。否则在转换完成之后每次启动客户机的时候都会抱怨，并且该工具不能卸载。

## 2. vCenter：URI

libvirt `URI`格式：

```shell
vpx://user@server/Datacenter/esxi
```

- user@

    > 可选。如果包含`\`（eg. `DOMAIN\USER`），使用`%5c`（十六进制ASCII码）代替（eg. `DOMAIN%5cUSER`）。其它标点符号可能也需要如此。@是`%40`，`.`不需要转换，[可在此查询](http://www.bejson.com/convert/ox2str/)。这个地方一定要加上域名，例：`vpx://administrator%40vsphere.local@172.16.2.178/Datacenter/cluster/172.16.2.162?no_verify=1`

- server

    > 服务器域名

- Datacenter

    > 数据中心的名字。空格使用`%20`代替。

- esxi

    > 运行虚拟机的ESXi hypervisor的名字

如果使用文件夹部署VMware，可能需要将其添加到URI，eg：

```shell
 vpx://user@server/Folder/Datacenter/esxi
```

[详细的libvirt URIs](http://libvirt.org/drvesx.html)

## 3. 测试libvirt到vCenter的连接

使用`virsh`列出虚拟机：

```shell
 $ virsh -c 'vpx://root@vcenter.example.com/Datacenter/esxi' list --all
 Enter root's password for vcenter.example.com: ***
 
  Id    Name                           State
 ----------------------------------------------------
  -     Fedora 20                      shut off
  -     Windows 2003                   shut off
```

如果出现了证书相关的问题，可以导入vCenter主机的证书，或者跳过证书验证：

```shell
$ virsh -c 'vpx://root@vcenter.example.com/Datacenter/esxi?no_verify=1' list --all
```

你也应该尝试从任意虚拟机复制元数据：

```shell
$ virsh -c 'vpx://root@vcenter.example.com/Datacenter/esxi' dumpxml "Windows 2003"
 <domain type='vmware'>
   <name>Windows 2003</name>
   [...]
 </domain>
```

**如果上述步骤失败了，那么就不能进行转换！**

## 4. vCenter：导入虚拟机

```shell
 $ virt-v2v -ic 'vpx://root@vcenter.example.com/Datacenter/esxi?no_verify=1' \
   "Windows 2003" \
   --password-file vCenter.pass -o local -os /var/tmp
```

**虚拟机必须关机**。

如果不想在转换时输入密码，使用`--password-file <file>`选项指定密码文件。

## 5. vCenter：Non-Administrator 角色

可以使用非管理员角色执行转换，但是需要为其提供最小权限：

1. 在vCenter创建角色

2. 打开以下对象
<pre>

      Datastore:
       - Browse datastore
       - Low level file operations
      
      Sessions:
       - Validate session
      
      Virtual Machine:
        Provisioning:
          - Allow disk access
          - Allow read-only disk access
          - Guest Operating system management by VIX API
</pre>

## 6. vCenter：防火墙及代理设置

### 6.1 vCenter：端口

若是有防火墙，需要打开`443`（https）和`5480`端口。前者用于复制磁盘，后者用于查询虚拟机元数据。

如果使用了非默认端口，需要在URI中指定。这些端口只用于virt-v2v转换，如果想要使用其他功能需要打开其他端口。

```shell
 ┌────────────┐   port 443 ┌────────────┐        ┌────────────┐
 │ virt-v2v   │───────────▶ vCenter    │────────▶ ESXi       │
 │ conversion │────────────▶ server     │        │ hypervisor │
 │ server     │  port 5480 │            │        │   ┌─────┐  │
 └────────────┘            └────────────┘        │   │guest│  │
                                                 └───┴─────┴──┘
```

箭头表示TCP启动方向，不是数据传输方向。

从图中可以看出，virt-v2v 不是直接和ESXI连接，而是vCenter连接到hypervisor，所以，如果在vCenter与hypervisor之间有防火墙的话，需要打开额外的端口。

在做转换时代理环境变量（`https_proxy`, `all_proxy`, `no_proxy`, `HTTPS_PROXY`, `ALL_PROXY` and `NO_PROXY`）会失效。

## 7. vCenter：SSL/TLS 证书问题

可能会看到这个错误：

```shell
  CURL: Error opening file: SSL: no alternative certificate subject
  name matches target host name
```

（也许打开调试模式`virt-v2v -v -x`才能看到这个信息）

这是因为使用了IP地址访问，需要使用vCenter服务器完全合格的域名。

vCenter服务器不匹配的`FQDN`和IP地址（比如服务器获取了一个新的ip地址）会导致另一个证书问题。修复方法：改变DHCP服务或网络服务配置，让vCenter服务器有一个固定的IP地址；然后登录vCenter服务器的admin控制台`https://vcenter:5480/`，在`Admin`标签下，选择`Certificate regeneration enabled`，然后重启。
