create or replace function FN_V_Order(
    p_tradePartition     number,    --����ģ�飨1������2��������
    p_Code               varchar2,  --��ĺ�
    p_Price              number,    --�۸�
    p_amount             number,    --����
    p_traderId           varchar2,  --����Ա
    p_userID             varchar2,  --�����û�(������)
    p_Margin             number,    --��֤��
    p_Fee                number,    --������
    p_orderTime          timestamp  --ί��ʱ��
) return number
/****
 * 2012-03-21 by liuyu
 * ����ί��
 * ����ֵ
 *	��ί�гɹ�����ί�е���
 *	-1  �쳣����
 *	-2  �ʽ��㷵��
****/
as
    v_F_Funds         number(15,2):=0;      --Ӧ�����ʽ�
    v_A_Funds         number(15,2);         --�����ʽ�
    v_F_FrozenFunds   number(15,2):=0;      --�����ʽ�
    v_A_OrderNo       number(15,0);         --ί�к�
    v_orderTime       timestamp;
    v_Overdraft       number(10,2):=0;      --�����������ʽ�
begin
        -- ��ȡ��ǰ���ݿ�ʱ��
        select systimestamp(6) into v_orderTime from dual;

        --Ӧ�����ʽ�
        v_F_Funds := p_Margin + p_Fee;
        --2013-10-08��ȡ�����ʽ�
        select Overdraft into v_Overdraft from v_tradeUser where userCode = p_userID;
        --��������ʽ𣬲���ס�����ʽ�
        v_A_Funds := FN_F_GetRealFunds(p_userID,1);
        if(v_A_Funds + v_Overdraft < v_F_Funds) then
            rollback;
            return -2;  --�ʽ�����
        end if;

        --���¶����ʽ�
        v_F_FrozenFunds := FN_F_UpdateFrozenFunds(p_userID,v_F_Funds,'21');
        --����ί�б�������ί�е���
        select SP_V_CURSUBMIT.nextval into v_A_OrderNo from dual;
        insert into v_curSubmit
          (ID,          tradePartition,   Code,   Price,   amount,   traderId,   userID,   submitTime,  OrderType, validAmount, modifytime,  FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType)
        values
          (v_A_OrderNo, p_tradePartition, p_Code, p_Price, p_amount, p_traderId, p_userID, p_orderTime, 0,         p_amount,    v_orderTime, p_Margin,     p_Fee,     0,              0,           null);

        /*if(p_tradePartition=1) then
            update v_tradeUser set TradeQty = TradeQty + p_amount where userCode = p_userID;
        end if;

        if(p_withOrderNo > 0) then
            update v_curSubmit set modifytime = v_orderTime,ToItsType = 2 where ID = p_withOrderNo;
        end if;*/

        return v_A_OrderNo;
exception
    when others then
        rollback;
        return -1;
end;
/

