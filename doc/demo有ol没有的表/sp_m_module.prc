create or replace procedure SP_m_module
(
    p_FirmID   varchar2 --�����̴���
) as
begin
  insert into m_tradermodule
          (MODULEID, traderid, ENABLED)
        values
          (21, p_FirmID, 'Y');
end;
/

