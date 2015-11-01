create or replace force view v_e_platform_revenue_stat as
select
    sum(tradefee) tradefee,         --交易手续费（业务代码为‘23001‘）
    sum(deliveryfee) deliveryfee,   --交收手续费（业务代码为‘23004‘）
    dat tradedate                   --平台收入日期
from(
    select a.dat dat,a.code shou,a.amount deliveryfee,b.code yi,b.amount tradefee from
        (select oprcode code,sum(amount) amount,trunc(createtime) dat from f_fundflow where oprcode='23004' group by oprcode,trunc(createtime)) a,
        (select oprcode code,sum(amount) amount,trunc(createtime) dat from f_fundflow where oprcode='23001' group by oprcode,trunc(createtime)) b
      where a.dat=b.dat and b.amount <> 0 and a.amount <> 0
    union
    select c.dat dat,c.code shou,c.amount deliveryfee,d.code yi,d.amount tradefee from
        (select oprcode code,sum(amount) amount,trunc(createtime) dat from f_h_fundflow where oprcode='23004' group by oprcode,trunc(createtime)) c,
        (select oprcode code,sum(amount) amount,trunc(createtime) dat from f_h_fundflow where oprcode='23001' group by oprcode,trunc(createtime)) d
      where c.dat=d.dat and d.amount <> 0 and c.amount <> 0
) where 1=1
group by dat
;

