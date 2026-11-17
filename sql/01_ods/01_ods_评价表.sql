-- 创建paimon catalog
CREATE CATALOG paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

-- 切换catalog
USE CATALOG paimon_catalog;

-- 1、创建flinkcdc source表
CREATE TEMPORARY TABLE ods.review_cdc (
    `review_id` BIGINT NOT NULL COMMENT '评价ID (主键)',
    `order_id` BIGINT NOT NULL COMMENT '订单ID (外键，关联订单表)',
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (外键，关联乘客表)',
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (外键，关联司机表)',
    `rating` INT NOT NULL COMMENT '评分',
    `comment` STRING COMMENT '评价评论',
    `timestamp` TIMESTAMP NOT NULL COMMENT '评价时间',
    PRIMARY KEY ( `review_id` ) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc', -- 只能用于读取数据
  'hostname' = 'master',
  'port' = '3306',
  'username' = 'root',
  'password' = '123456',
  'database-name' = 'trip',
  'table-name' = 'review'
);

-- 创建paimon表
CREATE TABLE if not exists ods.ods_review (
    `review_id` BIGINT NOT NULL COMMENT '评价ID (主键)',
    `order_id` BIGINT NOT NULL COMMENT '订单ID (外键，关联订单表)',
    `passenger_id` BIGINT NOT NULL COMMENT '乘客ID (外键，关联乘客表)',
    `driver_id` BIGINT NOT NULL COMMENT '司机ID (外键，关联司机表)',
    `rating` INT NOT NULL COMMENT '评分',
    `comment` STRING COMMENT '评价评论',
    `timestamp` TIMESTAMP NOT NULL COMMENT '评价时间',
    PRIMARY KEY ( `review_id` ) NOT ENFORCED
) COMMENT '评价表';

-- 设置checkpoint的间隔时间
SET 'execution.checkpointing.interval' = '10 s';

--通过flink cdc实时采集数据，将数据写入paimon表中
insert into ods.ods_review
select * from ods.review_cdc;
