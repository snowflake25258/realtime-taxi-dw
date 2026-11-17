订单状态 0 冒泡 1 呼叫 2 司机接单 3 乘客上车 4 载客 5 订单完成 6 订单支付，7 订单评价 ，8 司机取消，9 乘客取消



CREATE TABLE IF NOT EXISTS dws.dws_order_wide (
    order_id            BIGINT          NOT NULL        COMMENT '订单ID',
    passenger_id        BIGINT                          COMMENT '乘客ID',
    driver_id           BIGINT                          COMMENT '司机ID',
    city                VARCHAR(255)                    COMMENT '城市',
    start_time          DATETIME(3)                     COMMENT '开始时间',
    end_time            DATETIME(3)                     COMMENT '结束时间',
    complaint_type      VARCHAR(255)                    COMMENT '投诉类型',
    description         VARCHAR(65533)                  COMMENT '投诉描述',
    activity_name       VARCHAR(255)                    COMMENT '活动名称',
    activity_type       VARCHAR(255)                    COMMENT '活动类型',
    prize_name          VARCHAR(255)                    COMMENT '奖品名称',
    prize_type          VARCHAR(255)                    COMMENT '奖品类型',
    estimated_amount    DECIMAL(10, 2)                  COMMENT '预估金额',
    actual_amount       DECIMAL(10, 2)                  COMMENT '实际支付金额',
    trip_time           DOUBLE                          COMMENT '乘坐用时',
    rating              INT                             COMMENT '评分',
    pickup_location     VARCHAR(65533)                  COMMENT '起始地点',
    dropoff_location    VARCHAR(65533)                  COMMENT '目的地点',
    status              INT                             COMMENT '订单状态',
    passenger_name      VARCHAR(50)                     COMMENT '乘客姓名',
    passenger_phone     VARCHAR(20)                     COMMENT '乘客电话号码',
    passenger_email     VARCHAR(100)                    COMMENT '乘客电子邮件',
    passenger_address   VARCHAR(100)                    COMMENT '乘客地址',
    driver_name         VARCHAR(50)                     COMMENT '司机姓名',
    driver_phone        VARCHAR(20)                     COMMENT '司机电话号码',
    driver_email        VARCHAR(100)                    COMMENT '司机电子邮件',
    license_number      VARCHAR(50)                     COMMENT '司机驾驶执照号码'
) ENGINE=OLAP
DUPLICATE KEY(order_id)
COMMENT '订单宽表'
DISTRIBUTED BY HASH(order_id) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 1"
);



CREATE CATALOG  paimon_catalog WITH (
    'type'='paimon',
    'warehouse'='hdfs://master:9000/data/paimon'
);

USE CATALOG paimon_catalog;
CREATE DATABASE IF NOT EXISTS dws;


SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '10 s';

-- 设置状态有效期
SET 'table.exec.state.ttl' = '86400000';

CREATE TEMPORARY TABLE IF NOT EXISTS dws.dws_order_wide (
    order_id            BIGINT          COMMENT '订单ID',
    passenger_id        BIGINT          COMMENT '乘客ID',
    driver_id           BIGINT          COMMENT '司机ID',
    city                STRING          COMMENT '城市',
    start_time          TIMESTAMP(3)    COMMENT '开始时间',
    end_time            TIMESTAMP(3)    COMMENT '结束时间',
    complaint_type      STRING          COMMENT '投诉类型',
    description         STRING          COMMENT '投诉描述',
    activity_name       STRING          COMMENT '活动名称',
    activity_type       STRING          COMMENT '活动类型',
    prize_name          STRING          COMMENT '奖品名称',
    prize_type          STRING          COMMENT '奖品类型',
    estimated_amount    DECIMAL(10, 2)  COMMENT '预估金额',
    actual_amount       DECIMAL(10, 2)  COMMENT '实际支付金额',
    trip_time           DOUBLE          COMMENT '乘坐用时',
    rating              INT             COMMENT '评分',
    pickup_location     STRING          COMMENT '起始地点',
    dropoff_location    STRING          COMMENT '目的地点',
    status              INT             COMMENT '订单状态',
    passenger_name      VARCHAR(50)     COMMENT '乘客姓名',
    passenger_phone     VARCHAR(20)     COMMENT '乘客电话号码',
    passenger_email     VARCHAR(100)    COMMENT '乘客电子邮件',
    passenger_address   VARCHAR(100)    COMMENT '乘客地址',
    driver_name         VARCHAR(50)     COMMENT '司机姓名',
    driver_phone        VARCHAR(20)     COMMENT '司机电话号码',
    driver_email        VARCHAR(100)    COMMENT '司机电子邮件',
    license_number      VARCHAR(50)     COMMENT '司机驾驶执照号码',
    PRIMARY KEY (order_id) NOT ENFORCED
) WITH (
  'connector' = 'doris',
  'fenodes' = 'master:8034',
  'benodes' = 'master:8041',
  'table.identifier' = 'dws.dws_order_wide',
  'username' = 'root',
  'password' = '123456',
  'sink.label-prefix' = 'doris_label'
);


