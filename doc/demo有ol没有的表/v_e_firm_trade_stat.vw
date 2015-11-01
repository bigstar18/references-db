create or replace force view v_e_firm_trade_stat as
select b.firmid,                                               --�����̴���
       b.name,                                                 --����������
       nvl(sum(cnt), 0) cnt,                                   --�ɽ�����
       nvl(sum(TotalPrice) / sum(TotalQuantity), 0) EvenPrice, --�ɽ�����
       nvl(sum(TotalPrice), 0) TotalPrice,                     --�ɽ����
       nvl(sum(TotalQuantity), 0) TotalQuantity,               --�ɽ�����
       nvl(sum(TotalQuantity) / sum(cnt), 0) EvenQuantity      --�ɽ�����
  from (select firmid, name from m_firm) b
  left join (select n.firmid firmid,
                    count(1) cnt,
                    sum(m.price * m.quantity) TotalPrice,
                    sum(quantity) TotalQuantity,
                    trunc(time) tradedate
               from (select price, quantity, time, tradeno
                       from e_trade
                      where status = '8'
                     union
                     select price, quantity, time, tradeno
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

