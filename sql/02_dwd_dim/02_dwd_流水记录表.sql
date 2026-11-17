-- 流水记录表：ods.ods_record → dwd.dwd_record
-- ETL：字符串去除首尾空格；可空字符串清理后为空则转换为 NULL。
-- 保留金额、状态、时间、主键及删除标记的原值，不过滤业务记录。
-- 前置条件：对应的 ODS 表已存在并持续采集数据。
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

USE CATALOG paimon_catalog;
CREATE DATABASE IF NOT EXISTS dwd;

-- 创建 Paimon 目标表
CREATE TABLE if not exists dwd.dwd_record (
    `record_id` BIGINT NOT NULL,
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (外键，关联乘客表)',
    `activity_id` BIGINT NOT NULL COMMENT '活动ID',
    `prize_id` BIGINT NOT NULL COMMENT '券ID',
    `order_id` BIGINT NOT NULL COMMENT '订单ID (外键，关联订单表)',
    `money` DECIMAL(16,2) COMMENT '券金额',
    `record_status` INT COMMENT '券状态 1 发放  2 核销',
    `is_delete` INT COMMENT ' 0-1',
    `gmt_create` TIMESTAMP NOT NULL,
    `gmt_modified` TIMESTAMP NOT NULL,
    PRIMARY KEY ( `record_id` ) NOT ENFORCED
) COMMENT '流水记录';

SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '10 s';

INSERT INTO dwd.dwd_record (
    `record_id`,
    `passenger_id`,
    `activity_id`,
    `prize_id`,
    `order_id`,
    `money`,
    `record_status`,
    `is_delete`,
    `gmt_create`,
    `gmt_modified`
)
SELECT
    `record_id` AS `record_id`,
    `passenger_id` AS `passenger_id`,
    `activity_id` AS `activity_id`,
    `prize_id` AS `prize_id`,
    `order_id` AS `order_id`,
    `money` AS `money`,
    `record_status` AS `record_status`,
    `is_delete` AS `is_delete`,
    `gmt_create` AS `gmt_create`,
    `gmt_modified` AS `gmt_modified`
FROM ods.ods_record;
