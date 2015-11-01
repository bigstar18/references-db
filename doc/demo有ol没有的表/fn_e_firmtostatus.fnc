create or replace function FN_E_FirmToStatus
(
    p_FirmID   m_firm.firmid%type--交易商代码
)
return integer is
  /**
  * 修改交易商状态
  * 返回值： 1 成功
  **/
  v_cnt                number(4); --数字变量
begin

    return 1;
end;
/

