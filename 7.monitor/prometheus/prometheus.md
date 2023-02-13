## 部署Prometheus

Prometheus 的下载地址：[https://prometheus.io/download/](https://prometheus.io/download/)

```shell
$ /opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data --web.enable-lifecycle --enable-feature=remote-write-receiver --query.lookback-delta=2m --web.enable-admin-api

--config.file=/opt/prometheus/prometheus.yml
指定 Prometheus 的配置文件路径

--storage.tsdb.path=/opt/prometheus/data
指定 Prometheus 时序数据的硬盘存储路径

--web.enable-lifecycle
启用生命周期管理相关的 API，比如调用 /-/reload 接口就需要启用该项

--enable-feature=remote-write-receiver
启用 remote write 接收数据的接口，启用该项之后，categraf、grafana-agent 等 agent 就可以通过 /api/v1/write 接口推送数据给 Prometheus

--query.lookback-delta=2m
即时查询在查询当前最新值的时候，只要发现这个参数指定的时间段内有数据，就取最新的那个点返回，这个时间段内没数据，就不返回了

--web.enable-admin-api
启用管理性 API，比如删除时间序列数据的 /api/v1/admin/tsdb/delete_series 接口

```

服务默认启动在9090端口

同时 Prometheus 在配置文件里配置了抓取规则，打开 prometheus.yml 就可以看到了。

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']
```

localhost:9090 是暴露监控数据的地址，没有指定接口路径，默认使用 /metrics，没有指定 scheme，默认使用 HTTP，所以实际请求的是 http://localhost:9090/metrics。

## 部署Node-Exporter

下载 [Node-Exporter](https://prometheus.io/download/#node_exporter)

Node-Exporter 默认的监听端口是 9100，我们可以通过下面的命令看到 Node-Exporter 采集的指标。

```shell
$ curl -s localhost:9100/metrics
```

修改prometheus配置，

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
    - targets: ['localhost:9100']
```

并且`kill -HUP <prometheus pid>`生效

```shell
$ lsof -i:9090
prometheu 8213 root
$ kill -HUP 8213
```

Node-Exporter 默认内置了很多 collector，比如 cpu、loadavg、filesystem 等，可以通过命令行启动参数来控制这些 collector，比如要关掉某个 collector，使用 --no-collector.，如果要开启某个 collector，使用 --collector.。具体可以参考 Node-Exporter 的 [README](https://github.com/prometheus/node_exporter#collectors) 。Node-Exporter 默认采集几百个指标，有了这些数据，我们就可以演示告警规则的配置了。

## 配置告警规则

Prometheus 进程内置了告警判断引擎，prometheus.yml 中可以指定告警规则配置文件，默认配置中有个例子。

```yaml
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"
```

我们可以把不同类型的告警规则拆分到不同的配置文件中，然后在 prometheus.yml 中引用。比如 Node-Exporter 相关的规则，我们命名为 node_exporter.yml，最终这个 rule_files 就变成了如下配置。

```yaml
rule_files:
  - "node_exporter.yml"
```

这边设计一个例子，监控 Node-Exporter 挂掉以及内存使用率超过 1% 这两种情况。这里我故意设置了一个很小的阈值，确保能够触发告警。参考 [node_exporter.yml]

给 Prometheus 进程发个 HUP 信号，让它重新加载配置文件。

```shell
kill -HUP 8213
```

## 部署 Alertmanager

Alertmanager 会读取二进制同级目录下的 alertmanager.yml 配置文件。我使用 163 邮箱作为 SMTP 发件服务器，下面我们来看下具体的配置。

```yaml
global:
  smtp_from: 'username@163.com'
  smtp_smarthost: 'smtp.163.com:465'
  smtp_auth_username: 'username@163.com'
  smtp_auth_password: '这里填写授权码'
  smtp_require_tls: false
  
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 1m
  repeat_interval: 1h
  receiver: 'email'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'

  - name: 'email'
    email_configs:
    - to: 'ulricqin@163.com'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

## 部署 Grafana

Grafana 是一个数据可视化工具，有丰富的图表类型，视觉效果很棒，插件式架构，支持各种数据源，是开源监控数据可视化的标杆之作。

