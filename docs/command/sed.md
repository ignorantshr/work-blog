替换文件中的内容：
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

