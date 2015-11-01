create or replace force view v_e_trade_breach_stat as
select tradedate,                            --成交日期
       sum(cnt) cnt,                         --违约笔数
       sum(quantity) quantity                --违约数量
  from
      (select trunc(time) tradedate,
           count(1) cnt,
           sum(quantity) quantity
           from e_trade where status in (1,4) group by trunc(time)
           union
        select trunc(time) tradedate,
           count(1) cnt,
           sum(quantity) quantity
           from e_trade_h where status in (1,4) group by trunc(time))
            group by tradedate
;

