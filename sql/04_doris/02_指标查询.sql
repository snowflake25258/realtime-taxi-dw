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
