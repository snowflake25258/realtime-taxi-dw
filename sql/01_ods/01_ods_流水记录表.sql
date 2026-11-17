-- 创建paimon catalog
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

-- 切换catalog
USE CATALOG paimon_catalog;

-- 1、创建flinkcdc source表
CREATE TEMPORARY TABLE ods.record_cdc (
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
) WITH (
  'connector' = 'mysql-cdc', -- 只能用于读取数据
  'hostname' = 'master',
  'port' = '3306',
  'username' = 'root',
  'password' = '123456',
  'database-name' = 'trip',
  'table-name' = 'record'
);

-- 创建paimon表
CREATE TABLE if not exists ods.ods_record (
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

-- 设置checkpoint的间隔时间
SET 'execution.checkpointing.interval' = '10 s';

--通过flink cdc实时采集数据，将数据写入paimon表中
insert into ods.ods_record
select * from ods.record_cdc;
