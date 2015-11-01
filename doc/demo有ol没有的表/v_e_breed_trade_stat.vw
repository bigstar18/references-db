create or replace force view v_e_breed_trade_stat as
select b.breedid,                                                     --品名ID
       b.breedname,                                                   --品名
       nvl(sum(cnt), 0) cnt,                                          --成交笔数
       nvl(sum(TotalPrice) / sum(TotalQuantity), 0) EvenPrice,        --成交均价
       nvl(sum(TotalPrice), 0) TotalPrice,                            --成交金额
       nvl(sum(TotalQuantity), 0) TotalQuantity,                      --成交数量
       nvl(sum(TotalQuantity) / sum(cnt), 0) EvenQuantity             --成交均量
  from (select breedid, breedname from m_breed where status <> 2 and belongmodule like '%23%') b
  left join (select m.breedid breedid,
                    count(1) cnt,
                    sum(m.price * m.quantity) TotalPrice,
                    sum(quantity) TotalQuantity,
                    trunc(time) tradedate
               from (select breedid, price, quantity, time, tradeno
                       from e_trade
                      where status = '8'
                     union
                     select breedid, price, quantity, time, tradeno
                       from e_trade_h
                      where status = '8') m
              group by m.breedid, trunc(time)) a on a.breedid = b.breedid
                                                and tradedate >=
                                                    to_date(date_view_param.get_start(),
                                                            'yyyy-MM-dd')
                                                and tradedate <=
                                                    to_date(date_view_param.get_end(),
                                                            'yyyy-MM-dd')
 group by b.breedid, b.breedname
;