insert into dws.dws_order_wide
select 
    a.order_id
    ,a.passenger_id
    ,a.driver_id
    ,a.city
    ,a.start_time
    ,a.end_time
    ,d.complaint_type
    ,d.description
    ,h.name as activity_name
    ,h.type as activity_type
    ,g.name as prize_name
    ,g.type as prize_type
    ,a.estimated_amount
    ,a.actual_amount
    ,TIMESTAMPDIFF(SECOND,a.start_time,a.end_time)/60.0 as trip_time
    ,c.rating
    ,a.pickup_location
    ,a.dropoff_location
    ,a.status
    ,e.name as  passenger_name
    ,e.phone as  passenger_phone
    ,e.email as  passenger_email
    ,e.address as  passenger_address
    ,f.name as driver_name
    ,f.phone as driver_phone
    ,f.email as driver_email
    ,f.license_number as license_number
from 
(select *,PROCTIME() as proctime from dwd.dwd_order) as a
left join
(select *,PROCTIME() as proctime from dwd.dwd_record) as b
on a.order_id=b.order_id
left join 
dwd.dwd_review as c
on
a.order_id=c.order_id
left join
dwd.dwd_complaint as d
on
a.order_id=d.order_id
left join
dim.dim_passenger FOR SYSTEM_TIME AS OF a.proctime as e -- 流表关联维度使用lookup join
on a.passenger_id=e.passenger_id
left join 
dim.dim_driver  FOR SYSTEM_TIME AS OF a.proctime  as f -- 流表关联维度使用lookup join
on a.driver_id=f.driver_id
left join
dim.dim_prize FOR SYSTEM_TIME AS OF b.proctime as g -- 流表关联维度使用lookup join
on b.prize_id=g.prize_id
left join
dim.dim_activity FOR SYSTEM_TIME AS OF b.proctime as h -- 流表关联维度使用lookup join
on b.activity_id=h.activity_id;



-- 全平台总的冒发率
select sum(case when status>=1 then 1.0 else 0.0 end)/sum(1.0) from 
dws.dws_order_wide ;

-- 全平台最近一个小时的冒发率
select year(start_time),month(start_time),day(start_time),hour(start_time),
sum(case when status>=1 then 1.0 else 0.0 end)/sum(1.0) 
from 
dws.dws_order_wide
group by year(start_time),month(start_time),day(start_time),hour(start_time);

-- 全平台每天的冒发率
select year(start_time),month(start_time),day(start_time),
sum(case when status>=1 then 1.0 else 0.0 end)/sum(1.0) 
from 
dws.dws_order_wide
group by year(start_time),month(start_time),day(start_time)


-- 每个城市每天冒发率
select city,year(start_time),month(start_time),day(start_time),
sum(case when status>=1 then 1.0 else 0.0 end)/sum(1.0) 
from 
dws.dws_order_wide
group by city,year(start_time),month(start_time),day(start_time);