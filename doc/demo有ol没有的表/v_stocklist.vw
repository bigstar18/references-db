create or replace force view v_stocklist as
select t5."STOCKID",t5."BREEDID",t5.ownerfirm,t5."WAREHOUSEID",t5."QUANTITY",t5."UNIT",t5."LASTTIME",t5."CREATETIME",t5."STOCKSTATUS",
t5."LOGISTICSORDER",t5."COMPANY",t5."RECEIVED" ,t5."RECEIVEDDATE",t5.breedname,nvl(b11.stockid,0) as invoiceStatus from
(select t4."STOCKID",t4."BREEDID",t4.ownerfirm,t4."WAREHOUSEID",t4."QUANTITY",t4."UNIT",t4."LASTTIME",t4."CREATETIME",t4."STOCKSTATUS",
        t4."LOGISTICSORDER",t4."COMPANY",t4."RECEIVED" ,t4."RECEIVEDDATE",m.breedname  from
       (select distinct(t3.stockid),t3.breedid,t3.warehouseid,t3.quantity,t3.ownerfirm,t3.unit,t3.lasttime,t3.createtime,t3.stockstatus,t3.logisticsorder,t3.company,t44.received,t44.receiveddate
               from
                   (select t.stockid,t.breedid,t.ownerfirm,t.warehouseid,t.quantity,t.unit,t.lasttime,t.createtime,t.stockstatus,t2.logisticsorder,t2.company
                        from bi_stock t
                             left join bi_logistics t2 on t.stockid=t2.stockid where t.stockstatus=2 ) t3
                                  left join
                                  (select stockid,received,receiveddate,buyer from bi_businessrelationship
 where  selltime in (select selltime from ( select stockid,max(selltime) selltime from bi_businessrelationship group by stockid)))
                                   t44 on t3.stockid=t44.stockid and t3.ownerfirm=t44.buyer  ) t4
                                       left join m_breed m on t4.breedid=m.breedid) t5

                                       left join bi_invoiceinform b11 on t5.stockid=b11.stockid;

