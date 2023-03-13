#!/bin/bash

# install prometheus
mkdir -p /opt/prometheus
wget https://s3-gz01.didistatic.com/n9e-pub/prome/prometheus-2.28.0.linux-amd64.tar.gz -O prometheus-2.28.0.linux-amd64.tar.gz
tar xf prometheus-2.28.0.linux-amd64.tar.gz
cp -far prometheus-2.28.0.linux-amd64/*  /opt/prometheus/

# service 
cat <<EOF >/etc/systemd/system/prometheus.service
[Unit]
Description="prometheus"
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple

ExecStart=/opt/prometheus/prometheus  --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data --web.enable-lifecycle --enable-feature=remote-write-receiver --query.lookback-delta=2m 

Restart=on-failure
SuccessExitStatus=0
LimitNOFILE=65536
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=prometheus


[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl restart prometheus
systemctl status prometheus

# install mysql
yum -y install mariadb*
systemctl enable mariadb
systemctl restart mariadb
mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('1234');"

# install redis
yum install -y redis
systemctl enable redis
systemctl restart redis

# install nightingale
mkdir -p /opt/n9e && cd /opt/n9e

# 去 https://github.com/didi/nightingale/releases 找最新版本的包，文档里的包地址可能已经不是最新的了
tarball=n9e-v5.15.0-linux-amd64.tar.gz
urlpath=https://github.com/didi/nightingale/releases/download/v5.15.0/${tarball}
wget $urlpath || exit 1

tar zxvf ${tarball}

mysql -uroot -p1234 < docker/initsql/a-n9e.sql

nohup ./n9e server &> server.log &
nohup ./n9e webapi &> webapi.log &

# check logs
# check port