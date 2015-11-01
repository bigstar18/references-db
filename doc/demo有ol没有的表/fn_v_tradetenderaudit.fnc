create or replace function FN_V_TradeTenderAudit(p_Code varchar2) return number
/****
 * 2013-12-16 by liuyu
 * �б�ɽ�ȷ��
 * ����ֵ
 * 1  �ɹ�
 * -1 ʧ��
 * -2 ȷ������������Ʒ����
****/
as
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
    v_c_bail      number(12,2):=0;           --Ͷ�귽��֤��
    v_m_bail      number(12,2):=0;           --�ұ귽��֤��
    v_c_poundage  number(12,2):=0;           --Ͷ�귽������
    v_m_poundage  number(12,2):=0;           --�ұ귽������
    v_F_FrozenFunds     number(15,2):=0;
    v_Withdraw    number(10);
    v_withdrawQty number(16,6):=0;           --��������
    v_A_TradeNo   number(10);
    v_orderTime       timestamp;
    v_TenderTradeConfirm  number(2);         --�б�ɽ�ȷ�ϣ�0��δȷ�ϣ�1����ȷ�ϣ�
    v_ConfirmAmount       number(16,6):=0;   --ȷ�ϳɽ���������
    v_bs_flag             number(2);         --��Ʒ��������
    v_bs_flag_c           number(2);         --Ͷ�귽��������
    v_num                 number(3);
