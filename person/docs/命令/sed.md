```
sed [OPTION]... {script-only-if-no-other-script} [input-file]...

OPTION
	-n, --quiet, --silent					不输出没有变动的行
	-f script-file, --file=script-file		从含有脚本的文件中执行动作
	-i[SUFFIX], --in-place[=SUFFIX]			直接修改文件，如果提供 SUFFIX，则进行备份
	-r, --regexp-extended					使用扩展的正则表达式
	
{script-only-if-no-other-script}：'[n1[,n2]]动作'
常用动作
	a		后接字符串，在匹配行的下一行新增字符串
    i		后接字符串，在匹配行的上一行新增字符串
    c		后接字符串，替换掉 n1-n2 之间的行
    d		删除行
    p		打印行
    s		替换字符串
```



## 替换文件中的内容

```shell
sed -i 's/refa/hyxz/' rpms.list
```

选项含意：

- -i：写入到文件中
- -e：指定执行的命令，在控制台输出

如果内容包含`/`，需要加上前缀进行转义：

```shell
sed -e 's/virt-v2v/\/home\/tmp\/usr\/local\/bin\/virt-v2v/g' convert.sh
```

## 删除指定行

根据行号删除：

```shell
sed -e '2,$d' rpms.list
```

根据匹配的字符串删除：

```shell
sed -e '/class/d' setup.py
```

## 插入多行

```bash
[root@dev vitest]# nl /etc/passwd | sed '2i first line\
> second line'
     1  root:x:0:0:root:/root:/bin/bash
first line
second line
     2  bin:x:1:1:bin:/bin:/sbin/nologin
```

## 取代行

```shell
[root@dev vitest]# nl /etc/passwd | sed '1,4c No lines.'
No lines.
     5  lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
```

## 打印行

```shell
[root@dev vitest]# nl /etc/passwd | sed -n '1,3p'
     1  root:x:0:0:root:/root:/bin/bash
     2  bin:x:1:1:bin:/bin:/sbin/nologin
     3  daemon:x:2:2:daemon:/sbin:/sbin/nologin
```

