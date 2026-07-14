# KDB Monitoring Images

该目录维护 KDB 默认监控栈使用的自有镜像。当前策略是以官方运行镜像作为上游基线，在 `kdbdeveloper/*` 下重打标并保留后续扩展入口。

## 镜像映射

| KDB 镜像 | 上游镜像 | 说明 |
|---|---|---|
| `kdbdeveloper/prometheus-operator:v0.92.0` | `quay.io/prometheus-operator/prometheus-operator:v0.92.0` | Prometheus Operator controller |
| `kdbdeveloper/prometheus-config-reloader:v0.92.0` | `quay.io/prometheus-operator/prometheus-config-reloader:v0.92.0` | Prometheus 配置热加载 sidecar |
| `kdbdeveloper/prometheus:v3.12.0` | `quay.io/prometheus/prometheus:v3.12.0` | Prometheus server |
| `kdbdeveloper/alertmanager:v0.33.0` | `quay.io/prometheus/alertmanager:v0.33.0` | Alertmanager |
| `kdbdeveloper/grafana:12.0.1` | `grafana/grafana:12.0.1` | Grafana |

## 构建

```bash
make monitoring-images
```

可单独构建：

```bash
make prometheus-operator
make prometheus-config-reloader
make prometheus
make alertmanager
make grafana
```

## 版本来源

- Prometheus Operator 使用 KDB 当前内置 bundle 版本 `v0.92.0`。
- `prometheus-config-reloader` 与 Prometheus Operator 保持同版本。
- Prometheus `v3.12.0` 与 Alertmanager `v0.33.0` 对齐 Prometheus Operator `v0.92.0` 的默认版本。
- Grafana 保持 KDB 当前默认版本 `12.0.1`。
