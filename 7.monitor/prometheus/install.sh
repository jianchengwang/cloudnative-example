#!/bin/bash

# prometheus 9090
mkdir -p /opt/prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.42.0/prometheus-2.37.1.linux-amd64.tar.gz
tar xf prometheus-2.42.0.linux-amd64.tar.gz
cp -far prometheus-2.42.0.linux-amd64/*  /opt/prometheus/
rm -rf prometheus-2.42.0.linux-amd64
rm -rf prometheus-2.42.0.linux-amd64.tar.gz

# prometheus service 
cat <<EOF >/etc/systemd/system/prometheus.service
[Unit]
Description="prometheus"
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple

ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data --web.enable-lifecycle --enable-feature=remote-write-receiver --query.lookback-delta=2m --web.enable-admin-api

Restart=on-failure
SuccessExitStatus=0
LimitNOFILE=65536
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=prometheus



[Install]
WantedBy=multi-user.target
EOF

systemctl enable prometheus
systemctl start prometheus
systemctl status prometheus

# alert manager
mkdir -p /opt/alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz
tar xf alertmanager-0.25.0.linux-amd64.tar.gz
cp -far alertmanager-0.25.0.linux-amd64/*  /opt/alertmanager/
rm -rf alertmanager-0.25.0.linux-amd64
rm -rf alertmanager-0.25.0.linux-amd64.tar.gz

# alertmanager service 
cat <<EOF >/etc/systemd/system/alertmanager.service
[Unit]
Description="alertmanager"
After=network.target

[Service]
Type=simple

ExecStart=/usr/local/alertmanager/alertmanager
WorkingDirectory=/usr/local/alertmanager

Restart=on-failure
SuccessExitStatus=0
LimitNOFILE=65536
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=alertmanager



[Install]
WantedBy=multi-user.target
EOF

systemctl enable alertmanager
systemctl start alertmanager
systemctl status alertmanager

# node-exporter 9100
mkdir -p /opt/node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar xf node_exporter-1.5.0.linux-amd64.tar.gz
cp -far node_exporter-1.5.0.linux-amd64/* /opt/node_exporter/
rm -rf node_exporter-1.5.0.linux-amd64
rm -rf node_exporter-1.5.0.linux-amd64.tar.gz
nohup /opt/node_exporter/node_exporter &> output.log &

# grafana 3000
mkdir -p /opt/grafana
wget https://dl.grafana.com/oss/release/grafana-9.3.6.linux-amd64.tar.gz
tar xf grafana-9.3.6.linux-amd64.tar.gz
cp -far grafana-9.3.6.linux-amd64/* /opt/grafana/
rm -rf grafana-9.3.6.linux-amd64
rm -rf grafana-9.3.6.linux-amd64.tar.gz
