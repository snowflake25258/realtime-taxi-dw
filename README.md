# 网约车实时数仓（Flink + Paimon + Doris）

基于 Flink CDC 的网约车业务实时数仓，覆盖 **ODS → DWD/DIM → DWS → 指标查询** 全链路，
存储层用 Paimon（数据湖，计算与存储解耦），指标查询层用 Doris（宽表 + 分组聚合出指标）。

## 一、架构

```
MySQL(trip 库 8 张表)
        │  Flink CDC（binlog 实时采集）
        ▼
   Paimon 数据湖 (HDFS: /data/paimon)
   ├── ods   : 8 张原始表（ods_order / ods_record / ...）
   ├── dwd   : 4 张明细事实表（dwd_order / dwd_record / dwd_review / dwd_complaint）
   ├── dim   : 4 张维度表（dim_passenger / dim_driver / dim_activity / dim_prize）
   └── dws   : 订单宽表（8 表关联）
        │  Flink Doris Connector（Sink 直写）
        ▼
   Doris (dws.dws_order_wide)
        │  分组聚合 SQL
        ▼
   指标：冒发率（总体 / 按小时 / 按天 / 按城市）
```

开发平台：**Dinky 1.1.0**（Flink SQL 作业开发、发布、运行、运维监控）

## 二、技术栈

| 组件 | 版本 | 用途 |
|---|---|---|
| Flink | 1.18.1 | 实时计算引擎（standalone 集群，24 slot） |
| Flink CDC | 3.1.0 | 从 MySQL 实时采集 binlog |
| Paimon | 1.18-1.1 | 数据湖存储，ODS/DWD/DIM/DWS 分层落湖 |
| HDFS | Hadoop 3.1.3 | Paimon warehouse 底层存储 |
| Doris | 2.1.11 | OLAP 查询层，宽表指标计算 |
| Dinky | 1.1.0 | Flink SQL 开发平台 |
| MySQL | 8.0.34 | 业务库（trip）+ Dinky 元数据库 |
| flink-doris-connector | 1.18-26.3.0 | Flink 写 Doris |

## 三、目录结构

```
网约车实时数仓项目/
├── README.md
├── sql/
│   ├── 01_ods/          # 8 张表的 Flink CDC → Paimon ODS 采集作业
│   ├── 02_dwd_dim/      # ODS → DWD（明细事实）/ DIM（维度）ETL 作业
│   ├── 03_dws/          # 订单宽表（8 表关联 + 写 Doris）
│   └── 04_doris/        # Doris 建表 DDL + 指标查询 SQL
├── docs/
│   ├── 实时数据仓库-网约车(需求文档).docx   # 业务背景、表结构、指标体系
│   └── 宽表设计.xlsx                       # dws_order_wide 字段级设计（字段/类型/来源表）
└── data/
    └── trip.sql         # 业务库建表 + 样例数据（约 80MB，含 12 万订单）
```

## 四、数据分层说明

| 层 | 表 | 说明 |
|---|---|---|
| ODS | ods_order / ods_record / ods_review / ods_complaint / ods_passenger / ods_driver / ods_activity / ods_prize | Flink CDC 原样入湖，不做清洗 |
| DWD | dwd_order / dwd_record / dwd_review / dwd_complaint | 流式事实表，只做 TRIM、空串转 NULL 等轻量清洗 |
| DIM | dim_passenger / dim_driver / dim_activity / dim_prize | 维度表，主键唯一、数据不过期 |
| DWS | dws_order_wide | 订单为主表，4 张流表 LEFT JOIN + 4 张维表 LOOKUP JOIN |

**关联要点**

- 订单 → 流水/评价/投诉：`LEFT JOIN`（订单不一定有流水，用 inner join 会丢单）；
- 订单 → 乘客/司机/活动/奖品：`LOOKUP JOIN`（`FOR SYSTEM_TIME AS OF a.proctime`），维表数据不会过期；
- 状态有效期：`SET 'table.exec.state.ttl' = '86400000';`（1 天），防止双流 JOIN 状态无限膨胀导致 OOM；
- 乘车用时：`TIMESTAMPDIFF(SECOND, start_time, end_time) / 60.0`；
- Doris Sink：`connector = 'doris'`，`fenodes/benodes` 指向 FE/BE，`sink.label-prefix` 做事务标签。

## 五、运行结果（本机实测）

| 项 | 结果 |
|---|---|
| 业务库规模 | order 122,320 行、record 121,790 行、review 12,312 行、complaint 2,232 行、passenger 9,771 行、driver 100 行、activity 100 行、prize 232 行 |
| Flink 作业 | 17 个常驻作业（8 ODS + 8 DWD/DIM + 1 DWS 宽表），全部 RUNNING |
| 宽表行数 | Doris `dws.dws_order_wide` = 122,320 行 |
| 冒发率（全平台） | **0.8996**（已呼叫 110,035 / 总订单 122,320） |
| 按城市 | 合肥 0.9172、关岭 0.9145、秀珍 0.9140、辉市 0.9016… |
| 按小时 | 2023-07-11 21 时 0.8724 … 2023-07-12 04 时 0.8987 |

## 六、部署与运行

前置：HDFS、Flink 1.18.1（standalone，24 slot）、Dinky 1.1.0、MySQL 8、Doris 2.1.11（FE+BE）。

```bash
# 1. 导入业务库
mysql -uroot -p123456 -e "CREATE DATABASE IF NOT EXISTS trip DEFAULT CHARACTER SET utf8mb4;"
mysql -uroot -p123456 trip < data/trip.sql

# 2. 起 HDFS / Flink / Dinky
$HADOOP_HOME/sbin/start-dfs.sh
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_CLASSPATH=$(hadoop classpath | tr ':' '\n' | grep -v 'commons-cli' | paste -sd: -)   # 关键：排除 commons-cli 版本冲突
$FLINK_HOME/bin/start-cluster.sh
cd /usr/local/soft/dinky-1.1.0 && ./auto.sh start 1.18

# 3. 起 Doris（BE 启动前需 swapoff -a）
swapoff -a
$DORIS_HOME/fe/bin/start_fe.sh --daemon
$DORIS_HOME/be/bin/start_be.sh --daemon

# 4. Dinky 里按顺序执行 SQL
#    01_ods/*  → 02_dwd_dim/*  → 04_doris/01（建 Doris 表）→ 03_dws/order_wide.sql
# 5. Doris 里执行 04_doris/02_指标查询.sql
```

## 七、踩坑记录

1. **Flink 起不来**：`NoSuchMethodError: org.apache.commons.cli.Option.builder` —— Hadoop classpath 里的 commons-cli 1.2 与 Flink 的 1.5 冲突，启动时过滤掉 commons-cli。
2. **Doris BE 起不来**：`Please disable swap memory` —— `swapoff -a` 并把 `/etc/fstab` 里的 swap 注释。
3. **Dinky 无 MySQL 驱动**：`ClassNotFoundException: com.mysql.cj.jdbc.Driver` —— 把 `mysql-connector-java-8.0.29.jar` 放进 Dinky 的 `lib/`。
4. **Doris Connector 版本不匹配**：Flink 1.18 必须用 `flink-doris-connector-1.18-*`，且与 Flink 小版本对齐。
5. **任务 OOM**：`taskmanager.memory.process.size` 从 1024m 调到 4096m；多流 JOIN 一定要配 `table.exec.state.ttl`。
6. **宽表作业提交失败**：Dinky 的“运行”不接受 SELECT 结尾的脚本，指标查询要单独在 Doris 里跑。
