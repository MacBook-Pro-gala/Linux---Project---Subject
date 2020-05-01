# 目录
[toc]

# 架构

| 服务 |ip  | hostname | 解释|
| --- | --- | --- | ---|
|DHCP & DNS  | 172.16.250.3 | centos2 | |
| NFS客户机 & 阿帕奇 | 172.16.250.9 | centos3 | |
| NFS客户机 & 阿帕奇| 172.16.250.103 |  centos4| |
| NFS服务 & SMB |172.16.250.7  | centos5 | |
|  NFS客户机  & SMB客户机   |    172.16.250.5    |   centos6  |  笔记本|
|   NFS客户机   & MySQL  |   172.16.250.10  |    centos7  | |
|   NFS客户机   & 前端  |   172.16.250.4  |    centos8  | |
|   NFS客户机   & 前端  |   172.16.250.130  |    centos9  | |

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

ahrs.com.zone
```
$TTL 1D
@       IN SOA  ahrs.com. root.ahrs.com. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      @
           A    172.16.250.4
www     IN A    172.16.250.4
```
ahrs.lan.zone
```
$TTL 1D
@       IN SOA  ahrs.lan. root.ahrs.lan. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      @
           A    172.16.250.4
www     IN A    172.16.250.4
```
![fe73eefc581136bd9c48a98411fb4071.png](en-resource://database/31263:1)





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

## 代理（squid）
配置服务端
```
vim /etc/squid/squid.conf
```
```
acl block_sites url_regex "/etc/squid/audio-video/domains"
http_access allow all
```


客户端
![4cc5a61d424ea24964a2a52d6784a6c6.png](en-resource://database/31265:1)


可以看到www.bing.com可以访问
![1da1565481b9766886063a3c58fd9fa4.png](en-resource://database/31426:1)

而且https://www.videofriends.net/无法访问
![5d689ef2d2edc66c2e68d0f491313080.png](en-resource://database/31428:1)











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


### 脚本

```shell
#!/bin/bash
passwd=`mkpasswd -l 9 -s 1`
echo "${passwd}"

printf "${passwd}\n${passwd}\n"  | sudo -A smbpasswd $1 -s
```
执行：
```
[root@centos5 /]# ./passwdchange.sh germaine
```




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


## Apache
```
yum install httpd
```
```
cd /etc/httpd/conf
vim httpd.conf 
```
修改配置文件
```
DocumentRoot "/nfsfile"
<Directory "/nfsfile">
```


安装相关组件
```

yum -y install php


yum -y install php-common php-cli php-gd php-pdo php-develf


yum -y install php-xml php-json php-mysqlnd php-bcmath

```
## Wordpress
访问
```
http://172.16.250.8/wp-admin/setup-config.php
```
![b5f8242bbb48741835fef83b06555c17.png](en-resource://database/31255:1)
wordpress负载均衡
打开数据库，找到wp_options表单
```
1.修改url为haproxy前端地址
    1 siteurl http://172.16.250.4 yes
2.修改url为haproxy前端地址
    36 home http://172.16.250.4 yes
```
## Mysql
### Mysql安装
```
yum install mysql-server
```


```
systemctl enable mysqld.service
```
```
update user set host='%' where user='root';
```
### MySQL每日备份
脚本：
```shell
#!/bin/bash
#删除90天前数据

find /nfsfile/backup -mtime +90 -name "*.*" -exec rm -rf {} \;

mysqldump -uroot -p"liuyuhan" --single-transaction wordpress > /nfsfile/backup/wordpress_`date +%Y%m%d`.dump
```
```
crontab -e
```

```
30 0 * * * /backup.sh
```



## 代理服务器haproxy
```
yum install haproxy
```

修改配置文件/etc/haproxy/haproxy.cfg
```
global
        maxconn         10000
        stats socket    /var/run/haproxy.stat mode 600 level admin
        log             127.0.0.1 local0
        user     root
        group            root
        chroot          /var/empty
        daemon

defaults
        mode            http
        log             global
        option          httplog
        option          dontlognull
        monitor-uri     /monitoruri
        maxconn         8000
        timeout client  30s

        stats uri       /admin/stats
        option prefer-last-server
        retries         2
        option redispatch
        timeout connect 5s
        timeout server  5s


# The public 'www' address in the DMZ
frontend public
        bind             *:80 name clear
        #bind            192.168.1.10:443 ssl crt /etc/haproxy/haproxy.pem
        #use_backend     static if { hdr_beg(host) -i img }
        #use_backend     static if { path_beg /img /css   }
        default_backend  static

# The static backend backend for 'Host: img', /img and /css.
backend static
        balance         roundrobin
        server          statsrv1 172.16.250.9:80 check inter 1000
       server          statsrv2 172.16.250.103:80 check inter 1000
```

# 奖励部分

## PhpMyadmin
打开libraries/config.default.php，对下面三行进行修改：
```
$cfg['Servers'][$i]['host'] = '172.16.250.10';
$cfg['Servers'][$i]['port'] = '3306';

$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = 'liuyuhan';
```

在浏览器打开
[http://172.16.250.9/phpMyAdmin/index.php](http://172.16.250.9/phpMyAdmin/index.php)
![96ba33251990388b904941a8cf5466bd.png](en-resource://database/30937:1)

## 自动更新黑名单脚本(for Squid)



## Add a secondary Front server and setup a DNS-RoundRobin to feed these frontal servers

### 修改DNS配置文件
vim /etc/named.conf 
```
        multiple-cnames yes;
        rrset-order {
        class IN type ANY name "*" order cyclic;
        };
```


vim /var/named/ahrs.com.zone 

```
$TTL 1D
@       IN SOA  ahrs.com. root.ahrs.com. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      @
           A    172.16.250.4
www     IN A    172.16.250.4
        IN A    172.16.250.130
```

vim /var/named/ahrs.lan.zone 
```
$TTL 1D
@       IN SOA  ahrs.lan. root.ahrs.lan. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      @
           A    172.16.250.4
www     IN A    172.16.250.4
        IN A    172.16.250.130
```

### 修改wordpress的wp_options数据表
![1f6fe853151a292276be09b1e30e1097.png](en-resource://database/32172:1)

### 演示
当关闭172.16.250.4的haproxy.service 服务
仍然能够通过域名www.ahrs.com来访问到172.16.250.130的haproxy.service 服务
![663c6d7127af40b7ec95fdf671b11b8a.png](en-resource://database/32174:0)
