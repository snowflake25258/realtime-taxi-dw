-- 创建paimon catalog
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

-- 切换catalog
USE CATALOG paimon_catalog;

-- 1、创建flinkcdc source表
CREATE TEMPORARY TABLE ods.prize_cdc (
    `prize_id` BIGINT NOT NULL COMMENT '奖品ID',
    `cid` STRING NOT NULL COMMENT '企业ID',
    `name` STRING NOT NULL COMMENT '奖品名称',
    `type` STRING NOT NULL COMMENT '奖品类型',
    `module` INT NOT NULL COMMENT '奖品发放方式 0：智能 1手动',
    `status` INT COMMENT '奖品状态 0-停用、1-启用',
    `is_delete` INT COMMENT '是否删除 0-未删除、1-删除',
    `creator_id` STRING NOT NULL COMMENT '创建者id',
    `nick_name` STRING COMMENT '创建者名称',
    `update_user_id` STRING NOT NULL COMMENT '最后修改人id',
    `update_nick_name` STRING COMMENT '最后修改人名称',
    `gmt_create` TIMESTAMP NOT NULL COMMENT '创建时间',
    `gmt_modified` TIMESTAMP NOT NULL COMMENT '更新时间',
    PRIMARY KEY ( `prize_id` ) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc', -- 只能用于读取数据
  'hostname' = 'master',
  'port' = '3306',
  'username' = 'root',
  'password' = '123456',
  'database-name' = 'trip',
  'table-name' = 'prize'
);

-- 创建paimon表
CREATE TABLE if not exists ods.ods_prize (
    `prize_id` BIGINT NOT NULL COMMENT '奖品ID',
    `cid` STRING NOT NULL COMMENT '企业ID',
    `name` STRING NOT NULL COMMENT '奖品名称',
    `type` STRING NOT NULL COMMENT '奖品类型',
    `module` INT NOT NULL COMMENT '奖品发放方式 0：智能 1手动',
    `status` INT COMMENT '奖品状态 0-停用、1-启用',
    `is_delete` INT COMMENT '是否删除 0-未删除、1-删除',
    `creator_id` STRING NOT NULL COMMENT '创建者id',
    `nick_name` STRING COMMENT '创建者名称',
    `update_user_id` STRING NOT NULL COMMENT '最后修改人id',
    `update_nick_name` STRING COMMENT '最后修改人名称',
    `gmt_create` TIMESTAMP NOT NULL COMMENT '创建时间',
    `gmt_modified` TIMESTAMP NOT NULL COMMENT '更新时间',
    PRIMARY KEY ( `prize_id` ) NOT ENFORCED
) COMMENT '奖品配置';

-- 设置checkpoint的间隔时间
SET 'execution.checkpointing.interval' = '10 s';

--通过flink cdc实时采集数据，将数据写入paimon表中
insert into ods.ods_prize
select * from ods.prize_cdc;
