-- 创建paimon catalog
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

-- 切换catalog
USE CATALOG paimon_catalog;

-- 1、创建flinkcdc source表
CREATE TEMPORARY TABLE ods.activity_cdc (
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
) WITH (
  'connector' = 'mysql-cdc', -- 只能用于读取数据
  'hostname' = 'master',
  'port' = '3306',
  'username' = 'root',
  'password' = '123456',
  'database-name' = 'trip',
  'table-name' = 'activity'
);

-- 创建paimon表
CREATE TABLE if not exists ods.ods_activity (
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

-- 设置checkpoint的间隔时间
SET 'execution.checkpointing.interval' = '10 s';

--通过flink cdc实时采集数据，将数据写入paimon表中
insert into ods.ods_activity
select * from ods.activity_cdc;
