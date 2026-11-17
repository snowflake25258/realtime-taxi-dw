-- 活动表：ods.ods_activity → dim.dim_activity
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
CREATE TABLE if not exists dim.dim_activity (
    `activity_id` BIGINT NOT NULL COMMENT '主键',
    `cid` STRING NOT NULL COMMENT '企业ID',
    `name` STRING NOT NULL COMMENT '活动名称',
    `type` STRING NOT NULL COMMENT '活动类型 BUBBLE：冒泡',
    `start_time` TIMESTAMP NOT NULL COMMENT '开始时间',
    `end_time` TIMESTAMP NOT NULL COMMENT '结束时间',
    `is_default` INT,
    `status` INT COMMENT '活动状态 0-草稿、1-待启用 2-暂停 3-下线 4-灰度 5-上线',
    `is_delete` INT COMMENT '是否删除 0-未删除、1-删除',
    `creator_id` STRING NOT NULL COMMENT '创建者id',
    `nick_name` STRING COMMENT '创建者名称',
    `update_user_id` STRING NOT NULL COMMENT '最后修改人id',
    `update_nick_name` STRING COMMENT '最后修改人名称',
    `gmt_create` TIMESTAMP NOT NULL COMMENT '创建时间',
    `gmt_modified` TIMESTAMP NOT NULL COMMENT '更新时间',
    PRIMARY KEY ( `activity_id` ) NOT ENFORCED
) COMMENT '营销活动';

SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '10 s';

INSERT INTO dim.dim_activity (
    `activity_id`,
    `cid`,
    `name`,
    `type`,
    `start_time`,
    `end_time`,
    `is_default`,
    `status`,
    `is_delete`,
    `creator_id`,
    `nick_name`,
    `update_user_id`,
    `update_nick_name`,
    `gmt_create`,
    `gmt_modified`
)
SELECT
    `activity_id` AS `activity_id`,
    TRIM(`cid`) AS `cid`,
    TRIM(`name`) AS `name`,
    TRIM(`type`) AS `type`,
    `start_time` AS `start_time`,
    `end_time` AS `end_time`,
    `is_default` AS `is_default`,
    `status` AS `status`,
    `is_delete` AS `is_delete`,
    TRIM(`creator_id`) AS `creator_id`,
    NULLIF(TRIM(`nick_name`), '') AS `nick_name`,
    TRIM(`update_user_id`) AS `update_user_id`,
    NULLIF(TRIM(`update_nick_name`), '') AS `update_nick_name`,
    `gmt_create` AS `gmt_create`,
    `gmt_modified` AS `gmt_modified`
FROM ods.ods_activity;
