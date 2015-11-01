create or replace force view v_e_category_trade_stat as
select i.categoryid,                                              --��Ʒ�����
       i.categoryname,                                            --��Ʒ��������
       nvl(sum(cnt), 0) cnt,                                      --�ɽ�����
       nvl(sum(TotalPrice) / sum(TotalQuantity), 0) EvenPrice,    --�ɽ�����
       nvl(sum(TotalPrice), 0) TotalPrice,                        --�ɽ����
       nvl(sum(TotalQuantity), 0) TotalQuantity,                  --�ɽ�����
       nvl(sum(TotalQuantity) / sum(cnt), 0) EvenQuantity         --�ɽ�����
  from (select x.categoryid, x.categoryname
          from m_category x
         where categoryid <> -1
           and status <> 2
           and type = 'leaf'
           and belongmodule like '%23%') i
  left join (select TotalQuantity,
                    TotalPrice,
                    cnt,
                    a.tradetime,
                    a.breedid,
                    g.categoryid
               from (select sum(t.quantity) TotalQuantity,
                            sum(t.price * t.quantity) TotalPrice,
                            count(1) cnt,
                            trunc(tradetime) tradetime,
                            breedid
                       from (select price,
                                    quantity,
                                    trunc(time) tradetime,
                                    tradeno,
                                    breedid
                               from e_trade
                              where status = '8'
                             union
                             select price,
                                    quantity,
                                    trunc(time) tradetime,
                                    tradeno,
                                    breedid
                               from e_trade_h
                              where status = '8') t
                      group by t.breedid, trunc(tradetime)) a,
                    m_breed g
              where a.breedid = g.breedid
                and g.status <> 2) u on i.categoryid = u.categoryid
                                    and tradetime >=
                                        to_date(date_view_param.get_start(),
                                                'yyyy-MM-dd')
                                    and tradetime <=
                                        to_date(date_view_param.get_end(),
                                                'yyyy-MM-dd')
 group by i.categoryid, i.categoryname
;

