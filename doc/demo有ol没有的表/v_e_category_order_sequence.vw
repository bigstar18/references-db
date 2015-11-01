create or replace force view v_e_category_order_sequence as
select b.categoryid,                                        --��Ʒ�����
       b.categoryname,                                      --��Ʒ��������
       nvl(sum(cnt), 0) cnt,                                --ί�б���
       nvl(sum(TotalPrice) / sum(quantity), 0) EvenPrice,   --����
       nvl(sum(TotalPrice), 0) TotalPrice,                  --ί�н��
       nvl(sum(quantity), 0) quantity,                      --ί������
       nvl(sum(tradeqty), 0) tradeqty                       --�ɽ�����
  from (select categoryid, categoryname
          from m_category
         where categoryid <> -1
           and status <> 2
           and type = 'leaf'
           and belongmodule like '%23%') b
  left join (select n.categoryid,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order n
              group by n.categoryid, trunc(n.ordertime)
             union
             select n.categoryid,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_Order_h n
              group by n.categoryid, trunc(n.ordertime)) a on a.categoryid =
                                                              b.categoryid
                                                          and ordertime > =
                                                              to_date(date_view_param.get_start(),
                                                                      'yyyy-MM-dd')
                                                          and ordertime <=
                                                              to_date(date_view_param.get_end(),
                                                                      'yyyy-MM-dd')
 group by b.categoryid, b.categoryname
;

