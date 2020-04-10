```
gawk [ POSIX or GNU style options ] -f program-file [ -- ] file ...
gawk [ POSIX or GNU style options ] [ -- ] program-text file ...

program-text 使用单引号包围
OPTIONS
	-F fs  --field-separator fs		指定分隔符
	-v var=value					定义程序中的变量及默认值，引用变量时无需$符号
	-mf	N							指定处理的最大字段数
	-mr	N							指定文件最大行数

program
Built-in Variables
	FS          The input field separator, a space by default.
    OFS         The output field separator, a space by default.
	RS          The input record separator, by default a newline.
	ORS         The output record separator, by default a newline.
	NF          The number of fields in the current input record.
	NR          The total number of input records seen so far.
	
	$0			代表一整行
	$n			代表该行的第n个字段

Patterns
	BEGIN
    END
    BEGINFILE
    ENDFILE
    /regular expression/
    relational expression
    pattern && pattern
    pattern || pattern
    pattern ? pattern : pattern
    (pattern)
    ! pattern
    pattern1, pattern2

Control Statements
	if (condition) statement [ else statement ]
    while (condition) statement
    do statement while (condition)
    for (expr1; expr2; expr3) statement
    for (var in array) statement
    break
    continue
    delete array[index]
    delete array
    exit [ expression ]
    { statements }
    switch (expression) {
    case value|regex : statement
    ...
    [ default: statement ]
    }
```

脚本中的语法一样，但是不需要分号分隔多个命令：

```
[root@centos7 ~]# cat script.gawk
{
text = "Tom"
print text " is a superman."
}
[root@centos7 ~]# gawk -f script.gawk test1.txt
Tom is a superman.
Tom is a superman.
Tom is a superman.
Tom is a superman.
Tom is a superman.
```

使用条件语句：

```shell
[root@dev vitest]# cat -n /etc/passwd | awk -F: 'NR==1 {printf "%12s%12s\n", "name", "bash"}; $3 < 5 {print $1"\t"$7}'
        name        bash
     1  root    /bin/bash
     2  bin     /sbin/nologin
     3  daemon  /sbin/nologin
     4  adm     /sbin/nologin
     5  lp      /sbin/nologin
# 分隔符也可以在脚本里面定义，效果同上
[root@dev vitest]# cat -n /etc/passwd | awk 'BEGIN {FS=":"}; NR==1 {printf "%12s%12s\n", "name", "bash"}; $3 < 5 {print $1"\t"$7}'
# 脚本中定义的变量可以直接使用，无需$符号
[root@dev vitest]# cat -n /etc/passwd | awk 'BEGIN {FS=":"; head1="name"}; NR==1 {head2="bash"; printf "%12s%12s\n", head1, head2}; $3 < 5 {print $1"\t"$7}'
```

awk还支持运算：

```shell
cat pay. txt | \
> awk ' {if(NR==1) printf "%10s %10s %10s %10s %10s\n", $1, $2, $3, $4, "Total"}
> NR>=2{total = $2 + $3 + $4
> printf "%10s %10d %10d %10d %10.2f\n", $1, $2, $3, $4, total}'
```

