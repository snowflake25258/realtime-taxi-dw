-- 评价表：ods.ods_review → dwd.dwd_review
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
CREATE TABLE if not exists dwd.dwd_review (
    `review_id` BIGINT NOT NULL COMMENT '评价ID (主键)',
    `order_id` BIGINT NOT NULL COMMENT '订单ID (外键，关联订单表)',
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (外键，关联乘客表)',
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (外键，关联司机表)',
    `rating` INT NOT NULL COMMENT '评分',
    `comment` STRING COMMENT '评价评论',
    `timestamp` TIMESTAMP NOT NULL COMMENT '评价时间',
    PRIMARY KEY ( `review_id` ) NOT ENFORCED
) COMMENT '评价表';

SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '10 s';

INSERT INTO dwd.dwd_review (
    `review_id`,
    `order_id`,
    `passenger_id`,
    `driver_id`,
    `rating`,
    `comment`,
    `timestamp`
)
SELECT
    `review_id` AS `review_id`,
    `order_id` AS `order_id`,
    `passenger_id` AS `passenger_id`,
    `driver_id` AS `driver_id`,
    `rating` AS `rating`,
    NULLIF(TRIM(`comment`), '') AS `comment`,
    `timestamp` AS `timestamp`
FROM ods.ods_review;
