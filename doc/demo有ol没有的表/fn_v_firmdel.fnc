create or replace function FN_V_FirmDel(p_FirmID varchar2)
return number
 /****
  *注销交易商
  *成功返回 1
  *****/
as
     v_cnt number(5);
begin
    delete from v_tradeuser where usercode=p_FirmID;

    update v_hisbargain set userid=userid||'_D' where userid=p_FirmID;
    update v_hissubmit set userid=userid||'_D' where userid=p_FirmID;

    return 1;
end;
/

