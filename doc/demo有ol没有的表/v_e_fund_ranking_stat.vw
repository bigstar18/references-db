create or replace force view v_e_fund_ranking_stat as
select
         a.firmid,            --交易商代码
         a.margin,            --占用保证金
         a.goodsmoney,        --占用货款
         a.subscription,      --诚信保障金
         b.balance,           --余额
         a.margin + a.goodsmoney + a.subscription + b.balance equity--权益
from e_funds a, f_firmfunds b
    where a.firmid = b.firmid
;

