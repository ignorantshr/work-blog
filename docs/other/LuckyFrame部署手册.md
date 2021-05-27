> 本文说明的是如何编译部署 [LuckyFrame](http://www.luckyframe.cn) 项目。

项目地址：

- [服务端](https://gitee.com/seagull1985/LuckyFrameWeb)
- [客户端](https://gitee.com/seagull1985/LuckyFrameClient)

操作系统：

- 部署服务器：centos7.9.2009 x86_64
- 编译服务器：centos7.8.2003  x86_64



## 环境准备

### 部署环境

#### jdk

jdk1.8，不可过高或过低。

```
yum install java-1.8.0-openjdk
```

#### MySQL

根据[官网](https://dev.mysql.com/doc/refman/8.0/en/linux-installation-yum-repo.html)手册安装MySQL，版本最低要求是5.7（本文安装的是8.0版本）。

安装完成后删除原来的数据目录：

```
rm -rf /var/lib/mysql/
rm -rf /var/log/mariadb/
```

替换配置文件：

```
mv /etc/my.cnf.rpmnew /etc/my.cnf
```

修改配置文件，新增以下内容：

```
[client]
#修改客户端默认字符编码格式为utf8
default-character-set=utf8

[mysqld]
#不区分大小写
lower_case_table_names=1
character-set-server=utf8
default-time-zone = '+8:00'
default-storage-engine=INNODB
```

启动 mysqld 服务，

根据文档的指示修改root密码，然后创建数据库：

```
CREATE DATABASE `luckyframe`;
```

#### 运行目录

```
mkdir /opt/LuckyFrameWeb/
mkdir /opt/LuckyFrameClient/
```

### 编译环境

#### jdk

jdk1.8，不可过高或过低。

```
yum install java-1.8.0-openjdk-devel
```

#### maven

yum源中的版本太低不能使用，需要去[官网](https://maven.apache.org/download.cgi)下载安装新版本（本文安装的是3.8.1版本）。



## 编译

### 服务端

在编译之前先把部署环境搭建好。

```
git clone git@gitee.com:seagull1985/LuckyFrameWeb.git
cd LuckyFrameWeb
```

修改`src/main/resources/application-druid.yml`文件中的`password`为数据库密码，

修改`src/main/resources/application.yml`文件中的服务端口为`8080`。

编译命令：

```
mvn clean package
```

### 客户端

```
git clone git@gitee.com:seagull1985/LuckyFrameClient.git
cd LuckyFrameClient
```

修改`src/main/Resources/sys_config.properties`文件中服务器端口`server.web.port=80`为8080。

编译命令：

```
mvn clean package
```



## 部署

#### 服务端

将`target`下生成的jar包放在部署服务器上的`/opt/LuckyFrameWeb/`下。

创建`/etc/systemd/system/luckyframewebd.service`文件：

```
[Unit]
Description=LuckyFrameWeb

[Service]
Type=simple
User=root
Group=root
LimitNOFILE=65535
WorkingDirectory=/opt/LuckyFrameWeb
ExecStart=/usr/bin/java -jar LuckyFrameWeb.jar

[Install]
WantedBy=multi-user.target
```

重载配置文件：

```
systemctl daemon-reload
```

启动服务：

```
systemctl start luckyframewebd.service
```

查看状态：

```
systemctl status luckyframewebd.service
```

开机自启：

```
systemctl enable luckyframewebd.service
```

### 客户端

将`target`下生成的整个`classes`目录放在部署服务器上的`/opt/LuckyFrameClient/`下。

创建`/etc/systemd/system/luckyframeclientd.service`文件：

```
[Unit]
Description=LuckyFrameClient
After=luckyframewebd.service

[Service]
Type=forking
User=root
Group=root
LimitNOFILE=65535
WorkingDirectory=/opt/LuckyFrameClient/classes
ExecStart=/usr/bin/sh start_service.sh

[Install]
WantedBy=multi-user.target
```

重载配置文件：

```
systemctl daemon-reload
```

启动服务：

```
systemctl start luckyframeclientd.service
```

查看状态：

```
systemctl status luckyframeclientd.service
```

开机自启：

```
systemctl enable luckyframeclientd.service
```

### 访问地址

http://xxx:8080，默认账户密码：`admin/admin`。