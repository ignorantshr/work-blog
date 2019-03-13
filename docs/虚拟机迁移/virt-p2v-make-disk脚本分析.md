用于创建包含`virt-p2v`的`可引导磁盘映像`或`USB key`的脚本，使用`virt-builder`实现。

脚本位于`/libguestfs/p2v/virt-p2v-make-disk`。

# 使用介绍

输出一个virt-p2v可启动USB key到*/dev/sdX*：

```shell
 virt-p2v-make-disk -o /dev/sdX
```

输出一个virt-p2v可启动虚拟磁盘，在qemu下启动：

```shell
 virt-p2v-make-disk -o /var/tmp/p2v.img
 qemu-kvm -m 1024 -boot c \
   -drive file=/var/tmp/p2v.img,if=virtio,index=0 \
   -drive file=/var/tmp/guest.img,if=virtio,index=1
```

# 脚本分析
1.解析传入的选项，包括自身的选项、virt-builder可接受的选项、帮助选项。

2.获取一个操作系统版本。

​	没有设置的话，去检查`/etc/redhat-release`或`/etc/debian_version`是否存在，前者使用fedora系统，后者使用debian系统；都没有的话需要重新指定操作系统类型。

3.确定使用xz文件。

​	如果传入了`--arch`选项，使用`virt_p2v_xz_binary="$libdir/virt-p2v.$arch.xz"`，否则使用`virt_p2v_xz_binary="$libdir/virt-p2v.xz"`。前者需要自行构建。

4.创建临时输出目录。

​	`tmpdir="$(mktemp -d)"`

5.解压xz文件到临时目录。

6.依据不同的操作系统读取不同的依赖文件。

```shell
centos-*|fedora-*|rhel-*|scientificlinux-*)
	depsfile="$datadir/dependencies.redhat"
	重构initramfs
debian-*|ubuntu-*)
	depsfile="$datadir/dependencies.debian"
archlinux-*)
    depsfile="$datadir/dependencies.archlinux"
opensuse-*|suse-*)
    depsfile="$datadir/dependencies.suse"
```

7.执行`virt-builder`命令

```shell
virt-builder "$osversion"                                       \
    $verbose_option						\
    --output "$output"                                          \
    $arch_option						\
    $preinstall_args                                            \
    --update                                                    \
    --install "$install"                                        \
    --root-password password:p2v                                \
    --upload "$datadir"/issue:/etc/issue                        \
    --upload "$datadir"/issue:/etc/issue.net                    \
    --mkdir /usr/bin                                            \
    --upload "$virt_p2v_binary":/usr/bin/virt-p2v               \
    --chmod 0755:/usr/bin/virt-p2v                              \
    --upload "$datadir"/launch-virt-p2v:/usr/bin/               \
    --chmod 0755:/usr/bin/launch-virt-p2v                       \
    --upload "$datadir"/p2v.service:/etc/systemd/system/        \
    --mkdir /etc/systemd/system/multi-user.target.wants         \
    --link /etc/systemd/system/p2v.service:/etc/systemd/system/multi-user.target.wants/p2v.service \
    --edit '/lib/systemd/system/getty@.service:
        s/^ExecStart=(.*)/ExecStart=$1 -a root/
    '                                                           \
    --edit '/etc/systemd/logind.conf:
        s/^[Login]/[Login]\nReserveVT=1\n/
    '                                                           \
    $upload                                                     \
    $extra_args                                                 \
    "${passthru[@]}"                                            \
    $final_args
```

8.清理临时目录



