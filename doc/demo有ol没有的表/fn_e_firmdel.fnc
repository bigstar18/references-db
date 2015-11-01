create or replace function FN_E_FirmDel
(
    p_FirmID   m_firm.firmid%type--�����̴���
)
return integer is
  /**
  * ɾ��������
  * ����ֵ�� 1 �ɹ�
  **/
  v_cnt                number(4); --���ֱ���
  v_ordercount         number(4); --ί�����ֱ���
  v_tradecount         number(4); --��ͬ���ֱ���
  v_subordercount      number(4); --������ֱ���
  f_margin               number(15,2); --��֤�����
  f_goodsmoney           number(15,2); --�������
  f_transferloss         number(15,2); --ת��������
  f_subscription         number(15,2); --���ű�֤�����
  RET_ORDERERROR integer:=-230;--��δ������ί��
  RET_TRADEERROR integer:=-231;--��δ�����ĺ�ͬ
  RET_SUBORDERERROR integer:=-232;--��δ�𸴵����
  RET_MARGINERROR integer:=-233;--�����̱�֤��Ϊ0
  RET_MONEYERROR integer:=-234;--�����̻��Ϊ0
  RET_TRANERROR integer:=-235;--������ת����Ϊ0
  RET_SUBERROR integer:=-236;--�����̳��Ž�Ϊ0
begin
   --ί��������״̬����2:ȫ���ɽ�����3:���¼� ����ע��������
   select count(*) into v_ordercount from e_order o where o.firmid=p_FirmID and o.status not in(2,3);
   if(v_ordercount>0)then
   return RET_ORDERERROR;
   end if;
    --��ͬ������״̬����8:��������1:�����׶�ΥԼ ����2:ϵͳ������������4:�ɽ��׶�ΥԼ ����ע��������
   select count(*) into v_tradecount from e_trade t where (t.bfirmid=p_FirmID or t.sfirmid=p_FirmID) and t.status not in (1,2,4,8);
   if(v_tradecount>0)then
   return RET_TRADEERROR;
   end if;
   --���������״̬Ϊ0:�ȴ��� ����ע��������
   select count(*) into v_subordercount from e_suborder s where s.subfirmid=p_FirmID and s.status=0;
   if(v_subordercount>0)then
   return RET_SUBORDERERROR;
   end if;

    --�ý����̵��ʽ���Ϣ��ĳһ���ʽ�ֵ��Ϊ0 ����ע��������
   select f.margin,f.goodsmoney,f.transferloss,f.subscription into f_margin,f_goodsmoney,f_transferloss,f_subscription from e_funds f where f.firmid=p_FirmID;
   if(f_margin>0)then
     return RET_MARGINERROR;
   end if;
   if(f_goodsmoney>0)then
     return RET_MONEYERROR;
   end if;
   if(f_transferloss>0)then
     return RET_TRANERROR;
   end if;
   if(f_subscription>0)then
     return RET_SUBERROR;
   end if;
   /**
   Forѭ�������ڸý����̵�ģ����Ϣ��ɾ��ģ�����Բ�ѯ������

   for template in (select g.templateid from e_goodstemplate g where g.belongtouser=p_FirmID) loop
       delete from e_goodstemplateproperty tp where tp.templateid=template.templateid;
       end loop;
   --ɾ���ý�����ģ����Ϣ
   delete from e_goodstemplate te where te.belongtouser=p_FirmID;
    **/
   /**
   Forѭ�������ڸý����̵�Ԥ��ί����Ϣ��ɾ��Ԥ��ί�����Բ�ѯ������

   for goodsresource in (select r.resourceid from e_goodsresource r where r.firmid=p_FirmID) loop
       delete from e_goodsresourceproperty rp where rp.resourceid=goodsresource.resourceid;
       delete from e_goodsresourcepic gpic where gpic.resourceid=goodsresource.resourceid;
       end loop;
    --ɾ���ý�����Ԥ��ί����Ϣ
   delete from e_goodsresource r where r.firmid=p_FirmID;
   --ɾ�����⽻��������
   delete from e_tradefee f where f.firmid=p_FirmID;
   --ɾ�����⽻��������
   delete from e_deliveryfee f where f.firmid=p_FirmID;
   --ɾ��������Լ��֤��
   delete from e_deliverymargin f where f.firmid=p_FirmID;
   --ɾ�����⽻����Ȩ��
   delete from e_traderight f where f.firmid=p_FirmID;
   **/
   --ɾ���Ƽ�����
   delete from e_recommendshop f where f.firmid=p_FirmID;
   return 1;
end;
/

