create or replace force view v_e_breed_trade_stat as
select b.breedid,                                                     --Ʒ��ID
       b.breedname,                                                   --Ʒ��
       nvl(sum(cnt), 0) cnt,                                          --�ɽ�����
       nvl(sum(TotalPrice) / sum(TotalQuantity), 0) EvenPrice,        --�ɽ�����
       nvl(sum(TotalPrice), 0) TotalPrice,                            --�ɽ����
       nvl(sum(TotalQuantity), 0) TotalQuantity,                      --�ɽ�����
       nvl(sum(TotalQuantity) / sum(cnt), 0) EvenQuantity             --�ɽ�����
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

