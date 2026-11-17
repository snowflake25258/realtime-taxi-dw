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
