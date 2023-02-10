#!/bin/bash

# install nfs
yum -y install rpcbind nfs-utils

# mkdir share dir
mkdir /data/nfs/
chmod 755 -R /data/nfs/

# rw 表示设置目录可读写。
# sync 表示数据会同步写入到内存和硬盘中，相反 rsync 表示数据会先暂存于内存中，而非直接写入到硬盘中。
# no_root_squash NFS客户端连接服务端时如果使用的是root的话，那么对服务端分享的目录来说，也拥有root权限。
# no_all_squash 不论NFS客户端连接服务端时使用什么用户，对服务端分享的目录来说都不会拥有匿名用户权限。
tee /etc/exports <<-'EOF'
/data/nfs/ 172.22.0.0(rw,no_root_squash,no_all_squash,sync)
EOF

# 设置固定端口
tee /etc/sysconfig/nfs <<-'EOF'
RQUOTAD_PORT=1001
LOCKD_TCPPORT=30001
LOCKD_UDPPORT=30002
MOUNTD_PORT=1002
EOF

# 启动服务
systemctl start rpcbind
systemctl start nfs
systemctl status nfs-server

# 生效
exportfs -ra


