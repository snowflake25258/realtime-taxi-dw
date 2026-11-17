-- 创建paimon catalog
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

-- 切换catalog
USE CATALOG paimon_catalog;

-- 1、创建flinkcdc source表
CREATE TEMPORARY TABLE ods.order_cdc (
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
) WITH (
  'connector' = 'mysql-cdc', -- 只能用于读取数据
  'hostname' = 'master',
  'port' = '3306',
  'username' = 'root',
  'password' = '123456',
  'database-name' = 'trip',
  'table-name' = 'order'
);

-- 创建paimon表
CREATE TABLE if not exists ods.ods_order (
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

-- 设置checkpoint的间隔时间
SET 'execution.checkpointing.interval' = '10 s';

--通过flink cdc实时采集数据，将数据写入paimon表中
insert into ods.ods_order
select * from ods.order_cdc;
