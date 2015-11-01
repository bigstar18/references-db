create or replace function FN_V_TradeSell(p_Code varchar2) return number
/****
 * 2013-12-16 by liuyu
 * 竞卖成交
 * 返回值
 * 1  成功
 * -1 失败
****/
as
    v_num         number(10,0);
    v_FlowAmount  number(16,6):=0;           --流拍数量
    v_amountSum   number(16,6):=0;           --委托数量
    v_Balance     number(15,2);
    v_Amount      number(16,6):=0;           --商品数量
    v_commodityID varchar2(64);
    v_beginPrice  number(15,2):=0;           --起拍价
    v_alertPrice  number(15,2):=0;           --报警价
    v_Qty         number(16,6):=0;           --成交数量
    v_section     number(3);                 --所属交易节
    v_tradeFlag   number(3):=1;              --成交标志（1：全部成交；2：部分成交）
    v_userID      varchar2(32);              --交易用户
    v_bailSum     number(12,2):=0;           --挂单方总保证金
    v_poundageSum number(12,2):=0;           --挂单方总手续费
    v_b_bail      number(12,2):=0;           --买方保证金
    v_s_bail      number(12,2):=0;           --卖方保证金
    v_b_poundage  number(12,2):=0;           --买方手续费
    v_s_poundage  number(12,2):=0;           --卖方手续费
    v_F_FrozenFunds     number(15,2):=0;
    v_Withdraw    number(10);
    v_withdrawQty number(16,6):=0;           --撤单数量
    v_A_TradeNo   number(10);
    v_orderTime       timestamp;
    v_FlowAmountAlgr   number(2);            --流拍数量计算方式（0：百分比；1：绝对值）
    v_Status           number(3);
begin
    -- 获取当前数据库时间
    select systimestamp(6) into v_orderTime from dual;
    --1. 验证该标的是否已成交，如果已经存在该标的的成交，直接跳出函数
    select Status into v_Status from v_commodity where Code = p_Code;
    if(v_Status<>2) then
        return 1;
    end if;

    --获取商品信息
    select commodityID,   FlowAmount,   FlowAmountAlgr,   Amount,   userID
      into v_commodityID, v_FlowAmount, v_FlowAmountAlgr, v_Amount, v_userID
    from v_commodity where Code = p_Code;
    --汇总委托表中数量
    select nvl(sum(amount),0) into v_amountSum from v_curSubmit where Code = p_Code;
    --获取所属交易节
    select section into v_section from v_curCommodity where Code = p_Code;

    --2. 释放挂单方冻结资金并删除挂单冻结记录
    select FrozenMargin,FrozenFee into v_bailSum,v_poundageSum from V_FundFrozen where Code = p_Code;
    v_F_FrozenFunds := FN_F_UpdateFrozenFunds(v_userID,-v_bailSum-v_poundageSum,'21');
    delete V_FundFrozen where Code = p_Code;

    --计算流拍数量
    if(v_FlowAmountAlgr=1) then--按百分比计算
        v_FlowAmount := v_Amount*v_FlowAmount;
    end if;
    --3. 如果委托数量小于流拍数量 则流拍
    if(v_amountSum<v_FlowAmount) then--流拍
        --循环调用撤单函数
        for withdraw in (select ID,amount from v_curSubmit where Code = p_Code)
          loop
              v_Balance := FN_V_Withdraw(withdraw.ID,1,withdraw.amount);
          end loop;
        --更新当前交易商表
        update v_curCommodity set bargainType = 3, modifyTime = sysdate where Code = p_Code;
        --更新商品表状态
        update v_commodity set Status=8 where Code = p_Code;
    else

        --4. 按照价格优先、数量优先、时间优先的顺序排序(过滤已撤单)
        for trade in (select ID,Price,amount,validAmount,userID,FrozenMargin,FrozenFee,unFrozenMargin,unFrozenFee from v_curSubmit where Code = p_Code and OrderType in (0,5) order by Price,amount desc,submitTime)
            loop
                if(v_Amount>0) then
                    if(v_Amount<trade.amount) then --部分成交
                        v_tradeFlag := 2;
                        v_Qty := trade.validAmount;   --成交数量
                        v_withdrawQty := trade.validAmount - v_Amount;
                    else         --全部成交
                        v_Qty := trade.amount;
                        v_tradeFlag := 1;
                    end if;

                    --计算保证金和手续费
                    if(v_Amount < trade.validAmount) then
                        v_s_bail :=  FN_V_ComputeMargin(p_Code,2,v_Qty,trade.Price,trade.userID);
                        v_s_poundage := FN_V_ComputeFee(p_Code,2,v_Qty,trade.Price,trade.userID);
                    else
                        v_s_bail :=  trade.FrozenMargin - trade.unFrozenMargin;
                        v_s_poundage := trade.FrozenFee - trade.unFrozenFee;
                    end if;

                    --计算买方保证金手续费
                    v_b_bail :=  FN_V_ComputeMargin(p_Code,1,v_Qty,trade.Price,v_userID);
                    v_b_poundage := FN_V_ComputeFee(p_Code,1,v_Qty,trade.Price,v_userID);

                    --获取成交号
                    select SP_V_BARGAIN.nextval into v_A_TradeNo from dual;
                    --写成交
                    insert into v_bargain
                       (contractID,  tradePartition, submitID, Code,   commodityID,   Price,       Amount, userID,       TradeTime, Section,   b_bail,   s_bail,   b_poundage,   s_poundage)
                    values
                       (v_A_TradeNo, 2,              trade.ID, p_Code, v_commodityID, trade.Price, v_Qty,  trade.userID, sysdate,   v_section, v_b_bail, v_s_bail, v_b_poundage, v_s_poundage);

                    --改委托
                    update v_curSubmit set OrderType=v_tradeFlag,
                                           modifytime=v_orderTime,
                                           unFrozenMargin=unFrozenMargin+v_s_bail,
                                           unFrozenFee=unFrozenFee+v_s_poundage
                                       where id = trade.ID;
                    --释放卖方冻结资金
                    v_F_FrozenFunds := FN_F_UpdateFrozenFunds(trade.userID,-v_s_bail-v_s_poundage,'21');
                    --收双方保证金、手续费（写流水）
                    --买方
                    v_Balance := FN_F_UpdateFundsFull(v_userID,'21002',v_b_bail,v_A_TradeNo,v_commodityID,null,null);
                    v_Balance := FN_F_UpdateFundsFull(v_userID,'21001',v_b_poundage,v_A_TradeNo,v_commodityID,null,null);
                    --卖方
                    v_Balance := FN_F_UpdateFundsFull(trade.userID,'21002',v_s_bail,v_A_TradeNo,v_commodityID,null,null);
                    v_Balance := FN_F_UpdateFundsFull(trade.userID,'21001',v_s_poundage,v_A_TradeNo,v_commodityID,null,null);
                    --如果部分成交需要成交后撤单
                    if(v_tradeFlag=2 and v_withdrawQty>0) then
                        v_Withdraw := FN_V_Withdraw(trade.ID,0,v_withdrawQty);
                    end if;

                    --成交后递减商品数量
                    v_Amount := v_Amount - v_Qty;
                else
                    --如果配对成交后有多余的委托单需要做撤单处理
                    v_Withdraw := FN_V_Withdraw(trade.ID,0,trade.amount);
                end if;
            end loop;

        --更新当前交易商品表
        update v_curCommodity set bargainType = 1, modifyTime =sysdate where Code = p_Code;
        --更新商品表状态
        update v_commodity set Status=1 where Code = p_Code;
    end if;
    return 1;
exception
    when others then
    rollback;
    return -1;
end;
/

