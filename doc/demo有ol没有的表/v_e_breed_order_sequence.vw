create or replace force view v_e_breed_order_sequence as
select b.breedid,                                      --Ʒ��ID
       b.breedname,                                    --Ʒ��
       nvl(sum(cnt), 0) cnt,                           --ί�б���
       nvl(sum(TotalPrice)/sum(quantity), 0) EvenPrice,    --����
       nvl(sum(TotalPrice), 0) TotalPrice,             --ί�н��
       nvl(sum(quantity), 0) quantity,                 --ί������
       nvl(sum(tradeqty), 0) tradeqty                  --�ɽ�����
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

