create or replace force view v_bi_invoiceinform as
select i.stockid,m.breedname,s.warehouseid,s.quantity,s.unit,i.invoicetype,
i.companyname,i.address,i.dutyparagraph,i.bank,i.bankaccount,i.name,i.phone
from  BI_Invoiceinform i,BI_stock s,m_breed m
where i.stockid=s.stockid and s.breedid=m.breedid;

