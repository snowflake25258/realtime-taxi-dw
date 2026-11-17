-- 司机表：ods.ods_driver → dim.dim_driver
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
CREATE TABLE if not exists dim.dim_driver (
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (主键)',
    `name` STRING NOT NULL COMMENT '司机姓名',
    `phone` STRING NOT NULL COMMENT '司机电话号码',
    `email` STRING NOT NULL COMMENT '司机电子邮件',
    `license_number` STRING NOT NULL COMMENT '司机驾驶执照号码',
    PRIMARY KEY ( `driver_id` ) NOT ENFORCED
) COMMENT '司机表';

SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '10 s';

INSERT INTO dim.dim_driver (
    `driver_id`,
    `name`,
    `phone`,
    `email`,
    `license_number`
)
SELECT
    `driver_id` AS `driver_id`,
    TRIM(`name`) AS `name`,
    TRIM(`phone`) AS `phone`,
    TRIM(`email`) AS `email`,
    TRIM(`license_number`) AS `license_number`
FROM ods.ods_driver;
