create or replace force view v_e_breed_order_stat as
select b.breedid,                                                               --Ʒ��ID
       b.breedname,                                                             --Ʒ��
       b.bsflag bsflag,                                                         --��������
       nvl(sum(cnt), 0) cnt,                                                    --ί�б���
       nvl(sum(TotalPrice) / sum(quantity), 0) EvenPrice,                             --����
       nvl(sum(TotalPrice), 0) TotalPrice,                                      --ί�н��
       nvl(sum(quantity), 0) quantity,                                          --ί������
       nvl(sum(tradeqty), 0) tradeqty                                           --�ɽ�����
  from (select 'B' bsflag, breedid, breedname
          from m_breed where status <> 2  and belongmodule like '%23%'
        union
        select 'S' bsflag, breedid, breedname from m_breed where status <> 2 and belongmodule like '%23%') b
  left join (select n.breedid,
                    'B' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order n
              where n.bsflag = 'B'
              group by n.breedid, trunc(n.ordertime)
             union
             select n.breedid,
                    'B' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_Order_h n
              where n.bsflag = 'B'
              group by n.breedid, trunc(n.ordertime)
             union
             select n.breedid,
                    'S' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order n
              where n.bsflag = 'S'
              group by n.breedid, trunc(n.ordertime)
             union
             select n.breedid,
                    'S' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order_h n
              where n.bsflag = 'S'
              group by n.breedid, trunc(n.ordertime)) a on a.breedid =
                                                           b.breedid
                                                       and b.bsflag =
                                                           a.bsflag
                                                       and ordertime >=
                                                           to_date(date_view_param.get_start(),
                                                                   'yyyy-MM-dd')
                                                       and ordertime <=
                                                           to_date(date_view_param.get_end(),
                                                                   'yyyy-MM-dd')
 group by b.breedid, b.bsflag, b.breedname
;

