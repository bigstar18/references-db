create or replace function FN_E_firmADD
(
    p_FirmID m_firm.firmid%type --�����̴���
)
return integer is
  /**
  * �ֻ�ϵͳ��ӽ�����
  * ����ֵ�� 1 �ɹ�
  **/
  v_cnt                number(4); --���ֱ���
begin
  select count(*) into v_cnt from E_firm where firmid = p_FirmID;
   if (v_cnt > 0) then
    --����������Ѿ��������������ý�������Ϣ
    update E_firm set firmlevel=1,createtime= sysdate  where firmid=p_FirmID;
    update E_funds set margin=0,goodsmoney= 0,transferloss=0,subscription=0  where firmid=p_FirmID;
    update E_firminfo set firmsummary=null,firmxml=null  where firmid=p_FirmID;
    update E_shop set ShopName=' ',ShopLevel= 0  where firmid=p_FirmID;
  end if;

  insert into E_firm
      (firmid, firmlevel, createtime)
  values
      (p_FirmID, 1, sysdate);
  insert into E_funds
      (firmid, margin, goodsmoney, transferloss, subscription)
  values
      (p_FirmID, 0, 0, 0, 0);
  insert into E_firminfo
      (firmid, firmsummary, firmxml)
  values
      (p_FirmID, null, null);
  insert into E_shop
      (firmid,ShopName,ShopLevel)
  values
      (p_FirmID,' ',0);

  --��������200800��Ŀ�����ڼ�¼�����̳��ű�֤��
  select count(*) into v_cnt from f_account where Code='200800'||p_FirmID;
  if(v_cnt=0)then
    insert into f_account(Code,Name,accountLevel,dCFlag)
    select '200800'||p_FirmID,name||p_FirmID,3,'C' from f_account
    where code='200800';
  end if;

  return 1;
end;
/

