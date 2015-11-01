create or replace force view v_bi_businessrelationship as
select  t."STOCKID",t."BREEDNAME",t."WAREHOUSEID",t."QUANTITY",t."UNIT",t."SELLER",t."BUYER",t."RECEIVED",t."RECEIVEDDATE",t."SELLTIME", nvl(bi.stockid,0)  as invoiceStatus
from (select b.stockid,m.breedname,s.warehouseid,s.quantity,s.unit,b.seller,b.buyer,b.received,b.receiveddate,b.selltime
from  BI_BusinessRelationship b,BI_stock s,m_breed m
where b.stockid=s.stockid and s.breedid=m.breedid)t
left join bi_invoiceinform bi on bi.stockid=t.stockid;

