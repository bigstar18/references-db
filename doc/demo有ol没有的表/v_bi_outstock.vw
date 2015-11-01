create or replace force view v_bi_outstock as
select  t3.stockid,t3.realstockcode,t3.breedid,t3.breedname,t3.ownerfirm,t3.warehouseid,t3.quantity,t3.unit,t3.createtime,t3.lasttime,t3.company,t3.logisticsorder,
case when t3.received is null or t3.received='0' then 0
else 1 end isreceived,t3.receiveddate,nvl(i.stockid,0) as invoiceStatus
from (select   t1.stockid,t1.realstockcode,t1.breedid,t1.breedname,t1.ownerfirm,t1.warehouseid,t1.quantity,t1.unit,t1.createtime,t1.lasttime,t1.company,t1.logisticsorder,t2.received,t2.receiveddate from (
              select t.stockid,t.realstockcode,t.breedid,m.breedname,t.ownerfirm,t.warehouseid,t.quantity,t.unit,t.createtime,t.lasttime,b.company,b.logisticsorder from
                     (select stockid,realstockcode,breedid,ownerfirm,warehouseid,quantity,unit,createtime,lasttime from bi_stock o where stockstatus=2) t
                      left  join bi_logistics b on t.stockid=b.stockid
                      inner join  m_breed   m on m.breedid=t.breedid
               ) t1

left  join
(select stockid,received,receiveddate,buyer from bi_businessrelationship  where  selltime in (select selltime from ( select stockid,max(selltime) selltime from bi_businessrelationship group by stockid))) t2
on t1.stockid=t2.stockid and t1.ownerfirm=t2.buyer) t3
LEFT JOIN BI_INVOICEINFORM i ON i.STOCKID=t3.stockid;

