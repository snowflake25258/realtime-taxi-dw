-- 创建paimon catalog
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

-- 切换catalog
USE CATALOG paimon_catalog;

-- 1、创建flinkcdc source表
CREATE TEMPORARY TABLE ods.driver_cdc (
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (主键)',
    `name` STRING NOT NULL COMMENT '司机姓名',
    `phone` STRING NOT NULL COMMENT '司机电话号码',
    `email` STRING NOT NULL COMMENT '司机电子邮件',
    `license_number` STRING NOT NULL COMMENT '司机驾驶执照号码',
    PRIMARY KEY ( `driver_id` ) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc', -- 只能用于读取数据
  'hostname' = 'master',
  'port' = '3306',
  'username' = 'root',
  'password' = '123456',
  'database-name' = 'trip',
  'table-name' = 'driver'
);

-- 创建paimon表
CREATE TABLE if not exists ods.ods_driver (
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (主键)',
    `name` STRING NOT NULL COMMENT '司机姓名',
    `phone` STRING NOT NULL COMMENT '司机电话号码',
    `email` STRING NOT NULL COMMENT '司机电子邮件',
    `license_number` STRING NOT NULL COMMENT '司机驾驶执照号码',
    PRIMARY KEY ( `driver_id` ) NOT ENFORCED
) COMMENT '司机表';

-- 设置checkpoint的间隔时间
SET 'execution.checkpointing.interval' = '10 s';

--通过flink cdc实时采集数据，将数据写入paimon表中
insert into ods.ods_driver
select * from ods.driver_cdc;
