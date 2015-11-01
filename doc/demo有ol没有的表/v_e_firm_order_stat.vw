create or replace force view v_e_firm_order_stat as
select b.firmid firmid,                             --交易商代码
       b.name name,                                 --交易商名称
       b.bsflag bsflag,                             --买卖方向
       nvl(sum(cnt), 0) cnt,                        --委托笔数
       nvl(sum(TotalPrice) /sum(quantity), 0) EvenPrice, --均价
       nvl(sum(TotalPrice), 0) TotalPrice,          --委托金额
       nvl(sum(quantity), 0) quantity,              --委托数量
       nvl(sum(tradeqty), 0) tradeqty               --成交数量
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

