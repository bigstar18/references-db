create or replace function FN_V_CloseMarket(p_partitionID number) return number
/****
 * 2013-08-22 by liuyu
 * 闭市处理
****/
as
    v_sysdate     date;
    v_status      number(3);

    --当前商品
    type cue_curComm is ref cursor;
    v_curComm cue_curComm;
    v_tradepartition      number(3);
    v_code                varchar2(64);
    v_commodityid         varchar2(64);
    v_section             number(3);
    --v_lpflag              number(2);   --是否流拍（0：否；1：是）
    v_bargainType         number(2);   --是否成交（0：否；1：是）
    v_modifytime          date;
    v_F_FrozenFunds       number(15,2):=0;
begin
    --获取当前时间
    select sysdate,status into v_sysdate,v_status from v_syscurstatus where tradepartition = p_partitionID;
    if(v_status <> 5) then
        return 0;--系统状态不为闭市直接退出
    end if;

    --导入历史委托清当前委托
    insert into v_hissubmit
          (tradedate, id, tradepartition, code, price, amount, userid, traderId, submittime, OrderType, validamount, modifytime, FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType)
    select v_sysdate, id, tradepartition, code, price, amount, userid, traderID, submittime, OrderType, validamount, modifytime, FrozenMargin, FrozenFee, unFrozenMargin, unFrozenFee, WithdrawType
      from v_cursubmit
     where tradePartition = p_partitionID;

    delete from v_cursubmit where tradePartition = p_partitionID;

    --清空当日行情
    --delete from v_tradequotation where tradePartition = p_partitionID;

    --成交表数据导入历史成交表、合同扩展表、清当前成交表
    insert into v_hisbargain
			  (tradeDate, contractID, tradePartition, section, submitID, code, commodityid, price, amount, userid, tradeTime, b_bail, s_bail, b_poundage, s_poundage, b_payments, s_payments, b_referPayment, s_referPayment, b_dedit, s_dedit, processingTime, remark)
		select sysdate, contractid, tradepartition, section, submitid, code, commodityid, price, amount, userid, tradetime, b_bail, s_bail, b_poundage, s_poundage, 0,          0,          0,              0,              0,       0,       sysdate,        null
      from v_bargain where tradePartition = p_partitionID;

   /* insert into V_ContractExtra (id, code, firmName, witnessmember)
      select contractid,commodityid,userid,SEQ_V_WITNESSMEMBER.Nextval from v_bargain where tradePartition = p_partitionID;*/

    delete from v_bargain where tradePartition = p_partitionID;

    --当前商品导历史
    open v_curComm for select tradepartition, code, commodityid, section, bargainType, modifytime from v_curcommodity where tradePartition = p_partitionID;
        loop
            fetch v_curComm into v_tradepartition, v_code, v_commodityid, v_section, v_bargainType, v_modifytime;
            exit when v_curComm%NOTFOUND;
                --导入历史商品表
                insert into v_hiscommodity
                    (tradedate, tradepartition,   code,   commodityid,   section,   bargainType,   modifytime)
                values
                    (v_sysdate, v_tradepartition, v_code, v_commodityid, v_section, v_bargainType, v_modifytime);
        end loop;

    --清当前商品
    delete from v_curcommodity where tradePartition = p_partitionID;

    --交易权限表导历史表、清当前表（已成交的商品）
    insert into v_hisTradeAuthority
           (tradeDate, Code, userCode, ModifTime)
      select sysdate, t.code, t.usercode, t.modiftime
        from v_TradeAuthority t, v_commodity c
       where t.Code = c.Code
         and c.status in (1,7);

    delete v_TradeAuthority where Code in (select code from v_commodity where status in (1,7));

    --清空自选商品表
    delete from V_CommoditySelf where partitionid = p_partitionID;

    --退挂单方冻结资金并删除冻结记录
    for withdraw in (select f.code,f.userID,f.FrozenMargin,f.FrozenFee from V_FundFrozen f,v_commodity c where f.code = c.code and c.Tradepartition = p_partitionID and c.Status<>1)
        loop
            v_F_FrozenFunds := FN_F_UpdateFrozenFunds(withdraw.userID,-withdraw.FrozenMargin-withdraw.FrozenFee,'21');
            delete V_FundFrozen where Code = withdraw.code;
        end loop;

    --更新当前系统状态表中闭市处理为已处理
    update v_sysCurStatus set isClose = 1 where tradePartition = p_partitionID;

    return 1;
exception
    when others then
    rollback;
    return -1;
end;
/

