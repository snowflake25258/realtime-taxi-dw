-- 乘客表：ods.ods_passenger → dim.dim_passenger
-- ETL：字符串去除首尾空格；可空字符串清理后为空则转换为 NULL。
-- 保留金额、状态、时间、主键及删除标记的原值，不过滤业务记录。
-- 前置条件：对应的 ODS 表已存在并持续采集数据。
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

USE CATALOG paimon_catalog;
CREATE DATABASE IF NOT EXISTS dim;

-- 创建 Paimon 目标表
CREATE TABLE if not exists dim.dim_passenger (
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (主键)',
    `name` STRING NOT NULL COMMENT '乘客姓名',
    `phone` STRING NOT NULL COMMENT '乘客电话号码',
    `email` STRING NOT NULL COMMENT '乘客电子邮件',
    `address` STRING NOT NULL COMMENT '乘客地址',
    PRIMARY KEY ( `passenger_id` ) NOT ENFORCED
) COMMENT '乘客表';

SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '10 s';

INSERT INTO dim.dim_passenger (
    `passenger_id`,
    `name`,
    `phone`,
    `email`,
    `address`
)
SELECT
    `passenger_id` AS `passenger_id`,
    TRIM(`name`) AS `name`,
    TRIM(`phone`) AS `phone`,
    TRIM(`email`) AS `email`,
    TRIM(`address`) AS `address`
FROM ods.ods_passenger;
