create or replace force view v_e_breed_trade_amount_stat as
select b.breedid, --品名ID
       b.breedname, --品名
       sum(a.tradeamount) tradeamount --成交额
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
       m_breed b
 where a.breedid = b.breedid
   and b.status <> 2
   and belongmodule like '%23%'
 group by b.breedid, b.breedname
;

