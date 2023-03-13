## 关键指标

![google-gold-indicator](./google-gold-indicator.webp)

### 延迟

#### 客户端埋点

即上层业务程序在请求 MySQL 的时候，记录一下每个 SQL 的请求耗时，把这些数据统一推给监控系统，监控系统就可以计算出平均延迟、95 分位、99 分位的延迟数据了。不过因为要埋点，对业务代码有一定侵入性。

#### Slow queries

```sql
SHOW VARIABLES LIKE 'long_query_time'; -- default 10s
show global status like 'Slow_queries';
```

#### 通过 performance schema 和 sys schema 拿到统计数据

比如 `performance schema` 的 `events_statements_summary_by_digest` 表，这个表捕获了很多关键信息，比如延迟、错误量、查询量。我们看下面的例子，SQL 执行了 2 次，平均执行时间是 325 毫秒，表里的时间度量指标都是以皮秒为单位。

```sql
*************************** 1. row ***************************
                SCHEMA_NAME: employees
                     DIGEST: 0c6318da9de53353a3a1bacea70b4fce
                DIGEST_TEXT: SELECT * FROM `employees` WHERE `emp_no` > ?
                 COUNT_STAR: 2
             SUM_TIMER_WAIT: 650358383000
             MIN_TIMER_WAIT: 292045159000
             AVG_TIMER_WAIT: 325179191000
             MAX_TIMER_WAIT: 358313224000
              SUM_LOCK_TIME: 520000000
                 SUM_ERRORS: 0
               SUM_WARNINGS: 0
          SUM_ROWS_AFFECTED: 0
              SUM_ROWS_SENT: 520048
          SUM_ROWS_EXAMINED: 520048
...
          SUM_NO_INDEX_USED: 0
     SUM_NO_GOOD_INDEX_USED: 0
                 FIRST_SEEN: 2016-03-24 14:25:32
                  LAST_SEEN: 2016-03-24 14:25:55
```

针对即时查询、诊断问题的场景，我们还可以使用 `sys schema`，sys schema 提供了一种组织良好、人类易读的指标查询方式，查询起来更简单。比如我们可以用下面的方法找到最慢的 SQL。这个数据在 statements_with_runtimes_in_95th_percentile 表中。

```sql
SELECT * FROM sys.statements_with_runtimes_in_95th_percentile;
```

