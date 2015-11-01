create or replace force view v_e_firm_trade_stat as
select b.firmid,                                               --交易商代码
       b.name,                                                 --交易商名称
       nvl(sum(cnt), 0) cnt,                                   --成交笔数
       nvl(sum(TotalPrice) / sum(TotalQuantity), 0) EvenPrice, --成交均价
       nvl(sum(TotalPrice), 0) TotalPrice,                     --成交金额
       nvl(sum(TotalQuantity), 0) TotalQuantity,               --成交数量
       nvl(sum(TotalQuantity) / sum(cnt), 0) EvenQuantity      --成交均量
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

