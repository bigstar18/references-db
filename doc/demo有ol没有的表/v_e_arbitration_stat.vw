create or replace force view v_e_arbitration_stat as
select
       count (1) cnt,                     --�ٲ�����
       trunc(t.applytime) applydate       --�ٲ�����
from e_arbitration t
where 1=1
group by trunc(t.applytime)
;

