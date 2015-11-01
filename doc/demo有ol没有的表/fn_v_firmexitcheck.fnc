create or replace function FN_V_FirmExitCheck(p_FirmID varchar2)
return number
as
/**
 * ���� ����������
 **/
  v_cnt number(4);
begin
  select count(*) into v_cnt from v_tradeuser v where v.usercode=p_FirmID;
  if(v_cnt=0) then
    return -1;
  end if;
  --�к�ͬδ������
  select count(*) into v_cnt from v_hisbargain where userid=p_FirmID and status!=2;
  if(v_cnt!=0) then
    return -1;
  end if;

  return 1;
end;
/

