create or replace function FN_T_OUTSTOCKCONFIRM(
p_stockId  varchar2, --ȷ���ջ��Ĳֵ�ID
p_operator varchar2 --����Ա
)
return number
/**
   *  ����Ĳֵ�����ȷ���ջ�������ж�������ֵ��������ֵ�ռ���й����ֵ������ٷֱȽ��и�β�
   *  ����ֵ
   *  1 ȷ���ջ��ɹ�
   *  0 �ֵ�����ʹ����
   * -1 δ�ҵ��˲ֵ����������Ϣ�޷�ȷ���ջ�
   * by ������ 2015-08-14
  ****/
 as
  v_tradeNo t_Settlematch.Matchid%type; --������Ա��
  v_buyTax number(15,2);--�������˰��
  v_hl_Amout number(15,2);--����ˮ
  v_sellIncome number(15,2);--�����ջ���
  v_sellIncome_Ref number(15,2);--������׼����
  v_payMent number(15,2);--ȫ��β��
  v_realpayMent number(15,2);--���ֵ�β��
  v_amount number(15,2);--���
  v_firmId_S t_Settlematch.Firmid_s%type;--���� ID
  v_firmId_B t_Settlematch.Firmid_b%type;--�� ID
  v_commodityId t_Settlematch.Commodityid%type;--��Ʒ����
  v_everyAmount number(15,2):=0;--���������Ĳֵ�����
  v_confirmAmount number(15,2);--ȷ���ջ�����Ʒ����
  v_stockTotal number(15,2):=0; --��Ʒ����
  v_received number(1); --�Ƿ��ջ�
  v_stockAmont number(15):=0;--�����ֵ�����
begin
  --�ҵ�ʱ������Ĺ��ڴ˲ֵ��Ľ�����Ժ�
  begin
    select tradeNo into v_tradeNo from (select tradeNo from Bi_tradeStock where stockid = p_stockId and status = 1 order by releasetime desc) where Rownum = 1;
  exception
    when NO_DATA_FOUND then
      return 0;
  end;

  --���Ҷ�Ӧ�Ľ��������Ϣ
  begin
    select sellincome,hl_Amount,sellincome_ref,Buytax,Firmid_s,Commodityid,Firmid_b  into
           v_sellIncome,v_hl_Amout,v_sellIncome_Ref,v_buyTax,v_firmId_S,v_commodityId,v_firmId_B from T_SETTLEMATCH where matchid = v_tradeNo for update;
  exception
    when NO_DATA_FOUND then
      return - 1;
  end;
  --��ѯ���й����ֵ�,������������вֵ�����
  for stock in (select * from BI_TRADESTOCK where tradeNo=v_tradeNo)
    loop
      --��ȷ�Ϲ����Ĳֵ��Ƿ�ȷ���ջ�
     select RECEIVED into v_received from (select RECEIVED from BI_BUSINESSRELATIONSHIP where  stockid=stock.stockId and BUYER=v_firmId_B
                 and seller=v_firmId_S order by selltime desc) where rowNum=1;
      --���û���ջ�
      if(v_received=0) then
      select quantity into v_everyAmount from BI_STOCK where stockId = stock.stockid ;
       v_stockTotal:=v_stockTotal+v_everyAmount;
       v_stockAmont:=v_stockAmont+1;
       end if;
      end loop;

      select quantity into v_confirmAmount from Bi_Stock where stockId = p_stockId;
      --����ֵ���Ϊ0
      if(v_stockTotal=0) then
      return -1;
      end if;

      --����β�� ( ������׼���� +����ˮ +˰�� - �����յ���Ǯ +˰�� )
      v_payMent:=(v_sellIncome_Ref+v_hl_Amout+v_buyTax)-(v_sellIncome+v_buyTax);
  --���ֻʣ��һ���ֵ�ûȷ���ջ����м�����Ǯ
  if(v_stockAmont=1) then
  v_realpayMent:=v_payMent;
  else
    v_realpayMent:=(v_payMent/v_stockTotal)*v_confirmAmount;
  end if;

  --��β��
  if(v_realpayMent!=0) then
    update t_Settlematch t set  t.Sellincome=t.Sellincome+v_realpayMent where t.matchId=v_tradeNo;
    --д��ˮ
    v_amount:=FN_F_UpdateFundsFull(v_firmId_S,'15009',v_realpayMent,v_tradeNo,v_commodityId,null,null);
    --д�뽻����Խ����־
    insert into t_Settlematchfundmanage(Id, Matchid, Firmid, Summaryno, Amount, Operatedate, Commodityid)
           values(seq_t_settlematchfundmanage.nextval,v_tradeNo,v_firmId_S,'15009',v_realpayMent,sysdate,v_commodityId);
    --д�뽻�������־
    insert into t_Settlematchlog(Id, Matchid, Operator, Operatelog, Updatetime)
           values(seq_t_settlematchlog.nextval,v_tradeNo,p_operator,'����ȷ���ջ�,�ֵ���:'||p_stockId||',�ջ���,���ID:'||v_tradeNo||'���:'||v_realpayMent,sysdate);
    end if;
    --���½������ʱ����䶯��
    update t_Settlematch t set t.modifier=p_operator,t.modifytime=sysdate where t.matchid=v_tradeNo;

    --���������ϵ����Ϊ���״̬
    update BI_BUSINESSRELATIONSHIP B set received=1,receiveddate=sysdate where b.selltime =
                 (select selltime from ( select selltime from BI_BUSINESSRELATIONSHIP where  stockid=p_stockId and BUYER=v_firmId_B
                 and seller=v_firmId_S order by selltime desc) where rowNum=1) and BUYER=v_firmId_B and seller=v_firmId_S and stockid=p_stockId;
      return 1;
end;
/

