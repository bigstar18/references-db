create or replace procedure SP_V_FirmDel(p_FirmID varchar2) as
/**
 * 竞价删除交易商科目
 **/
begin
  delete from v_tradeuser where usercode=p_firmid;

  update v_hisbargain set userid=userid||'_D' where userid=p_FirmID;
  --update v_hismoney set firmid=firmid||'_D' where firmid=p_FirmID;
  update v_hissubmit set userid=userid||'_D' where userid=p_FirmID;
end;
/

