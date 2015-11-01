create or replace function FN_E_CanOutSubscription(p_firmid varchar2, --�����̴���
                                                   p_lock   number --�Ƿ����� 1:���� 0��������
                                                   ) return number
/***
  * ��ȡ�ɳ����ű�֤��
  * ����ֵ���ɳ����ű�֤��
  ****/
 is
  v_LeastSubscription     number(15, 2); --����Ӧ�ñ����ĳ��ű��Ͻ�
  v_SumSubscription       number(15, 2); --����ȫ��ΥԼ������ű��Ͻ�
  v_CanOut                number(15, 2); --�ɳ����ű��Ͻ�
  v_UnTradecnt            number(10); --δ�ɽ���ί������
  v_OneTradeMargin        number(15, 2); --����ί��������ű��Ͻ�
  v_OrderHoldSubscription number(15, 2); --ί��ռ�õĳ��ű��Ͻ�
begin

  select a.totalOrder + b.totalSubOrder
    into v_UnTradecnt
    from -- ί��״̬ 0��δ�ɽ� 1�����ֳɽ� 2��ȫ���ɽ� 3�����¼� 11������̨����Ա���
         (select count(*) totalOrder
            from E_order o
           where o.firmid = p_firmid
             and (o.status = 0 or o.status = 1 or o.status = 11)
             and o.ispaymargin = 'N' --û��֧����֤��
             and o.pledgeflag = 0) a, --�������ֵ�
         --��۱�״̬ 0���ȴ����Ʒ��� ������û�н���֤���
         (select count(*) totalSubOrder from(
           select case
                    when o.bsflag = 'B' then
                     t.deliverymargin_s
                    else
                     t.deliverymargin_b
                  end as margin,t.frozenmargin
             from E_suborder t, E_order o
             where t.subFirmID = p_firmid and t.orderid=o.orderid and t.status = 0) where margin!=frozenmargin) b;

  --����ȫ������ΥԼ������ű�֤��
  select sum(trademargin)
    into v_SumSubscription
    from (select case
                   when r.bsflag = 'B' then
                    t.trademargin_b
                   else
                    t.trademargin_s
                 end as trademargin
            from E_reserve r, E_trade t
           where r.tradeno = t.tradeno
             and r.firmid = p_firmid
             and r.status = 0);

  select x.runtimevalue
    into v_OneTradeMargin
    from E_systemprops x
   where x.key = 'OneTradeMargin'; --����ί��������ű��Ͻ�
  --����ί��ռ�õĳ��ű��Ͻ�
  v_OrderHoldSubscription := v_UnTradecnt * v_OneTradeMargin;

  if v_SumSubscription is NULL then
    v_SumSubscription := 0;
  end if;

  if v_OrderHoldSubscription is NULL then
    v_OrderHoldSubscription := 0;
  end if;

  v_LeastSubscription := v_OrderHoldSubscription + v_SumSubscription;

  if (p_lock = 1) then
    select f.subscription - v_LeastSubscription
      into v_CanOut
      from E_funds f
     where firmid = p_firmid
       for update;
  else
    select f.subscription - v_LeastSubscription
      into v_CanOut
      from E_funds f
     where firmid = p_firmid;
  end if;

  if (v_CanOut < 0) then
    v_CanOut := 0;
  end if;

  return v_CanOut;
end;
/

