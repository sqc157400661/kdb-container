# KDB MySQL Exporter Image

该目录用于构建 KDB MySQL 监控采集镜像，基于 Prometheus `mysqld_exporter`。

## 版本兼容

同一个 `mysqld_exporter` 镜像可用于 MySQL 5.7 和 MySQL 8.0。版本差异主要体现在 MySQL 服务端可采集对象上：

| 差异项 | MySQL 5.7 | MySQL 8.0 | 处理建议 |
|---|---|---|---|
| 复制命令命名 | 主要使用 `SHOW SLAVE STATUS` | 新语义为 `REPLICA`，但仍保留兼容输出 | exporter 侧继续启用复制 collector，平台指标可由 sidecar 补齐 |
| Performance Schema | 表和字段覆盖较少 | 覆盖更完整 | 高成本 `perf_schema.*` collector 按版本和性能测试后开启 |
| sys schema | 5.7+ 可用，但环境可能裁剪 | 默认更常见 | 依赖 `sys.*` 的 collector 需要额外授权 |
| InnoDB 指标 | 可用指标较少 | 可用指标更多 | 看板和告警避免强依赖单一版本独有指标 |
| 权限 | `PROCESS`、`REPLICATION CLIENT`、`SELECT` 基本够用 | 部分 collector 可能需要更细权限 | 默认最小权限，按 collector 增补授权 |

## 构建

```bash
make mysql-exporter
```

可覆盖版本：

```bash
make mysql-exporter MYSQLD_EXPORTER_VERSION=0.19.0
```

默认镜像名为 `kdbdeveloper/mysql-exporter:v0.0.1`，可通过 `MYSQLD_EXPORTER_IMAGE` 和 `MYSQLD_EXPORTER_IMAGE_TAG` 覆盖。

## 运行参数

镜像默认监听 `:9104`，支持通过环境变量生成 `/etc/mysqld_exporter/.my.cnf`：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `MYSQL_EXPORTER_USER` | `exporter` | MySQL 监控账号 |
| `MYSQL_EXPORTER_PASSWORD` | 空 | MySQL 监控账号密码 |
| `MYSQL_EXPORTER_HOST` | `127.0.0.1` | MySQL 地址 |
| `MYSQL_EXPORTER_PORT` | `3306` | MySQL 端口 |
| `MYSQL_EXPORTER_SOCKET` | 空 | 如设置则优先使用 socket |
| `MYSQLD_EXPORTER_CONFIG` | `/etc/mysqld_exporter/.my.cnf` | 自定义配置文件路径 |
| `WEB_LISTEN_ADDRESS` | `:9104` | exporter 监听地址 |
| `MYSQLD_EXPORTER_EXTRA_ARGS` | 空 | 额外 collector flags |

## 推荐账号

```sql
CREATE USER 'exporter'@'%' IDENTIFIED BY '<password>' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
```

如启用 `sys.*`、`heartbeat`、`mysql.user` 等 collector，需要按需补充权限。
