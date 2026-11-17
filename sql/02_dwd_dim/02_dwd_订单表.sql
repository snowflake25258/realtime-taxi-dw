-- 订单表：ods.ods_order → dwd.dwd_order
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
CREATE TABLE if not exists dwd.dwd_order (
    `order_id` BIGINT NOT NULL COMMENT '订单ID (主键)',
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (外键，关联乘客表)',
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (外键，关联司机表)',
    `city` STRING COMMENT '城市',
    `pickup_location` STRING COMMENT '起始地点',
    `dropoff_location` STRING COMMENT '目的地点',
    `estimated_amount` DECIMAL(10,2) COMMENT '预估金额',
    `actual_amount` DECIMAL(10,2) COMMENT '实际支付金额',
    `status` INT COMMENT '订单状态 0 冒泡 1 呼叫 2 司机接单 3 乘客上车 4 载客 5 订单完成 6 订单支付，7 订单评价 ，8 司机取消，9 乘客取消',
    `start_time` TIMESTAMP COMMENT '开始时间',
    `end_time` TIMESTAMP COMMENT '结束时间',
    PRIMARY KEY ( `order_id` ) NOT ENFORCED
);

SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '10 s';

INSERT INTO dwd.dwd_order (
    `order_id`,
    `passenger_id`,
    `driver_id`,
    `city`,
    `pickup_location`,
    `dropoff_location`,
    `estimated_amount`,
    `actual_amount`,
    `status`,
    `start_time`,
    `end_time`
)
SELECT
    `order_id` AS `order_id`,
    `passenger_id` AS `passenger_id`,
    `driver_id` AS `driver_id`,
    NULLIF(TRIM(`city`), '') AS `city`,
    NULLIF(TRIM(`pickup_location`), '') AS `pickup_location`,
    NULLIF(TRIM(`dropoff_location`), '') AS `dropoff_location`,
    `estimated_amount` AS `estimated_amount`,
    `actual_amount` AS `actual_amount`,
    `status` AS `status`,
    `start_time` AS `start_time`,
    `end_time` AS `end_time`
FROM ods.ods_order;
