create or replace function FN_V_Withdraw(
    p_A_OrderNo          number,             --被撤单委托单号
    p_WithdrawType       number,             --撤单类型 0：成交撤单；1：流拍撤单; 2:交易中撤单
    p_amount             number              --撤单数量
) return number
/****
 * 2012-03-21 by liuyu
 * 竞价撤单
 * 返回值
 * 1  成功
 * -1 失败
 * -2 撤单数量超过范围
****/
as
     v_FrozenMargin      number(15,2):=0;    --冻结保证金
     v_FrozenFee         number(15,2):=0;    --冻结手续费
     v_unFrozenMargin    number(15,2):=0;    --释放保证金
     v_unFrozenFee       number(15,2):=0;    --释放手续费
     v_OrderType         number(3):=3;       --委托状态（3：全部撤单；4：部分成交后撤单；5：部分撤单）
     v_Margin            number(15,2):=0;    --保证金
     v_Fee               number(15,2):=0;    --手续费
     v_userID            varchar2(32);
     v_tradePartition    number(3);          --交易板块（1：竞买；2：竞卖）
     v_amount            number(16,6):=0;    --委托数量
     v_validAmount       number(16,6):=0;    --有效成交数量
     v_orderTime         timestamp;
     v_F_FrozenFunds     number(15,2):=0;

begin
    -- 获取当前数据库时间
    select systimestamp(6) into v_orderTime from dual;
    --获取被撤单信息
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

    if(p_WithdrawType=0) then --成交撤单
         v_Margin := v_FrozenMargin - v_unFrozenMargin;
         v_Fee := v_FrozenFee - v_unFrozenFee;
         if(p_amount < v_validAmount) then
             v_OrderType := 4; --部分成交后撤单
         elsif(p_amount = v_validAmount) then
             v_OrderType := 3;--全部撤单
         end if;
    elsif(p_WithdrawType=1) then --流拍撤单
         v_Margin := v_FrozenMargin;
         v_Fee := v_FrozenFee;
         v_OrderType := 3;--全部撤单
    elsif(p_WithdrawType=2) then --委托撤单
         if(p_amount < v_validAmount) then--部分撤单
             v_Margin := p_amount/v_amount*v_FrozenMargin;
             v_Fee := p_amount/v_amount*v_FrozenFee;
             v_OrderType := 5;--部分撤单
         elsif(p_amount = v_validAmount) then--全部撤单
             v_Margin := v_FrozenMargin - v_unFrozenMargin;
             v_Fee := v_FrozenFee - v_unFrozenFee;
             v_OrderType := 3;--全部撤单
         else
             return -2;
         end if;
    end if;

    --更新委托表
    update v_curSubmit set modifytime = v_orderTime,
                           OrderType = v_OrderType,
                           unFrozenMargin = unFrozenMargin + v_Margin,
                           unFrozenFee = unFrozenFee + v_Fee,
                           validAmount = validAmount - p_amount,
                           WithdrawType = p_WithdrawType
    where ID = p_A_OrderNo;
    --更新冻结资金
    v_F_FrozenFunds := FN_F_UpdateFrozenFunds(v_userID,-v_Margin-v_Fee,'21');

    return 1;
exception
    when others then
    rollback;
    return -1;
end;
/

