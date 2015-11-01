create or replace function FN_V_TradeSell(p_Code varchar2) return number
/****
 * 2013-12-16 by liuyu
 * �����ɽ�
 * ����ֵ
 * 1  �ɹ�
 * -1 ʧ��
****/
as
    v_num         number(10,0);
    v_FlowAmount  number(16,6):=0;           --��������
    v_amountSum   number(16,6):=0;           --ί������
    v_Balance     number(15,2);
    v_Amount      number(16,6):=0;           --��Ʒ����
    v_commodityID varchar2(64);
    v_beginPrice  number(15,2):=0;           --���ļ�
    v_alertPrice  number(15,2):=0;           --������
    v_Qty         number(16,6):=0;           --�ɽ�����
    v_section     number(3);                 --�������׽�
    v_tradeFlag   number(3):=1;              --�ɽ���־��1��ȫ���ɽ���2�����ֳɽ���
    v_userID      varchar2(32);              --�����û�
    v_bailSum     number(12,2):=0;           --�ҵ����ܱ�֤��
    v_poundageSum number(12,2):=0;           --�ҵ�����������
    v_b_bail      number(12,2):=0;           --�򷽱�֤��
    v_s_bail      number(12,2):=0;           --������֤��
    v_b_poundage  number(12,2):=0;           --��������
    v_s_poundage  number(12,2):=0;           --����������
    v_F_FrozenFunds     number(15,2):=0;
    v_Withdraw    number(10);
    v_withdrawQty number(16,6):=0;           --��������
    v_A_TradeNo   number(10);
    v_orderTime       timestamp;
    v_FlowAmountAlgr   number(2);            --�����������㷽ʽ��0���ٷֱȣ�1������ֵ��
    v_Status           number(3);
