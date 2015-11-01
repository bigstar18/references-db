create or replace function FN_V_TradeTender(p_Code varchar2) return number
/****
 * 2013-12-16 by liuyu
 * �б�ɽ������׽ڽ���ʱ���ã�
 * ����ֵ
 * 1  �ɹ�
 * -1 ʧ��
****/
as
    v_num         number(10,0);
    v_Balance     number(15,2);
    v_Amount      number(16,6):=0;           --��Ʒ����
    v_commodityID varchar2(64);
    v_beginPrice  number(15,2):=0;           --���ļ�
    v_alertPrice  number(15,2):=0;           --������
    v_Qty         number(16,6):=0;           --�ɽ�����
    v_userID      varchar2(32);              --�����û�
    v_bs_flag     number(2);                 --��������1����2������

    type c_v_curSubmit is ref cursor;
	  v_trade c_v_curSubmit;
    v_sql varchar2(500);
    v_where varchar2(50);

    v_oradeby       varchar2(16):='';

    v_id            number(12);
    v_Price         number(12,2);
    v_orderamount   number(16,6);
    v_validAmount   number(16,6);
    v_orderuserID   varchar2(64);
    v_FrozenMargin  number(15,2):=0;
    v_FrozenFee     number(15,2):=0;
    v_unFrozenMargin  number(15,2):=0;
    v_unFrozenFee   number(15,2):=0;
begin
    --1. ��֤�ñ���Ƿ��Ѿ������ɽ�������Ѿ����ڸñ�ĵĳɽ���ֱ����������
    select count(*) into v_num from v_curSubmitTenderPlan where Code = p_Code;
    if(v_num>0) then
        return 1;
    end if;

    --2. ��ȡ��Ʒ��Ϣ
    select commodityID,   Amount,   beginPrice,   alertPrice,   userID,   bs_flag
      into v_commodityID, v_Amount, v_beginPrice, v_alertPrice, v_userID, v_bs_flag
    from v_commodity where Code = p_Code;

    --3.��ί�б���ϼ۸������ί�е��뵽�б�ί�б���
    if(v_bs_flag = 1) then
        insert into v_curSubmitTender
              (id, tradepartition, code, price, amount, userid, traderId, submittime, OrderType, validamount, modifytime, FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType)
        select id, tradepartition, code, price, amount, userid, traderID, submittime, OrderType, validamount, modifytime, FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType
          from v_cursubmit
         where code = p_Code and Price <= v_beginPrice and Price >= v_alertPrice;
    else
        insert into v_curSubmitTender
              (id, tradepartition, code, price, amount, userid, traderId, submittime, OrderType, validamount, modifytime, FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType)
        select id, tradepartition, code, price, amount, userid, traderID, submittime, OrderType, validamount, modifytime, FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType
          from v_cursubmit
         where code = p_Code and Price >= v_beginPrice and Price <= v_alertPrice;
    end if;


    --4.���ռ۸����ȡ��������ȡ�ʱ�����ȵ�˳������(���˲����ϼ۸������ί��)
    v_where := ' and Price <= '||v_beginPrice||' and Price >= '||v_alertPrice;
    if(v_bs_flag = 2) then
        v_oradeby := ' desc ';
        v_where := ' and Price >= '||v_beginPrice||' and Price <= '||v_alertPrice;
    end if;
    v_sql := 'select ID,Price,amount,validAmount,userID,FrozenMargin,FrozenFee,unFrozenMargin,unFrozenFee from v_curSubmit where Code = '''||p_Code||''' and OrderType in (0,5) '||v_where||' order by Price'||v_oradeby||',amount desc,submitTime';
    open v_trade for v_sql;
        loop
            fetch v_trade into v_id,v_Price,v_orderamount,v_validAmount,v_orderuserID,v_FrozenMargin,v_FrozenFee,v_unFrozenMargin,v_unFrozenFee;
            exit when v_trade%NOTFOUND;
                if(v_Amount>0) then
                    if(v_Amount<v_orderamount) then --���ֳɽ�
                        v_Qty := v_Amount;
                    else         --ȫ���ɽ�
                        v_Qty := v_orderamount;
                    end if;

                    --��Ĭ�ϳɽ���¼�����б�ƻ�ί�б�
                    insert into v_curSubmitTenderPlan
                          (id, tradepartition, code, price, amount, ConfirmAmount, userid, traderId, submittime, OrderType, validamount, modifytime, FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType)
                    select id, tradepartition, code, price, amount, v_Qty,         userid, traderID, submittime, OrderType, validamount, modifytime, FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType
                      from v_cursubmit
                     where id = v_id;

                    --�ɽ���ݼ���Ʒ����
                    v_Amount := v_Amount - v_Qty;
                end if;

        end loop;
        close v_trade;

    --5. �������ϼ۸������ί�н��г���
    if(v_bs_flag = 1) then
        for otherwithdraw in (select ID,amount from v_curSubmit where Code = p_Code and (Price > v_beginPrice or Price < v_alertPrice))
            loop
                v_Balance := FN_V_Withdraw(otherwithdraw.ID,0,otherwithdraw.amount);
            end loop;
    else
        for otherwithdraw in (select ID,amount from v_curSubmit where Code = p_Code and (Price > v_alertPrice or Price < v_beginPrice ))
            loop
                v_Balance := FN_V_Withdraw(otherwithdraw.ID,0,otherwithdraw.amount);
            end loop;
    end if;


    --6. ���µ�ǰ������Ʒ��
    update v_curCommodity set bargainType = 1, modifyTime =sysdate where Code = p_Code;
    --7. ������Ʒ��״̬
    update v_commodity set Status=1,TenderTradeConfirm = 0 where Code = p_Code;

    return 1;
exception
    when others then
    rollback;
    return -1;
end;
/

