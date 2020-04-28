# 目录
[toc]


# 架构

| 服务 |ip  | hostname |
| --- | --- | --- |
|DHCP & DNS  | 172.16.250.3 | centos2 |
| NFS客户机 | 172.16.250.9 | centos3 |
| NFS客户机 | 172.16.250.8 |  centos4|
| NFS服务 & SMB |172.16.250.7  | centos5 |
|  NFS客户机  & SMB客户机   |    172.16.250.5    |   centos6  |
|   NFS客户机      |   172.16.250.10  |    cenyos7  |


## 配置centos(2)主机DHCP服务
### 1、修改网卡配置文件
```
vim /etc/sysconfig/network-scripts/ifcfg-ens160 
```
```
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=ens160
UUID=9c191f9f-60b0-4af4-a11b-b5f852fb8df2
DEVICE=ens160
ONBOOT=yes
IPADDR=172.16.250.3
NETMASK=255.255.255.0
GATEWAY=172.16.250.2
DNS1=8.8.8.8
```

### 2、Vmware配置
配置网关为：172.16.250.2
配置端口转发
![7491248336a64fb49ea9587018d2d989.png](en-resource://database/30553:1)@w=500

### 3、安装DHCP
```
yum -y install dhcp-server.x86_64
```

### 4、更改配置文件

```
authoritative;
#
# # Use this to send dhcp log messages to a different log file (you also
# # have to hack syslog.conf to complete the redirection).
#log-facility local7;
#
# # No service will be given on this subnet, but declaring it helps the 
# # DHCP server to understand the network topology.
#
# subnet 10.152.187.0 netmask 255.255.255.0 {
# }
#
# # This is a very basic subnet declaration.
subnet 172.16.250.0 netmask 255.255.255.0 {
         range 172.16.250.4 172.16.250.254;
         option routers 172.16.250.2;     #随DHCP分发的默认网关
         option domain-name-servers 8.8.8.8;    #随DHCP分发的DNS
         option domain-name "test.cn";
         option broadcast-address 172.16.250.255;
         default-lease-time 600;
         max-lease-time 7200;
}
```
### 5、启动服务
```
systemctl start dhcpd 
systemctl enable dhcpd 
systemctl status dhcpd
```

### 6、配置客户机
```
TYPE=Ethernet
BOOTPROTO=dhcp
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
ONBOOT=yes
GATEWAY=172.16.250.3    #这里要设置成DHCP服务器的ip地址
NETMASK=255.255.255.0
DNS1=8.8.8.8
```
重新从dhcp服务器申请ip
```
sudo dhclient -v
```
修改默认网关
```
route add default gw 172.16.250.2
```




## 配置centos（2）主机DNS服务
### 1、安装
```
 yum install bind-chroot
```
### 2、修改主配置文件
把第11行和第17行的地址均修改为any，分别表示服务器上的所有IP地址均可提供DNS域名解析服务，以及允许所有人对本服务器发送DNS查询请求

```
vim /etc/named.conf
```

往options块内添加一条选项
```
forwarders { IP;};

```
IP填转发的服务器地址，重启named服务即可


### 3、编辑区域配置文件
```
zone "ahrs.lan" IN {
        type master;
        file "ahrs.lan.zone";
        allow-update { none; };
};


zone "ahrs.com" IN {
        type master;
        file "ahrs.com.zone";
        allow-update { none; };
};
```
### 4、编辑数据配置文件
从/var/named目录中复制一份正向解析的模板文件（named.localhost），然后把域名和IP地址的对应数据填写数据配置文件中并保存。
```
cd /var/named/
```
从/var/named目录中复制一份正向解析的模板文件（named.localhost），然后把域名和IP地址的对应数据填写数据配置文件中并保存。

### 5、启动
```
systemctl restart named
systemctl enable named
```

### 6、修改客户机DNS
```
vim  /etc/resolv.conf
```

 ### 7、修改DNS服务端的防火墙配置
 ```
 firewall-cmd --add-service=dns
```

## 代理（未完成）













## RAID10


### 为centos5添加硬盘
![b018f9d4f7412f28ee3dd5fc5f887546.png](en-resource://database/30701:1)@w=400

### 部署磁盘阵列
```
mdadm -Cv /dev/md0 -a yes -n 4 -l 10 /dev/nvme0n2 /dev/nvme0n3  /dev/nvme0n4 /dev/nvme0n5
```

```
mkfs.ext4 /dev/md0
```
```
mount /dev/md0 /RAID
```
![014b58133eb274605c605dbfc6d5c663.png](en-resource://database/30703:1)

```
echo "/dev/md0 /RAID ext4 defaults 0 0" >> /etc/fstab
```


## NFS
### 安装
```
yum install nfs-utils
```

### 创建共享目录
```
[root@centos5 /]# mkdir /nfsfile
[root@centos5 /]# chmod -Rf 777 /nfsfile/
```
### 启动服务
```
systemctl restart rpcbind 
systemctl enable rpcbind 
systemctl start nfs-server 
systemctl enable nfs-server
```
### 配置客户机centos3、centos4
```
mount -t nfs 172.16.250.7:/nfsfile /nfsfile
```
并且写入/etc/fstab


## SMB
### 创建用户和用户组
```
[root@centos5 /nfsfile]# groupadd Accounting
[root@centos5 /nfsfile]# groupadd HR
[root@centos5 /nfsfile]# groupadd IT
```
```
[root@centos5 /nfsfile]# useradd -d /home/germaine -g Accounting germaine
[root@centos5 /nfsfile]# id germaine
uid=1000(germaine) gid=1000(Accounting) groups=1000(Accounting)
[root@centos5 /nfsfile]# useradd -d /home/michel -g HR michel
[root@centos5 /nfsfile]# id michel
uid=1001(michel) gid=1001(HR) groups=1001(HR)
[root@centos5 /nfsfile]# useradd -d /home/paul -g IT paul
[root@centos5 /nfsfile]# id paul
uid=1002(paul) gid=1002(IT) groups=1002(IT)
[root@centos5 /nfsfile]# useradd -d /home/mathieu -g IT mathieu
[root@centos5 /nfsfile]# id mathieu
uid=1003(mathieu) gid=1002(IT) groups=1002(IT)
```
| User     | Group      |
|----------|------------|
| germaine | Accounting |
| michel   | HR         |
| paul     | IT         |
| mathieu  | IT         |
### 创建文件夹
```
[root@centos5 /home]# mkdir hr
[root@centos5 /home]# chown -R michel:HR hr/

[root@centos5 /home]# mkdir accounting
[root@centos5 /home]# chown -R germaine:Accounting accounting/
```
### 创建用户确定初始密码
```
pdbedit -a -u germaine
pdbedit -a -u michel
pdbedit -a -u paul
pdbedit -a -u mathieu
```
### 修改配置文件

在 /etc/samba/smb.con 添加如下内容
```
[germaine]
        path = /home/germaine
        browseable = yes
        writable = yes
        valid users = germaine
[michel]
        path = /home/michel
        browseable = yes
        writable = yes
        valid users = michel
[paul]
        path = /home/paul
        browseable = yes
        writable = yes
        valid users = paul
[mathieu]
        path = /home/mathieu
        browseable = yes
        writable = yes
        valid users = mathieu

[hr]
        path = /home/hr
        browseable = yes
        writable = yes
        valid users = @IT,@HR



[accounting]
        path = /home/accounting
        browseable = yes
        writable = yes
        valid users = @IT,@Accounting
```
### 禁止用户登录
```
germaine:x:1000:1000::/home/germaine:/bin/false
michel:x:1001:1001::/home/michel:/bin/false
```


### 脚本(未完成)






### 配置客户机SMB
安装
```
yum install samba-client.x86_64
```

连接SMB
```
smbclient //172.16.250.7/germaine -U germaine
```
如连接其他目录，将会失败
![1ba97ca0e0e3059107f0798defc8d7c4.png](en-resource://database/30705:1)

组连接SMB
```
[root@centos6 /]# smbclient //172.16.250.7/accounting -U paul
Enter SAMBA\paul's password: 
Try "help" to get a list of possible commands.
smb: \> 
```


## Apache（未完成）







## Mysql（未完成）




## 前端服务器（未完成）