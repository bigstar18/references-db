create or replace force view v_e_breed_order_sequence as
select b.breedid,                                      --品名ID
       b.breedname,                                    --品名
       nvl(sum(cnt), 0) cnt,                           --委托笔数
       nvl(sum(TotalPrice)/sum(quantity), 0) EvenPrice,    --均价
       nvl(sum(TotalPrice), 0) TotalPrice,             --委托金额
       nvl(sum(quantity), 0) quantity,                 --委托数量
       nvl(sum(tradeqty), 0) tradeqty                  --成交数量
  from (select breedid, breedname from m_breed  where status <>2 and belongmodule like '%23%') b
  left join (select n.breedid,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order n
              group by n.breedid, trunc(n.ordertime)
             union all
             select n.breedid,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_Order_h n
              group by n.breedid, trunc(n.ordertime)) a on a.breedid =
                                                           b.breedid
                                                       and ordertime >=
                                                           to_date(date_view_param.get_start(),
                                                                   'yyyy-MM-dd')
                                                       and ordertime <=
                                                           to_date(date_view_param.get_end(),
                                                                   'yyyy-MM-dd')
 group by b.breedid, b.breedname
;

