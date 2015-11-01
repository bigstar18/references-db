create or replace function FN_V_Order(
    p_tradePartition     number,    --交易模块（1：竞买；2：竞卖）
    p_Code               varchar2,  --标的号
    p_Price              number,    --价格
    p_amount             number,    --数量
    p_traderId           varchar2,  --交易员
    p_userID             varchar2,  --交易用户(交易商)
    p_Margin             number,    --保证金
    p_Fee                number,    --手续费
    p_orderTime          timestamp  --委托时间
) return number
/****
 * 2012-03-21 by liuyu
 * 竞价委托
 * 返回值
 *	下委托成功返回委托单号
 *	-1  异常返回
 *	-2  资金不足返回
****/
as
    v_F_Funds         number(15,2):=0;      --应冻结资金
    v_A_Funds         number(15,2);         --可用资金
    v_F_FrozenFunds   number(15,2):=0;      --冻结资金
    v_A_OrderNo       number(15,0);         --委托号
    v_orderTime       timestamp;
    v_Overdraft       number(10,2):=0;      --交易商虚拟资金
begin
        -- 获取当前数据库时间
        select systimestamp(6) into v_orderTime from dual;

        --应冻结资金
        v_F_Funds := p_Margin + p_Fee;
        --2013-10-08获取虚拟资金
        select Overdraft into v_Overdraft from v_tradeUser where userCode = p_userID;
        --计算可用资金，并锁住财务资金
        v_A_Funds := FN_F_GetRealFunds(p_userID,1);
        if(v_A_Funds + v_Overdraft < v_F_Funds) then
            rollback;
            return -2;  --资金余额不足
        end if;

        --更新冻结资金
        v_F_FrozenFunds := FN_F_UpdateFrozenFunds(p_userID,v_F_Funds,'21');
        --插入委托表，并返回委托单号
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

