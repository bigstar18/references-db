create or replace force view v_e_arbitration_stat as
select
       count (1) cnt,                     --仲裁数量
       trunc(t.applytime) applydate       --仲裁日期
from e_arbitration t
where 1=1
group by trunc(t.applytime)
;

