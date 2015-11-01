create or replace function FN_V_Withdraw(
    p_A_OrderNo          number,             --������ί�е���
    p_WithdrawType       number,             --�������� 0���ɽ�������1�����ĳ���; 2:�����г���
    p_amount             number              --��������
) return number
/****
 * 2012-03-21 by liuyu
 * ���۳���
 * ����ֵ
 * 1  �ɹ�
 * -1 ʧ��
 * -2 ��������������Χ
****/
as
     v_FrozenMargin      number(15,2):=0;    --���ᱣ֤��
     v_FrozenFee         number(15,2):=0;    --����������
     v_unFrozenMargin    number(15,2):=0;    --�ͷű�֤��
     v_unFrozenFee       number(15,2):=0;    --�ͷ�������
     v_OrderType         number(3):=3;       --ί��״̬��3��ȫ��������4�����ֳɽ��󳷵���5�����ֳ�����
     v_Margin            number(15,2):=0;    --��֤��
     v_Fee               number(15,2):=0;    --������
     v_userID            varchar2(32);
     v_tradePartition    number(3);          --���װ�飨1������2��������
     v_amount            number(16,6):=0;    --ί������
     v_validAmount       number(16,6):=0;    --��Ч�ɽ�����
     v_orderTime         timestamp;
     v_F_FrozenFunds     number(15,2):=0;

begin
    -- ��ȡ��ǰ���ݿ�ʱ��
    select systimestamp(6) into v_orderTime from dual;
    --��ȡ��������Ϣ
    begin
        select FrozenMargin,FrozenFee,unFrozenMargin,unFrozenFee,userID,tradePartition,amount,validAmount
          into v_FrozenMargin,v_FrozenFee,v_unFrozenMargin,v_unFrozenFee,v_userID,v_tradePartition,v_amount,v_validAmount
         from v_curSubmit
        where ID = p_A_OrderNo for update;
    exception
        when NO_DATA_FOUND then
        select FrozenMargin,FrozenFee,unFrozenMargin,unFrozenFee,userID,tradePartition,amount,validAmount
          into v_FrozenMargin,v_FrozenFee,v_unFrozenMargin,v_unFrozenFee,v_userID,v_tradePartition,v_amount,v_validAmount
         from v_hisSubmit
        where ID = p_A_OrderNo;
    end;

    if(p_WithdrawType=0) then --�ɽ�����
         v_Margin := v_FrozenMargin - v_unFrozenMargin;
         v_Fee := v_FrozenFee - v_unFrozenFee;
         if(p_amount < v_validAmount) then
             v_OrderType := 4; --���ֳɽ��󳷵�
         elsif(p_amount = v_validAmount) then
             v_OrderType := 3;--ȫ������
         end if;
    elsif(p_WithdrawType=1) then --���ĳ���
         v_Margin := v_FrozenMargin;
         v_Fee := v_FrozenFee;
         v_OrderType := 3;--ȫ������
    elsif(p_WithdrawType=2) then --ί�г���
         if(p_amount < v_validAmount) then--���ֳ���
             v_Margin := p_amount/v_amount*v_FrozenMargin;
             v_Fee := p_amount/v_amount*v_FrozenFee;
             v_OrderType := 5;--���ֳ���
         elsif(p_amount = v_validAmount) then--ȫ������
             v_Margin := v_FrozenMargin - v_unFrozenMargin;
             v_Fee := v_FrozenFee - v_unFrozenFee;
             v_OrderType := 3;--ȫ������
         else
             return -2;
         end if;
    end if;

    --����ί�б�
    update v_curSubmit set modifytime = v_orderTime,
                           OrderType = v_OrderType,
                           unFrozenMargin = unFrozenMargin + v_Margin,
                           unFrozenFee = unFrozenFee + v_Fee,
                           validAmount = validAmount - p_amount,
                           WithdrawType = p_WithdrawType
    where ID = p_A_OrderNo;
    --���¶����ʽ�
    v_F_FrozenFunds := FN_F_UpdateFrozenFunds(v_userID,-v_Margin-v_Fee,'21');

    return 1;
exception
    when others then
    rollback;
    return -1;
end;
/