begin
    --��ȡ��ǰ���ݿ�ʱ��
    select systimestamp(6) into v_orderTime from dual;

    --1. ��֤�ñ���Ƿ��Ѿ�ȷ�ϳɽ�������ñ���Ѿ�ȷ�ϳɽ���ֱ����������
    select TenderTradeConfirm into v_TenderTradeConfirm from v_commodity where Code = p_Code;
    if(v_TenderTradeConfirm=1) then
        return 1;
    end if;

    --��ȡ��Ʒ��Ϣ
    select commodityID,   Amount,   beginPrice,   alertPrice,   userID,   bs_flag
      into v_commodityID, v_Amount, v_beginPrice, v_alertPrice, v_userID, v_bs_flag
    from v_commodity where Code = p_Code;

    --2. ��֤��Ʒ�����Ƿ�����ɽ�������������ֱ���˳�
    select nvl(sum(ConfirmAmount),0) into v_ConfirmAmount from v_curSubmitTenderPlan where code = p_Code;
    if(v_ConfirmAmount > v_Amount) then
         return -2;
    end if;

    --��ȡ�������׽�
    select count(*) into v_num from v_curCommodity where Code = p_Code;
    if(v_num = 1) then
        select section into v_section from v_curCommodity where Code = p_Code;
    else
        select max(nvl(section,0)) into v_section from v_hisCommodity where Code = p_Code;
    end if;
    --select section into v_section from (select section from v_curCommodity where Code = p_Code union select section from v_hisCommodity where Code = p_Code);

    --3. �ͷŹҵ��������ʽ�ɾ���ҵ������¼
    select FrozenMargin,FrozenFee into v_bailSum,v_poundageSum from V_FundFrozen where Code = p_Code;
    v_F_FrozenFunds := FN_F_UpdateFrozenFunds(v_userID,-v_bailSum-v_poundageSum,'21');
    delete V_FundFrozen where Code = p_Code;

    --������Ʒ��������ȷ��ί����������
    if(v_bs_flag=1) then
       v_bs_flag_c := 2;
    else
       v_bs_flag_c := 1;
    end if;

    --4. ���ռ۸����ȡ��������ȡ�ʱ�����ȵ�˳������(���˲����ϼ۸������ί��)
    for trade in (select ID,Price,amount,ConfirmAmount,validAmount,userID,FrozenMargin,FrozenFee,unFrozenMargin,unFrozenFee from v_curSubmitTenderPlan where Code = p_Code)
        loop
            if(trade.ConfirmAmount<trade.amount) then --���ֳɽ�
                v_tradeFlag := 2;
                --v_Qty := trade.ConfirmAmount;   --�ɽ�����
                v_withdrawQty := trade.amount - trade.ConfirmAmount;
            else         --ȫ���ɽ�
                --v_Qty := trade.amount;
                v_tradeFlag := 1;
            end if;

            --�ɽ�����
            v_Qty := trade.ConfirmAmount;

            --����Ͷ�귽��֤���������
            if(trade.ConfirmAmount<trade.amount) then
                v_c_bail :=  FN_V_ComputeMargin(p_Code,v_bs_flag_c,v_Qty,trade.Price,trade.userID);
                v_c_poundage := FN_V_ComputeFee(p_Code,v_bs_flag_c,v_Qty,trade.Price,trade.userID);
            else
                v_c_bail :=  trade.FrozenMargin - trade.unFrozenMargin;
                v_c_poundage := trade.FrozenFee - trade.unFrozenFee;
            end if;

            --����ҵ�����֤��������
            v_m_bail :=  FN_V_ComputeMargin(p_Code,v_bs_flag,v_Qty,trade.Price,v_userID);
            v_m_poundage := FN_V_ComputeFee(p_Code,v_bs_flag,v_Qty,trade.Price,v_userID);

            if(v_bs_flag=1) then --����ұ귽Ϊ��
                v_b_bail := v_m_bail;
                v_s_bail := v_c_bail;
                v_b_poundage := v_m_poundage;
                v_s_poundage := v_c_poundage;
            else
                v_b_bail := v_c_bail;
                v_s_bail := v_m_bail;
                v_b_poundage := v_c_poundage;
                v_s_poundage := v_m_poundage;
            end if;

            --��ȡ�ɽ���
            select SP_V_BARGAIN.nextval into v_A_TradeNo from dual;
            --д�ɽ�
            insert into v_bargain
               (contractID,  tradePartition, submitID, Code,   commodityID,   Price,       Amount, userID,       TradeTime, Section,   b_bail,   s_bail,   b_poundage,   s_poundage)
            values
               (v_A_TradeNo, 3,              trade.ID, p_Code, v_commodityID, trade.Price, v_Qty,  trade.userID, sysdate,   v_section, v_b_bail, v_s_bail, v_b_poundage, v_s_poundage);

            --��ί��(��ǰ�����ʷ���п���������)
            --1�� ��ǰ��
            update v_curSubmit set OrderType=v_tradeFlag,
                                   modifytime=v_orderTime,
                                   unFrozenMargin=unFrozenMargin+v_s_bail,
                                   unFrozenFee=unFrozenFee+v_s_poundage
                               where id = trade.ID;
            --2�� ��ʷ��
            update v_hisSubmit set OrderType=v_tradeFlag,
                                   modifytime=v_orderTime,
                                   unFrozenMargin=unFrozenMargin+v_s_bail,
                                   unFrozenFee=unFrozenFee+v_s_poundage
                               where id = trade.ID;

            --�ͷ����������ʽ�
            v_F_FrozenFunds := FN_F_UpdateFrozenFunds(trade.userID,-v_c_bail-v_c_poundage,'21');
            --��˫����֤�������ѣ�д��ˮ��
            --�ҵ���
            v_Balance := FN_F_UpdateFundsFull(v_userID,'21002',v_m_bail,v_A_TradeNo,v_commodityID,null,null);
            v_Balance := FN_F_UpdateFundsFull(v_userID,'21001',v_m_poundage,v_A_TradeNo,v_commodityID,null,null);
            --Ͷ�귽
            v_Balance := FN_F_UpdateFundsFull(trade.userID,'21002',v_c_bail,v_A_TradeNo,v_commodityID,null,null);
            v_Balance := FN_F_UpdateFundsFull(trade.userID,'21001',v_c_poundage,v_A_TradeNo,v_commodityID,null,null);
            --������ֳɽ���Ҫ�ɽ��󳷵�
            if(v_tradeFlag=2 and v_withdrawQty>0) then
                v_Withdraw := FN_V_Withdraw(trade.ID,0,v_withdrawQty);
            end if;

            --�ɽ���ݼ���Ʒ����
            v_Amount := v_Amount - v_Qty;
        end loop;


    --5. ��δ�б�ί�н��г���
    for otherwithdraw in (select ID,amount from v_curSubmitTender where Code = p_Code and id not in (select id from v_curSubmitTenderPlan where Code = p_Code))
        loop
            v_Balance := FN_V_Withdraw(otherwithdraw.ID,0,otherwithdraw.amount);
        end loop;

    --6. ����б�ί�б�
    delete v_curSubmitTender where Code = p_Code;

    --���µ�ǰ������Ʒ��
    --update v_curCommodity set bargainType = 1, modifyTime =sysdate where Code = p_Code;
    --7. ������Ʒ��״̬
    update v_commodity set TenderTradeConfirm = 1 where Code = p_Code;

    return 1;
exception
    when others then
    rollback;
    return -1;
end;
/

