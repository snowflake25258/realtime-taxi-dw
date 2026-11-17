-- 创建paimon catalog
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

-- 切换catalog
USE CATALOG paimon_catalog;

-- 1、创建flinkcdc source表
CREATE TEMPORARY TABLE ods.complaint_cdc (
    `complaint_id` BIGINT NOT NULL COMMENT '投诉ID (主键)',
    `order_id` BIGINT NOT NULL COMMENT '订单ID (外键，关联订单表)',
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (外键，关联乘客表)',
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (外键，关联司机表)',
    `complaint_type` STRING NOT NULL COMMENT '投诉类型',
    `description` STRING COMMENT '投诉描述',
    `status` INT COMMENT '投诉状态',
    `timestamp` TIMESTAMP NOT NULL COMMENT '投诉时间',
    PRIMARY KEY ( `complaint_id` ) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc', -- 只能用于读取数据
  'hostname' = 'master',
  'port' = '3306',
  'username' = 'root',
  'password' = '123456',
  'database-name' = 'trip',
  'table-name' = 'complaint'
);

-- 创建paimon表
CREATE TABLE if not exists ods.ods_complaint (
    `complaint_id` BIGINT NOT NULL COMMENT '投诉ID (主键)',
    `order_id` BIGINT NOT NULL COMMENT '订单ID (外键，关联订单表)',
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (外键，关联乘客表)',
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (外键，关联司机表)',
    `complaint_type` STRING NOT NULL COMMENT '投诉类型',
    `description` STRING COMMENT '投诉描述',
    `status` INT COMMENT '投诉状态',
    `timestamp` TIMESTAMP NOT NULL COMMENT '投诉时间',
    PRIMARY KEY ( `complaint_id` ) NOT ENFORCED
) COMMENT '投诉表';

-- 设置checkpoint的间隔时间
SET 'execution.checkpointing.interval' = '10 s';

--通过flink cdc实时采集数据，将数据写入paimon表中
insert into ods.ods_complaint
select * from ods.complaint_cdc;
