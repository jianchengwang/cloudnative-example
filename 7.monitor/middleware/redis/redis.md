## 关键指标

### 延迟

```shell
redis-cli --latency -h 10.206.0.16 -p 6379
min: 33, max: 58, avg: 35.30 (1013 samples)
```

如果我们发现 Redis 变慢了，应该怎么找到那些执行得很慢的命令呢？这就要求助于 slowlog 了。说到慢日志，首先我们要定义执行时间超过多久算慢，Redis 默认的配置是 10 毫秒，比如我们调整成 5 毫秒。

```shell
$ grep slower /etc/redis.conf
slowlog-log-slower-than 10000
$ redis-cli
127.0.0.1:6379> config set slowlog-log-slower-than 5000
OK
127.0.0.1:6379> config get slowlog-log-slower-than
1) "slowlog-log-slower-than"
2) "5000"
127.0.0.1:6379> config rewrite
OK
127.0.0.1:6379> quit
$ grep slower /etc/redis.conf
slowlog-log-slower-than 5000
```

之后一些执行时间超过 5 毫秒的命令就会被记录下来，然后使用 slowlog get [count] 就能查看 count 出来的 slowlog 条数了。这里我获取 2 条作为样例。

```shell
127.0.0.1:6379> SLOWLOG get 2
1) 1) (integer) 47
   2) (integer) 1668743666
   3) (integer) 13168
   4) 1) "hset"
      2) "/idents/Default"
      3) "tt-fc-dev01.nj"
      4) "1668743666"
   5) "127.0.0.1:43172"
   6) ""
2) 1) (integer) 46
   2) (integer) 1668646906
   3) (integer) 13873
   4) 1) "hset"
      2) "/idents/Default"
      3) "10.206.16.3"
      4) "1668646906"
   5) "127.0.0.1:44612"
   6) ""
```

### 流量

```shell
$ redis-cli -h 127.0.0.1 -p 6379 info all | grep instantaneous
instantaneous_ops_per_sec:0
instantaneous_input_kbps:0.00
instantaneous_output_kbps:0.00
```

1. `ops_per_sec` 表示每秒执行多少次操作，
2. `input_kbps` 表示每秒接收多少 KiB，output_kbps 表示每秒返回多少 KiB。因为我这个 Redis 几乎没有什么流量，所以返回的都是 0，正常来讲，一个 Redis 实例每秒处理几万个请求都是很正常的。

每秒处理的操作如果较为恒定，是非常健康的。如果发现 ops_per_sec 变少了，就要注意了，有可能是某个耗时操作导致的命令阻塞，也有可能是客户端出了问题，不发请求过来了。

如果把 Redis 当做缓存来使用，我们还需关注 `keyspace_hits` 和 `keyspace_misses` 两个指标。

```shell
$ redis-cli -h 127.0.0.1 -p 6379 info all | grep keyspace
keyspace_hits:62033897
keyspace_misses:10489649
```

这两个指标都是 Counter 类型，单调递增，即 Redis 实例启动以来，统计的所有命中的数量和未命中的数量。如果要统计总体的命中率，使用 hits 除以总量即可。

```shell
hit rate = keyspace_hits / (keyspace_hits + keyspace_misses)
```

如果要关注近期的命中率，比如最近 10 分钟，就要通过 PromQL increase 函数等做二次运算。

```shell
increase(keyspace_hits[10m])/(increase(keyspace_hits[10m]) + increase(keyspace_misses[10m]))
```

如果命中率低于 0.8 就要注意了，有可能是内存不够用，很多 Key 被清理了。当然，也可能是数据没有及时填充或过期了。较低的命中率显然会对应用程序的延迟有影响，因为通常来讲，当应用程序无法从 Redis 中获取缓存数据时，就要穿透到更慢的存储介质去获取数据了。

### 错误

Redis 在响应客户端请求时，通常不会有什么内部错误产生，毕竟只是操作内存，依赖比较少，出问题的概率就很小了。如果是客户端错误一般做客户端埋点监控，自己发现了然后自己去解决。

Redis 对客户端的数量也有一个最大数值的限制，默认是 10 万，如果超过了这个数量，rejected_connections 指标就会 +1。和 MySQL 不一样的是，Redis 使用过程中，应该很少遇到超过最大连接数（maxclients） 的情况，不过谨慎起见，也可以对 rejected_connections 做一下监控。

### 饱和度

```shell
$ redis-cli -h 127.0.0.1 -p 6379 info memory 
used_memory:853432
used_memory_human:833.43K
used_memory_rss:7864320
used_memory_rss_human:7.50M
used_memory_peak:890088
used_memory_peak_human:869.23K
total_system_memory:16288477184
total_system_memory_human:15.17G
used_memory_lua:37888
used_memory_lua_human:37.00K
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
mem_fragmentation_ratio:9.21
mem_allocator:jemalloc-3.6.0
```

1. used_memory 使用内存
2. used_memory_rss 分配内存
3. used_memory_rss 除以 used_memory 就是内存碎片率，即 mem_fragmentation_ratio。

机器内存不够用了，碎片化的内存浪费太多，并且碎片化率很高的时候才需要处理。我们可以通过调整下面的参数来控制碎片处理过程。

```conf
# 开启自动内存碎片整理(总开关)
activedefrag yes
# 当碎片达到 100mb 时，开启内存碎片整理
active-defrag-ignore-bytes 100mb
# 当碎片超过 10% 时，开启内存碎片整理
active-defrag-threshold-lower 10
# 内存碎片超过 100%，则尽最大努力整理
active-defrag-threshold-upper 100
# 内存自动整理占用资源最小百分比
active-defrag-cycle-min 25
# 内存自动整理占用资源最大百分比
active-defrag-cycle-max 75
```

饱和度的度量方面，还有一个指标是 evicted_keys，表示当内存占用超过了 maxmemory 的时候，Redis 清理的 Key 的数量。实际上，内存达到 maxmemory 的时候，具体是怎么一个处理策略，是可以配置的，默认的策略是 noeviction。

```shell
$ redis-cli
127.0.0.1:6379> config get maxmemory-policy
1) "maxmemory-policy"
2) "noeviction"
```

## 采集配置

### Categraf配置

Categraf 也提供了 Redis 采集插件，配置样例在 `conf/input.redis/redis.toml`，我们看一下。

```toml
[[instances]]
# address = "127.0.0.1:6379"
# username = ""
# password = ""
# pool_size = 2

# # Optional. Specify redis commands to retrieve values
# commands = [
#     {command = ["get", "sample-key1"], metric = "custom_metric_name1"},
#     {command = ["get", "sample-key2"], metric = "custom_metric_name2"}
# ]

# labels = { instance="n9e-dev-redis" }
```

最核心的配置就是 address，也就是 Redis 的连接地址，然后是认证信息，username 字段低版本的 Redis 是不需要的，如果是 6.0 以上的版本并且启用了 ACL 的才需要。

commands 的作用是自定义一些命令来获取指标，和 MySQL 采集器中的 queries 类似，在业务指标采集的场景，通常能发挥奇效。

labels 是个通用配置，所有的 Categraf 的采集器，都支持在 [[instances]] 下面自定义标签。当然，我个人还是习惯使用机器名来过滤，这样便于把 Redis 的指标和 Redis 所在机器的指标放到一张大盘里展示。

### 监控大盘

[nightingale-dashboard](https://github.com/flashcatcloud/categraf/blob/main/inputs/redis/dashboard.json)

