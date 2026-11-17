-- 创建paimon catalog
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

-- 切换catalog
USE CATALOG paimon_catalog;

-- 1、创建flinkcdc source表
CREATE TEMPORARY TABLE ods.passenger_cdc (
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (主键)',
    `name` STRING NOT NULL COMMENT '乘客姓名',
    `phone` STRING NOT NULL COMMENT '乘客电话号码',
    `email` STRING NOT NULL COMMENT '乘客电子邮件',
    `address` STRING NOT NULL COMMENT '乘客地址',
    PRIMARY KEY ( `passenger_id` ) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc', -- 只能用于读取数据
  'hostname' = 'master',
  'port' = '3306',
  'username' = 'root',
  'password' = '123456',
  'database-name' = 'trip',
  'table-name' = 'passenger'
);

-- 创建paimon表
CREATE TABLE if not exists ods.ods_passenger (
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (主键)',
    `name` STRING NOT NULL COMMENT '乘客姓名',
    `phone` STRING NOT NULL COMMENT '乘客电话号码',
    `email` STRING NOT NULL COMMENT '乘客电子邮件',
    `address` STRING NOT NULL COMMENT '乘客地址',
    PRIMARY KEY ( `passenger_id` ) NOT ENFORCED
) COMMENT '乘客表';

-- 设置checkpoint的间隔时间
SET 'execution.checkpointing.interval' = '10 s';

--通过flink cdc实时采集数据，将数据写入paimon表中
insert into ods.ods_passenger
select * from ods.passenger_cdc;
