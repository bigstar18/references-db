create or replace force view v_e_firm_order_stat as
select b.firmid firmid,                             --�����̴���
       b.name name,                                 --����������
       b.bsflag bsflag,                             --��������
       nvl(sum(cnt), 0) cnt,                        --ί�б���
       nvl(sum(TotalPrice) /sum(quantity), 0) EvenPrice, --����
       nvl(sum(TotalPrice), 0) TotalPrice,          --ί�н��
       nvl(sum(quantity), 0) quantity,              --ί������
       nvl(sum(tradeqty), 0) tradeqty               --�ɽ�����
  from (select 'B' bsflag, firmid, name
          from m_firm
        union
        select 'S' bsflag, firmid, name from m_firm) b
  left join (select n.firmid,
                    'B' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order n
              where n.bsflag = 'B'
              group by n.firmid, trunc(n.ordertime)
             union
             select n.firmid,
                    'B' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_Order_h n
              where n.bsflag = 'B'
              group by n.firmid, trunc(n.ordertime)
             union
             select n.firmid,
                    'S' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order n
              where n.bsflag = 'S'
              group by n.firmid, trunc(n.ordertime)
             union
             select n.firmid,
                    'S' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order_h n
              where n.bsflag = 'S'
              group by n.firmid, trunc(n.ordertime)) a on a.firmid =
                                                          b.firmid
                                                      and b.bsflag =
                                                          a.bsflag
                                                      and ordertime >=
                                                          to_date(date_view_param.get_start(),
                                                                  'yyyy-MM-dd')
                                                      and ordertime <=
                                                          to_date(date_view_param.get_end(),
                                                                  'yyyy-MM-dd')
 group by b.firmid, b.bsflag, b.name
;

