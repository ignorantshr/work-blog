```
sed [OPTION]... {script-only-if-no-other-script} [input-file]...

OPTION
	-n, --quiet, --silent					
	-f script-file, --file=script-file		从含有脚本的文件中执行动作
	-i[SUFFIX], --in-place[=SUFFIX]			直接修改文件，如果提供 SUFFIX，则进行备份
	-r, --regexp-extended					使用扩展的正则表达式
	
{script-only-if-no-other-script}：'[n1[,n2]]命令'
常用命令
	a Text	后接字符串，在匹配行的下一行新增字符串
    i Text	后接字符串，在匹配行的上一行新增字符串
    c Text	后接字符串，替换掉 n1-n2 之间的行
    y/inchars/outchars/		按照一一对应的关系进行字符转换
    s/pattern/replacement/[flags]		替换字符串
    d		删除行
    p		打印行
    =		打印行号
    l		打印出所有字符
    w filename	将匹配的写入文件
    r filename	从文件中读取数据
```
## 使用地址

若要指定某些行，则要使用`行寻址`，sed 中有两种行寻址：

- 以数字形式表示行区间
- 以文本模式匹配行

语法：

```
[address]command

address{
	command1
	command2
}
```

数字行寻址，左闭右闭原则：

```bash
sed -e '2,$d' rpms.list
```

文本行寻址：

```bash
sed -e '/class/d' setup.py
```

文本行寻址还可以使用正则表达式来匹配。

## 替换文件中的内容

### 替换标记

替换的语法：

```
s/pattern/replacement/[flags]
```

其中flags有以下几种：

- 数字：替换第几处的匹配文本
- g：替换所有的匹配文本
- p：打印匹配的行，经常与`-n`选项联用来只打印匹配的行
- w file：把替换结果写入文件

没有标记替换第一处匹配文本：

```shell
sed -i 's/refa/hyxz/' rpms.list
```

p 标记：

```
[root@centos7 ~]# cat test1.txt
this is line number 1
this is line number 2
this is line number 3
this is line number 4

[root@centos7 ~]# sed 's/1/that/p' test1.txt
this is line number that
this is line number that
this is line number 2
this is line number 3
this is line number 4
```

w 标记：

```
[root@centos7 ~]# sed 's/1/that/w test1-copy.txt' test1.txt
this is line number that
this is line number 2
this is line number 3
this is line number 4

[root@centos7 ~]# cat test1-copy.txt
this is line number that
```

### 替换字符

如果内容包含`/`，需要加上前缀进行转义：

```shell
sed -e 's/virt-v2v/\/home\/tmp\/usr\/local\/bin\/virt-v2v/g' convert.sh
```

或者使用`!`来方便书写，多个命令使用分号隔开：

```bash
sed 's!this!that!; s/is/it/' test1.txt
```

## 转换字符

自动找到所有的字符进行替换，inchars与outchars的长度必须相同：

```
[root@centos7 ~]# rm -f test1-copy.txt
[root@centos7 ~]# sed 'y/hijk/lmns/' test1.txt
tlms ms lmne number 1
tlms ms lmne number 2
tlms ms lmne number 3
tlms ms lmne number 4
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

打印出不可打印的字符

```
[root@centos7 ~]# sed 'l' test1.txt
this is line number 1$
this is line number 1
this is line number 2$
this is line number 2
```

## 读写文件

读取文件并插入：

```
[root@centos7 ~]# cat test2.txt
this is an added line.
[root@centos7 ~]# sed '/1/r test2.txt' test1.txt
this is line number 1
this is an added line.
this is line number 2
```

