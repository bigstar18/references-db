create or replace force view v_e_breed_trade_type_stat as
select m.breedid,           --品名ID
       g.breedname,         --品名
       sum(xieyi) xieyi,    --协议交收合同
       sum(zizhu) zizhu     --自主交收合同
  from (select n.breedid, tradedate, sum(xieyi) xieyi, sum(zizhu) zizhu
          from (select count(tradetype) xieyi,
                       null zizhu,
                       trunc(time) tradedate,
                       t.breedid
                  from e_trade t
                 where tradetype = '0'
                 group by trunc(time), t.breedid
                union all
                select count(tradetype) xieyi,
                       null zizhu,
                       trunc(time) tradedate,
                       t.breedid
                  from e_trade_h t
                 where tradetype = '0'
                 group by trunc(time), t.breedid
                union all
                select null xieyi,
                       count(tradetype) zizhu,
                       trunc(time) tradedate,
                       t.breedid
                  from e_trade t
                 where tradetype = '1'
                 group by trunc(time), t.breedid
                union all
                select null xieyi,
                       count(tradetype) zizhu,
                       trunc(time) tradedate,
                       t.breedid
                  from e_trade_h t
                 where tradetype = '1'
                 group by trunc(time), t.breedid) n
         where trunc(n.tradedate) >=
               to_date(date_view_param.get_start(), 'yyyy-MM-dd')
           and trunc(n.tradedate) <=
               to_date(date_view_param.get_end(), 'yyyy-MM-dd')
         group by n.breedid, n.tradedate) m,
       m_breed g
 where m.breedid = g.breedid
       and g.status <> 2
       and belongmodule like '%23%'
 group by m.breedid, g.breedname
;

