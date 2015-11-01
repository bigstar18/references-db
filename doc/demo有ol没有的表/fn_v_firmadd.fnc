create or replace function FN_V_FirmAdd(p_FirmID varchar2)
return number
 /****
  *���ӽ�����
  *�ɹ����� 1
  *****/
as
     v_cnt number(5);
begin
     select count(*) into v_cnt from v_tradeuser where usercode=p_firmid;
     if(v_cnt>0) then
           return -1; --�������Ѵ���
     end if;
     --���뽻���̱�Ĭ���о���Ȩ�ޡ��޹ҵ�Ȩ��
     insert into v_tradeuser(usercode,isEntry,limits)
     values(P_FIRMID,0,0);

     return 1;
end;
/