begin
    -- ��ȡ��ǰ���ݿ�ʱ��
    select systimestamp(6) into v_orderTime from dual;
    --1. ��֤�ñ���Ƿ��ѳɽ�������Ѿ����ڸñ�ĵĳɽ���ֱ����������
    select Status into v_Status from v_commodity where Code = p_Code;
    if(v_Status<>2) then
        return 1;
    end if;

    --��ȡ��Ʒ��Ϣ
    select commodityID,   FlowAmount,   FlowAmountAlgr,   Amount,   userID
      into v_commodityID, v_FlowAmount, v_FlowAmountAlgr, v_Amount, v_userID
    from v_commodity where Code = p_Code;
    --����ί�б�������
    select nvl(sum(amount),0) into v_amountSum from v_curSubmit where Code = p_Code;
    --��ȡ�������׽�
    select section into v_section from v_curCommodity where Code = p_Code;

    --2. �ͷŹҵ��������ʽ�ɾ���ҵ������¼
    select FrozenMargin,FrozenFee into v_bailSum,v_poundageSum from V_FundFrozen where Code = p_Code;
    v_F_FrozenFunds := FN_F_UpdateFrozenFunds(v_userID,-v_bailSum-v_poundageSum,'21');
    delete V_FundFrozen where Code = p_Code;

    --������������
    if(v_FlowAmountAlgr=1) then--���ٷֱȼ���
        v_FlowAmount := v_Amount*v_FlowAmount;
    end if;
    --3. ���ί������С���������� ������
    if(v_amountSum<v_FlowAmount) then--����
        --ѭ�����ó�������
        for withdraw in (select ID,amount from v_curSubmit where Code = p_Code)
          loop
              v_Balance := FN_V_Withdraw(withdraw.ID,1,withdraw.amount);
          end loop;
        --���µ�ǰ�����̱�
        update v_curCommodity set bargainType = 3, modifyTime = sysdate where Code = p_Code;
        --������Ʒ��״̬
        update v_commodity set Status=8 where Code = p_Code;
    else

        --4. ���ռ۸����ȡ��������ȡ�ʱ�����ȵ�˳������(�����ѳ���)
        for trade in (select ID,Price,amount,validAmount,userID,FrozenMargin,FrozenFee,unFrozenMargin,unFrozenFee from v_curSubmit where Code = p_Code and OrderType in (0,5) order by Price,amount desc,submitTime)
            loop
                if(v_Amount>0) then
                    if(v_Amount<trade.amount) then --���ֳɽ�
                        v_tradeFlag := 2;
                        v_Qty := trade.validAmount;   --�ɽ�����
                        v_withdrawQty := trade.validAmount - v_Amount;
                    else         --ȫ���ɽ�
                        v_Qty := trade.amount;
                        v_tradeFlag := 1;
                    end if;

                    --���㱣֤���������
                    if(v_Amount < trade.validAmount) then
                        v_s_bail :=  FN_V_ComputeMargin(p_Code,2,v_Qty,trade.Price,trade.userID);
                        v_s_poundage := FN_V_ComputeFee(p_Code,2,v_Qty,trade.Price,trade.userID);
                    else
                        v_s_bail :=  trade.FrozenMargin - trade.unFrozenMargin;
                        v_s_poundage := trade.FrozenFee - trade.unFrozenFee;
                    end if;

                    --�����򷽱�֤��������
                    v_b_bail :=  FN_V_ComputeMargin(p_Code,1,v_Qty,trade.Price,v_userID);
                    v_b_poundage := FN_V_ComputeFee(p_Code,1,v_Qty,trade.Price,v_userID);

                    --��ȡ�ɽ���
                    select SP_V_BARGAIN.nextval into v_A_TradeNo from dual;
                    --д�ɽ�
                    insert into v_bargain
                       (contractID,  tradePartition, submitID, Code,   commodityID,   Price,       Amount, userID,       TradeTime, Section,   b_bail,   s_bail,   b_poundage,   s_poundage)
                    values
                       (v_A_TradeNo, 2,              trade.ID, p_Code, v_commodityID, trade.Price, v_Qty,  trade.userID, sysdate,   v_section, v_b_bail, v_s_bail, v_b_poundage, v_s_poundage);

                    --��ί��
                    update v_curSubmit set OrderType=v_tradeFlag,
                                           modifytime=v_orderTime,
                                           unFrozenMargin=unFrozenMargin+v_s_bail,
                                           unFrozenFee=unFrozenFee+v_s_poundage
                                       where id = trade.ID;
                    --�ͷ����������ʽ�
                    v_F_FrozenFunds := FN_F_UpdateFrozenFunds(trade.userID,-v_s_bail-v_s_poundage,'21');
                    --��˫����֤�������ѣ�д��ˮ��
                    --��
                    v_Balance := FN_F_UpdateFundsFull(v_userID,'21002',v_b_bail,v_A_TradeNo,v_commodityID,null,null);
                    v_Balance := FN_F_UpdateFundsFull(v_userID,'21001',v_b_poundage,v_A_TradeNo,v_commodityID,null,null);
                    --����
                    v_Balance := FN_F_UpdateFundsFull(trade.userID,'21002',v_s_bail,v_A_TradeNo,v_commodityID,null,null);
                    v_Balance := FN_F_UpdateFundsFull(trade.userID,'21001',v_s_poundage,v_A_TradeNo,v_commodityID,null,null);
                    --������ֳɽ���Ҫ�ɽ��󳷵�
                    if(v_tradeFlag=2 and v_withdrawQty>0) then
                        v_Withdraw := FN_V_Withdraw(trade.ID,0,v_withdrawQty);
                    end if;

                    --�ɽ���ݼ���Ʒ����
                    v_Amount := v_Amount - v_Qty;
                else
                    --�����Գɽ����ж����ί�е���Ҫ����������
                    v_Withdraw := FN_V_Withdraw(trade.ID,0,trade.amount);
                end if;
            end loop;

        --���µ�ǰ������Ʒ��
        update v_curCommodity set bargainType = 1, modifyTime =sysdate where Code = p_Code;
        --������Ʒ��״̬
        update v_commodity set Status=1 where Code = p_Code;
    end if;
    return 1;
exception
    when others then
    rollback;
    return -1;
end;
/