如果你想了解更多的例子，可以查看 [sys schema](https://github.com/mysql/mysql-sys) 的文档。

### 流量

关于流量，我们最耳熟能详的是统计 `SELECT、UPDATE、DELETE、INSERT` 等语句执行的数量。如果流量太高，超过了硬件承载能力，显然是需要监控、需要扩容的。这些类型的指标在 MySQL 的全局变量中都可以拿到。我们来看下面这个例子。

```sql

show global status where Variable_name regexp 'Com_insert|Com_update|Com_delete|Com_select|Questions|Queries';
+-------------------------+-----------+
| Variable_name           | Value     |
+-------------------------+-----------+
| Com_delete              | 2091033   |
| Com_delete_multi        | 0         |
| Com_insert              | 8837007   |
| Com_insert_select       | 0         |
| Com_select              | 226099709 |
| Com_update              | 24218879  |
| Com_update_multi        | 0         |
| Empty_queries           | 25455182  |
| Qcache_queries_in_cache | 0         |
| Queries                 | 704921835 |
| Questions               | 461095549 |
| Slow_queries            | 107       |
+-------------------------+-----------+
12 rows in set (0.001 sec)
```

例子中的这些指标都是 Counter 类型，单调递增，另外 Com_ 是 Command 的前缀，即各类命令的执行次数。整体吞吐量主要是看 Questions 指标，但 Questions 很容易和它上面的 Queries 混淆。从例子里我们可以明显看出 Questions 的数量比 Queries 少。Questions 表示客户端发给 MySQL 的语句数量，而 Queries 还会包含在存储过程中执行的语句，以及 PREPARE 这种准备语句，所以监控整体吞吐一般是看 Questions。

流量方面的指标，一般我们会统计写数量（Com_insert + Com_update + Com_delete）、读数量（Com_select）、语句总量（Questions）。

### 错误

从 MySQL 中采集相关错误

```sql
show global status where Variable_name regexp 'Connection_errors_max_connections|Aborted_connects';
+-----------------------------------+--------+
| Variable_name                     | Value  |
+-----------------------------------+--------+
| Aborted_connects                  | 785546 |
| Connection_errors_max_connections | 0      |
+-----------------------------------+--------+
```

最大连接数

```sql
SHOW VARIABLES LIKE 'max_connections'; -- default 151
SET GLOBAL max_connections = 2048;

vim my.cnf
max_connections = 2048
```

```sql
SELECT schema_name
     , SUM(sum_errors) err_count
  FROM performance_schema.events_statements_summary_by_digest
 WHERE schema_name IS NOT NULL
 GROUP BY schema_name;
+--------------------+-----------+
| schema_name        | err_count |
+--------------------+-----------+
| employees          |         8 |
| performance_schema |         1 |
| sys                |         3 |
+--------------------+-----------+
```

### 饱和度

MySQL 本身也有一些指标来反映饱和度，比如刚才我们讲到的连接数，当前连接数（Threads_connected）除以最大连接数（max_connections）可以得到连接数使用率，是一个需要重点监控的饱和度指标。

另外就是 InnoDB Buffer pool 相关的指标，一个是 Buffer pool 的使用率，一个是 Buffer pool 的内存命中率。Buffer pool 是一块内存，专门用来缓存 Table、Index 相关的数据，提升查询性能。对 InnoDB 存储引擎而言，Buffer pool 是一个非常关键的设计。我们查看一下 Buffer pool 相关的指标。

```sql

MariaDB [(none)]> show global status like '%buffer%';
+---------------------------------------+--------------------------------------------------+
| Variable_name                         | Value                                            |
+---------------------------------------+--------------------------------------------------+
| Innodb_buffer_pool_dump_status        |                                                  |
| Innodb_buffer_pool_load_status        | Buffer pool(s) load completed at 220825 11:11:13 |
| Innodb_buffer_pool_resize_status      |                                                  |
| Innodb_buffer_pool_load_incomplete    | OFF                                              |
| Innodb_buffer_pool_pages_data         | 5837                                             |
| Innodb_buffer_pool_bytes_data         | 95633408                                         |
| Innodb_buffer_pool_pages_dirty        | 32                                               |
| Innodb_buffer_pool_bytes_dirty        | 524288                                           |
| Innodb_buffer_pool_pages_flushed      | 134640371                                        |
| Innodb_buffer_pool_pages_free         | 1036                                             |
| Innodb_buffer_pool_pages_misc         | 1318                                             |
| Innodb_buffer_pool_pages_total        | 8191                                             |
| Innodb_buffer_pool_read_ahead_rnd     | 0                                                |
| Innodb_buffer_pool_read_ahead         | 93316                                            |
| Innodb_buffer_pool_read_ahead_evicted | 203                                              |
| Innodb_buffer_pool_read_requests      | 8667876784                                       |
| Innodb_buffer_pool_reads              | 236654                                           |
| Innodb_buffer_pool_wait_free          | 5                                                |
| Innodb_buffer_pool_write_requests     | 533520851                                        |
+---------------------------------------+--------------------------------------------------+
19 rows in set (0.001 sec)
```

这里有 4 个指标我重点讲一下。`Innodb_buffer_pool_pages_total` 表示 InnoDB Buffer pool 的页总量，页（page）是 Buffer pool 的一个分配单位，默认的 page size 是 16KiB，可以通过 show variables like "innodb_page_size" 拿到。

`Innodb_buffer_pool_pages_free` 是剩余页数量，通过 total 和 free 可以计算出 used，用 used 除以 total 就可以得到使用率。当然，使用率高并不是说有问题，因为 InnoDB 有 LRU 缓存清理机制，只要响应得够快，高使用率也不是问题。

`Innodb_buffer_pool_read_requests` 和 `Innodb_buffer_pool_reads` 是另外两个关键指标。read_requests 表示向 Buffer pool 发起的查询总量，如果 Buffer pool 缓存了相关数据直接返回就好，如果 Buffer pool 没有相关数据，就要穿透内存去查询硬盘了。有多少请求满足不了需要去查询硬盘呢？

这就要看 Innodb_buffer_pool_reads 指标统计的数量。所以，reads 这个指标除以 read_requests 就得到了穿透比例，这个比例越高，性能越差，一般可以通过调整 Buffer pool 的大小来解决。

## 采集配置

### Categraf配置

Categraf 针对 MySQL 的采集插件配置，在 `conf/input.mysql/mysql.toml` 里。我准备了一个配置样例，你可以参考。

```toml
[[instances]]
address = "127.0.0.1:3306"
username = "root"
password = "1234"

extra_status_metrics = true
extra_innodb_metrics = true
gather_processlist_processes_by_state = false
gather_processlist_processes_by_user = false
gather_schema_size = false
gather_table_size = false
gather_system_table_size = false
gather_slave_status = true

# # timeout
# timeout_seconds = 3

# labels = { instance="n9e-dev-mysql" }
```

最关键的配置是数据库连接地址和认证信息，具体采集哪些内容由一堆开关来控制。一般我建议把 extra_status_metrics、extra_innodb_metrics、gather_slave_status 设置为 true，其他的都不太需要采集。labels 部分，我建议你加个 instance 标签，给这个数据库取一个表意性更强的名称，未来收到告警消息的时候，可以一眼知道是哪个数据库的问题。instances 部分是个数组，如果要监控多个数据库，就配置多个 instances 就可以了。

### 监控大盘

[nightinggale-dashboard](https://github.com/flashcatcloud/categraf/blob/main/inputs/mysql/dashboard-by-ident.json)

[grafana](https://grafana.com/grafana/dashboards/7362-mysql-overview/)

### 业务指标

MySQL 的指标采集，核心原理其实就是连上 MySQL 执行一些 SQL，查询性能数据。Categraf 内置了一些查询 SQL，那我们能否自定义一些 SQL，查询一些业务指标呢？比如查询一下业务系统的用户量，把用户量作为指标上报到监控系统，还是非常有价值的

这个需求我们仍然可以使用 Categraf 的 MySQL 采集插件实现，查看 mysql.toml 里的默认配置，可以看到这样一段内容。

```toml
[[instances.queries]]
mesurement = "users"
metric_fields = [ "total" ]
label_fields = [ "service" ]
field_to_append = ""
timeout = "3s"
request = '''
select 'n9e' as service, count(*) as total from n9e_v5.users
'''
```

这就是自定义 SQL 的配置，想要查询哪个数据库实例，就在对应的 [[instances]] 下面增加 [[instances.queries]] 。我们看下这几个配置参数的解释。
1. mesurement 指标类别，会作为 metric name 的前缀。
2. metric_fields 查询返回的结果，可能有多列是数值，指定哪些列作为指标上报。
3. label_fields 查询返回的结果，可能有多列是字符串，指定哪些列作为标签上报。
4. field_to_append 指定某一列的内容作为 metric name 的后缀。
5. timeout 语句执行超时时间。
6. request 查询语句，连续三个单引号，和 Python 的三个单引号语义类似，里边的内容就不用转义了。




