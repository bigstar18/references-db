create or replace force view v_e_category_order_stat as
select b.categoryid,                                      --商品分类号
       b.categoryname,                                    --商品分类名称
       b.bsflag bsflag,                                   --买卖方向
       nvl(sum(cnt), 0) cnt,                              --委托笔数
       nvl(sum(TotalPrice) / sum(quantity), 0) EvenPrice, --均价
       nvl(sum(TotalPrice), 0) TotalPrice,                --委托金额
       nvl(sum(quantity), 0) quantity,                    --委托数量
       nvl(sum(tradeqty), 0) tradeqty                     --成交数量
  from (select 'B' bsflag, categoryid, categoryname
          from m_category
         where categoryid <> -1
           and status <> 2
           and type = 'leaf'
           and belongmodule like '%23%'
        union
        select 'S' bsflag, categoryid, categoryname
          from m_category
         where categoryid <> -1
         and status <> 2
         and type = 'leaf'
         and belongmodule like '%23%') b
  left join (select n.categoryid,
                    'B' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order n
              where n.bsflag = 'B'
              group by n.categoryid, trunc(n.ordertime)
             union
             select n.categoryid,
                    'B' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_Order_h n
              where n.bsflag = 'B'
              group by n.categoryid, trunc(n.ordertime)
             union
             select n.categoryid,
                    'S' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order n
              where n.bsflag = 'S'
              group by n.categoryid, trunc(n.ordertime)
             union
             select n.categoryid,
                    'S' bsflag,
                    count(*) cnt,
                    sum(price * quantity) TotalPrice,
                    sum(quantity) quantity,
                    sum(tradedqty) tradeqty,
                    trunc(n.ordertime) as ordertime
               from e_order_h n
              where n.bsflag = 'S'
              group by n.categoryid, trunc(n.ordertime)) a on a.categoryid =
                                                              b.categoryid
                                                          and b.bsflag =
                                                              a.bsflag
                                                          and ordertime >=
                                                              to_date(date_view_param.get_start(),
                                                                      'yyyy-MM-dd')
                                                          and ordertime <=
                                                              to_date(date_view_param.get_end(),
                                                                      'yyyy-MM-dd')
 group by b.categoryid, b.bsflag, b.categoryname
;

