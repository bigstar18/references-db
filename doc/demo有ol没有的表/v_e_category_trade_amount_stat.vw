create or replace force view v_e_category_trade_amount_stat as
select c.categoryid,                                    --商品分类号
       c.categoryname,                                  --商品名称
       sum(a.tradeamount) tradeamount                   --成交额
  from (select sum(price * quantity) tradeamount,
               trunc(time) tradedate,
               breedid
          from e_trade
         where status = '8'
           and trunc(time) >=
               to_date(date_view_param.get_start(), 'yyyy-MM-dd')
           and trunc(time) <=
               to_date(date_view_param.get_end(), 'yyyy-MM-dd')
         group by trunc(time), breedid
        union
        select sum(price * quantity) tradeamount,
               trunc(time) tradedate,
               breedid
          from e_trade_h
         where status = '8'
           and trunc(time) >=
               to_date(date_view_param.get_start(), 'yyyy-MM-dd')
           and trunc(time) <=
               to_date(date_view_param.get_end(), 'yyyy-MM-dd')
         group by trunc(time), breedid) a,
       m_breed b,
       m_category c
 where a.breedid = b.breedid
   and b.categoryid = c.categoryid
   and b.status <> 2
   and c.status <> 2
   and c.categoryid <> -1
   and type = 'leaf'
   and c.belongmodule like '%23%'
 group by c.categoryid, c.categoryname
;

