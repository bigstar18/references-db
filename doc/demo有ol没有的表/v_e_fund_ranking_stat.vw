create or replace force view v_e_fund_ranking_stat as
select
         a.firmid,            --�����̴���
         a.margin,            --ռ�ñ�֤��
         a.goodsmoney,        --ռ�û���
         a.subscription,      --���ű��Ͻ�
         b.balance,           --���
         a.margin + a.goodsmoney + a.subscription + b.balance equity--Ȩ��
from e_funds a, f_firmfunds b
    where a.firmid = b.firmid
;

