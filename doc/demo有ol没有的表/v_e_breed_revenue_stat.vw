create or replace force view v_e_breed_revenue_stat as
select g.breedid,                               --品名ID
       g.breedname,                             --品名
       sum(s.xiyie) tradefee,                   --交易手续费
       sum(s.jiaoshou) deliveryfee,             --交收手续费
       sum(s.xiyie) + sum(s.jiaoshou) sumfee    --手续费总额
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
         group by m.dat, m.tradeno, m.tradecode, m.deliverycode, n.breedid) s,
       m_breed g
 where s.breedid = g.breedid
   and g.status <> 2
   and belongmodule like '%23%'
 group by g.breedid, g.breedname
;

