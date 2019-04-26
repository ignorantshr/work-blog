# VMware-vddk虚拟机转换

此种转换方式可在vCenter与ESXi服务器上面使用。提供的uri连接也是这两种形式的。下面介绍最简单的转换用法。

需要在VMware下载[开发库](https://code.vmware.com/web/sdk/6.7/vddk)，但是此库是非开源的，不允许重新分发或商业用途，慎用。

## 1.获取服务器的指纹

在ESXi服务器上面执行：

```shell
openssl x509 -in /etc/vmware/ssl/rui.crt -fingerprint -sha1 -noout
```

或在vCenter服务器上面执行：

```shell
openssl x509 -in /etc/vmware-vpx/ssl/rui.crt -fingerprint -sha1 -noout
```

## 2.测试URI连接

测试方法与vCenter的方式一致，参考：[VMware-vCenter转换](VMware-vCenter转换.md)

## 3.执行转换

```shell
virt-v2v -ic esx://root@192.168.216.153?no_verify=1 centos-esxi-1 \
	-it vddk \
	-io vddk-libdir=vmware-vix-disklib-distrib/ \
	-io vddk-thumbprint=B2:01:D5:F3:B5:F1:9E:4A:C4:1D:53:4F:18:07:2B:66:B8:AD:E7:95 \
	-o rhv -os 172.16.2.124:/home/exports  --password-file esxi.pass
```

- vddk-libdir 指定开发库所在目录
- vddk-thumbprint 指定服务器的指纹

其它可选选项：*-io vddk-config*, *-io vddk-cookie*, *-io vddk-nfchostport*, *-io vddk-port*, *-io vddk-snapshot*, *-io vddk-transports* and *-io vddk-vimapiver*，可通过`man nbdkit-vddk-plugin`查看具体意思。