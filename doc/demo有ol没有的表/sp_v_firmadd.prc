CREATE OR REPLACE PROCEDURE SP_V_FirmAdd( P_FIRMID in VARCHAR2)
 /****
  *增加交易商
  *
  *****/
as
     v_cnt number(5);
begin
    select count(*) into v_cnt from v_tradeuser where usercode=p_firmid;
    if(v_cnt>0) then
           return;
    end if;
 --插入交易商表，默认有竞价权限、无挂单权限
 insert into v_tradeuser(usercode,isEntry,limits)
 values(P_FIRMID,0,0);
end;
/

