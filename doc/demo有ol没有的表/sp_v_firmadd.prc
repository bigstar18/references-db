CREATE OR REPLACE PROCEDURE SP_V_FirmAdd( P_FIRMID in VARCHAR2)
 /****
  *���ӽ�����
  *
  *****/
as
     v_cnt number(5);
begin
    select count(*) into v_cnt from v_tradeuser where usercode=p_firmid;
    if(v_cnt>0) then
           return;
    end if;
 --���뽻���̱�Ĭ���о���Ȩ�ޡ��޹ҵ�Ȩ��
 insert into v_tradeuser(usercode,isEntry,limits)
 values(P_FIRMID,0,0);
end;
/

