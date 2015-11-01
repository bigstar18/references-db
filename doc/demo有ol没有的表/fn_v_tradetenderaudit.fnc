create or replace function FN_V_TradeTenderAudit(p_Code varchar2) return number
/****
 * 2013-12-16 by liuyu
 * 招标成交确认
 * 返回值
 * 1  成功
 * -1 失败
 * -2 确认数量大于商品数量
****/
as
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
    v_c_bail      number(12,2):=0;           --投标方保证金
    v_m_bail      number(12,2):=0;           --挂标方保证金
    v_c_poundage  number(12,2):=0;           --投标方手续费
    v_m_poundage  number(12,2):=0;           --挂标方手续费
    v_F_FrozenFunds     number(15,2):=0;
    v_Withdraw    number(10);
    v_withdrawQty number(16,6):=0;           --撤单数量
    v_A_TradeNo   number(10);
    v_orderTime       timestamp;
    v_TenderTradeConfirm  number(2);         --招标成交确认（0：未确认；1：已确认）
    v_ConfirmAmount       number(16,6):=0;   --确认成交数量汇总
    v_bs_flag             number(2);         --商品买卖方向
    v_bs_flag_c           number(2);         --投标方买卖方向
    v_num                 number(3);
begin
    --获取当前数据库时间
    select systimestamp(6) into v_orderTime from dual;

    --1. 验证该标的是否已经确认成交，如果该标的已经确认成交，直接跳出函数
    select TenderTradeConfirm into v_TenderTradeConfirm from v_commodity where Code = p_Code;
    if(v_TenderTradeConfirm=1) then
        return 1;
    end if;

    --获取商品信息
    select commodityID,   Amount,   beginPrice,   alertPrice,   userID,   bs_flag
      into v_commodityID, v_Amount, v_beginPrice, v_alertPrice, v_userID, v_bs_flag
    from v_commodity where Code = p_Code;

    --2. 验证商品数量是否满足成交数量，不满足直接退出
    select nvl(sum(ConfirmAmount),0) into v_ConfirmAmount from v_curSubmitTenderPlan where code = p_Code;
    if(v_ConfirmAmount > v_Amount) then
         return -2;
    end if;

    --获取所属交易节
    select count(*) into v_num from v_curCommodity where Code = p_Code;
    if(v_num = 1) then
        select section into v_section from v_curCommodity where Code = p_Code;
    else
        select max(nvl(section,0)) into v_section from v_hisCommodity where Code = p_Code;
    end if;
    --select section into v_section from (select section from v_curCommodity where Code = p_Code union select section from v_hisCommodity where Code = p_Code);

    --3. 释放挂单方冻结资金并删除挂单冻结记录
    select FrozenMargin,FrozenFee into v_bailSum,v_poundageSum from V_FundFrozen where Code = p_Code;
    v_F_FrozenFunds := FN_F_UpdateFrozenFunds(v_userID,-v_bailSum-v_poundageSum,'21');
    delete V_FundFrozen where Code = p_Code;

    --根据商品买卖方向确定委托买卖方向
    if(v_bs_flag=1) then
       v_bs_flag_c := 2;
    else
       v_bs_flag_c := 1;
    end if;

    --4. 按照价格优先、数量优先、时间优先的顺序排序(过滤不符合价格区间的委托)
    for trade in (select ID,Price,amount,ConfirmAmount,validAmount,userID,FrozenMargin,FrozenFee,unFrozenMargin,unFrozenFee from v_curSubmitTenderPlan where Code = p_Code)
        loop
            if(trade.ConfirmAmount<trade.amount) then --部分成交
                v_tradeFlag := 2;
                --v_Qty := trade.ConfirmAmount;   --成交数量
                v_withdrawQty := trade.amount - trade.ConfirmAmount;
            else         --全部成交
                --v_Qty := trade.amount;
                v_tradeFlag := 1;
            end if;

            --成交数量
            v_Qty := trade.ConfirmAmount;

            --计算投标方保证金和手续费
            if(trade.ConfirmAmount<trade.amount) then
                v_c_bail :=  FN_V_ComputeMargin(p_Code,v_bs_flag_c,v_Qty,trade.Price,trade.userID);
                v_c_poundage := FN_V_ComputeFee(p_Code,v_bs_flag_c,v_Qty,trade.Price,trade.userID);
            else
                v_c_bail :=  trade.FrozenMargin - trade.unFrozenMargin;
                v_c_poundage := trade.FrozenFee - trade.unFrozenFee;
            end if;

            --计算挂单方保证金手续费
            v_m_bail :=  FN_V_ComputeMargin(p_Code,v_bs_flag,v_Qty,trade.Price,v_userID);
            v_m_poundage := FN_V_ComputeFee(p_Code,v_bs_flag,v_Qty,trade.Price,v_userID);

            if(v_bs_flag=1) then --如果挂标方为买方
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

            --获取成交号
            select SP_V_BARGAIN.nextval into v_A_TradeNo from dual;
            --写成交
            insert into v_bargain
               (contractID,  tradePartition, submitID, Code,   commodityID,   Price,       Amount, userID,       TradeTime, Section,   b_bail,   s_bail,   b_poundage,   s_poundage)
            values
               (v_A_TradeNo, 3,              trade.ID, p_Code, v_commodityID, trade.Price, v_Qty,  trade.userID, sysdate,   v_section, v_b_bail, v_s_bail, v_b_poundage, v_s_poundage);

            --改委托(当前表和历史表都有可能有数据)
            --1） 当前表
            update v_curSubmit set OrderType=v_tradeFlag,
                                   modifytime=v_orderTime,
                                   unFrozenMargin=unFrozenMargin+v_s_bail,
                                   unFrozenFee=unFrozenFee+v_s_poundage
                               where id = trade.ID;
            --2） 历史表
            update v_hisSubmit set OrderType=v_tradeFlag,
                                   modifytime=v_orderTime,
                                   unFrozenMargin=unFrozenMargin+v_s_bail,
                                   unFrozenFee=unFrozenFee+v_s_poundage
                               where id = trade.ID;

            --释放卖方冻结资金
            v_F_FrozenFunds := FN_F_UpdateFrozenFunds(trade.userID,-v_c_bail-v_c_poundage,'21');
            --收双方保证金、手续费（写流水）
            --挂单方
            v_Balance := FN_F_UpdateFundsFull(v_userID,'21002',v_m_bail,v_A_TradeNo,v_commodityID,null,null);
            v_Balance := FN_F_UpdateFundsFull(v_userID,'21001',v_m_poundage,v_A_TradeNo,v_commodityID,null,null);
            --投标方
            v_Balance := FN_F_UpdateFundsFull(trade.userID,'21002',v_c_bail,v_A_TradeNo,v_commodityID,null,null);
            v_Balance := FN_F_UpdateFundsFull(trade.userID,'21001',v_c_poundage,v_A_TradeNo,v_commodityID,null,null);
            --如果部分成交需要成交后撤单
            if(v_tradeFlag=2 and v_withdrawQty>0) then
                v_Withdraw := FN_V_Withdraw(trade.ID,0,v_withdrawQty);
            end if;

            --成交后递减商品数量
            v_Amount := v_Amount - v_Qty;
        end loop;


    --5. 将未中标委托进行撤单
    for otherwithdraw in (select ID,amount from v_curSubmitTender where Code = p_Code and id not in (select id from v_curSubmitTenderPlan where Code = p_Code))
        loop
            v_Balance := FN_V_Withdraw(otherwithdraw.ID,0,otherwithdraw.amount);
        end loop;

    --6. 清空招标委托表
    delete v_curSubmitTender where Code = p_Code;

    --更新当前交易商品表
    --update v_curCommodity set bargainType = 1, modifyTime =sysdate where Code = p_Code;
    --7. 更新商品表状态
    update v_commodity set TenderTradeConfirm = 1 where Code = p_Code;

    return 1;
exception
    when others then
    rollback;
    return -1;
end;
/

