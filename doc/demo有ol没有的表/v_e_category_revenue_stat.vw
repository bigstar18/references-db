create or replace force view v_e_category_revenue_stat as
select c.categoryid, --商品分类好
       c.categoryname, --商品分类名称
       sum(s.xiyie) tradefee, --交易手续费
       sum(s.jiaoshou) deliveryfee, --教授手续费
       sum(s.xiyie) + sum(s.jiaoshou) sumfee --手续费总额
  from (select m.tradecode,
               sum(m.xiyie) xiyie,
               m.deliverycode,
               sum(m.jiaoshou) jiaoshou,
               m.tradeno,
               m.dat,
               n.breedid
          from (select a.oprcode tradecode,
                       a.xiyie xiyie,
                       b.oprcode deliverycode,
                       b.jiaoshou jiaoshou,
                       a.tradeno,
                       a.dat dat
                  from (select t.oprcode,
                               sum(amount) xiyie,
                               t.contractno tradeno,
                               trunc(t.createtime) dat
                          from f_fundflow t
                         where t.oprcode = '23001'
                         group by t.oprcode, trunc(t.createtime), t.contractno
                         order by trunc(t.createtime) desc) a,
                       (select t.oprcode,
                               sum(amount) jiaoshou,
                               t.contractno tradeno,
                               trunc(t.createtime) dat
                          from f_fundflow t
                         where t.oprcode = '23004'
                         group by t.oprcode, trunc(t.createtime), t.contractno
                         order by trunc(t.createtime) desc) b
                 where a.dat = b.dat
                   and a.tradeno = b.tradeno) m,
               e_trade n
         where m.tradeno = n.tradeno
           and trunc(m.dat) >=
               to_date(date_view_param.get_start(), 'yyyy-MM-dd')
           and trunc(m.dat) <=
               to_date(date_view_param.get_end(), 'yyyy-MM-dd')
         group by m.dat, m.tradeno, m.tradecode, m.deliverycode, n.breedid
        union all
        select m.tradecode,
               sum(m.xiyie) xiyie,
               m.deliverycode,
               sum(m.jiaoshou) jiaoshou,
               m.tradeno,
               m.dat,
               n.breedid
          from (select a.oprcode tradecode,
                       a.xiyie xiyie,
                       b.oprcode deliverycode,
                       b.jiaoshou jiaoshou,
                       a.tradeno,
                       a.dat dat
                  from (select t.oprcode,
                               sum(amount) xiyie,
                               t.contractno tradeno,
                               trunc(t.createtime) dat
                          from f_fundflow t
                         where t.oprcode = '23001'
                         group by t.oprcode, trunc(t.createtime), t.contractno
                         order by trunc(t.createtime) desc) a,
                       (select t.oprcode,
                               sum(amount) jiaoshou,
                               t.contractno tradeno,
                               trunc(t.createtime) dat
                          from f_fundflow t
                         where t.oprcode = '23004'
                         group by t.oprcode, trunc(t.createtime), t.contractno
                         order by trunc(t.createtime) desc) b
                 where a.dat = b.dat
                   and a.tradeno = b.tradeno) m,
               e_trade_h n
         where m.tradeno = n.tradeno
           and trunc(m.dat) >=
               to_date(date_view_param.get_start(), 'yyyy-MM-dd')
           and trunc(m.dat) <=
               to_date(date_view_param.get_end(), 'yyyy-MM-dd')
         group by m.dat, m.tradeno, m.tradecode, m.deliverycode, n.breedid
        union all
        select m.tradecode,
               sum(m.xiyie) xiyie,
               m.deliverycode,
               sum(m.jiaoshou) jiaoshou,
               m.tradeno,
               m.dat,
               n.breedid
          from (select a.oprcode tradecode,
                       a.xiyie xiyie,
                       b.oprcode deliverycode,
                       b.jiaoshou jiaoshou,
                       a.tradeno,
                       a.dat dat
                  from (select t.oprcode,
                               sum(amount) xiyie,
                               t.contractno tradeno,
                               trunc(t.createtime) dat
                          from f_h_fundflow t
                         where t.oprcode = '23001'
                         group by t.oprcode, trunc(t.createtime), t.contractno
                         order by trunc(t.createtime) desc) a,
                       (select t.oprcode,
                               sum(amount) jiaoshou,
                               t.contractno tradeno,
                               trunc(t.createtime) dat
                          from f_h_fundflow t
                         where t.oprcode = '23004'
                         group by t.oprcode, trunc(t.createtime), t.contractno
                         order by trunc(t.createtime) desc) b
                 where a.dat = b.dat
                   and a.tradeno = b.tradeno) m,
               e_trade n
         where m.tradeno = n.tradeno
           and trunc(m.dat) >=
               to_date(date_view_param.get_start(), 'yyyy-MM-dd')
           and trunc(m.dat) <=
               to_date(date_view_param.get_end(), 'yyyy-MM-dd')
         group by m.dat, m.tradeno, m.tradecode, m.deliverycode, n.breedid
        union all
        select m.tradecode,
               sum(m.xiyie) xiyie,
               m.deliverycode,
               sum(m.jiaoshou) jiaoshou,
               m.tradeno,
               m.dat,
               n.breedid
          from (select a.oprcode tradecode,
                       a.xiyie xiyie,
                       b.oprcode deliverycode,
                       b.jiaoshou jiaoshou,
                       a.tradeno,
                       a.dat dat
                  from (select t.oprcode,
                               sum(amount) xiyie,
                               t.contractno tradeno,
                               trunc(t.createtime) dat
                          from f_h_fundflow t
                         where t.oprcode = '23001'
                         group by t.oprcode, trunc(t.createtime), t.contractno
                         order by trunc(t.createtime) desc) a,
                       (select t.oprcode,
                               sum(amount) jiaoshou,
                               t.contractno tradeno,
                               trunc(t.createtime) dat
                          from f_h_fundflow t
                         where t.oprcode = '23004'
                         group by t.oprcode, trunc(t.createtime), t.contractno
                         order by trunc(t.createtime) desc) b
                 where a.dat = b.dat
                   and a.tradeno = b.tradeno) m,
               e_trade_h n
         where m.tradeno = n.tradeno
           and trunc(m.dat) >=
               to_date(date_view_param.get_start(), 'yyyy-MM-dd')
           and trunc(m.dat) <=
               to_date(date_view_param.get_end(), 'yyyy-MM-dd')
         group by m.dat, m.tradeno, m.tradecode, m.deliverycode, n.breedid) s, m_breed g, m_category c
 where s.breedid = g.breedid
   and g.status <> 2
   and g.categoryid = c.categoryid
   and c.status <> 2
   and c.categoryid <> -1
   and c.type = 'leaf'
   and c.belongmodule like '%23%'
 group by c.categoryid, c.categoryname
;

