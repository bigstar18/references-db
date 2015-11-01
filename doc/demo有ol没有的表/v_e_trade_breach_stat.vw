create or replace force view v_e_trade_breach_stat as
select tradedate,                            --�ɽ�����
       sum(cnt) cnt,                         --ΥԼ����
       sum(quantity) quantity                --ΥԼ����
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

