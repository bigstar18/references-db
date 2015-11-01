create or replace force view v_e_firm_ranking_stat as
select b.firmid,                                                   --�����̴���
       b.name,                                                     --����������
       nvl(sum(cnt), 0) cnt,                                       --�ɽ�����
       nvl(sum(TotalQuantity), 0) TotalQuantity                    --�ɽ�����
  from (select firmid, name from m_firm) b
  left join (select n.firmid firmid,
                    count(1) cnt,
                    sum(quantity) TotalQuantity,
                    trunc(time) tradedate
               from (select quantity, time, tradeno
                       from e_trade
                      where status = '8'
                     union
                     select quantity, time, tradeno
                       from e_trade_h
                      where status = '8') m,
                    (select firmid, tradeno
                       from e_holding
                     union
                     select firmid, tradeno from e_holding_h) n
              where m.tradeno = n.tradeno
              group by n.firmid, trunc(time)) a on a.firmid = b.firmid
                                               and tradedate >=
                                                   to_date(date_view_param.get_start(),
                                                           'yyyy-MM-dd')
                                               and tradedate <=
                                                   to_date(date_view_param.get_end(),
                                                           'yyyy-MM-dd')
 group by b.firmid, b.name
;

