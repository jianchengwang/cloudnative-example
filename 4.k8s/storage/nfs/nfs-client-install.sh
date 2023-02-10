#!/bin/bash

yum -y install nfs-utils rpcbind

# ip地址为nfs服务的地址
showmount -e 172.22.0.12

# 挂载目录
# mkdir -p /data/storage/nfs
# mount -t nfs 172.22.0.12:/data/nfs /data/storage/nfs
