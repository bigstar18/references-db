create or replace procedure SP_F_ComputeFirmRights_old(
  p_beginDate date
)
/****
 * 计算交易商权益
****/
as
	v_lastDate     date;           -- 上一个结算日
  v_cnt          number(4);      --数字变量
  v_sumFirmFee   number(15, 2);  -- 交易商手续费合计
  v_sumFL        number(15, 2);  -- 交易商订货盈亏合计
  v_sumBalance   number(15, 2);  -- 交易商权益计算费用合计
begin

   -- 更新银行清算权益计算费用

        -- 删除银行清算权益计算费用表的当日数据
        delete from F_FirmRightsComputeFunds where b_date = p_beginDate;

        -- 取得银行清算权益计算费用表的上一个结算日
        select max(b_Date) into v_lastDate from F_FirmRightsComputeFunds;

        if(v_lastDate is null) then
          v_lastDate := to_date('2000-01-01','yyyy-MM-dd');
        end if;

       -- 将交易商当前资金表的交易商和银行清算总账费用配置表中费用类型是权益计算费用的总账代码链表
       -- 插入银行清算权益计算费用表作为当日的初始数据
       insert into F_FirmRightsComputeFunds(B_date, Firmid, Code)
         select p_beginDate,f.firmid, bc.ledgercode
         from f_firmfunds f,F_BankClearLedgerConfig bc
         where bc.feetype = 1;

        for firmRights in (select b_date, firmId, code from F_FirmRightsComputeFunds where b_date = p_beginDate)
        loop
            -- 更新银行清算权益计算费用表的上日余额
            update F_FirmRightsComputeFunds f
            set lastBalance = nvl((select balance
                 from F_FirmRightsComputeFunds where b_date = v_lastDate and firmId = firmRights.firmId and code = firmRights.code ), 0)
            where b_date = firmRights.b_date and firmId = firmRights.firmId and code = firmRights.code;

            -- 更新银行清算权益计算费用表的当日余额
            update F_FirmRightsComputeFunds f
            set balance = nvl((select bc.fieldsign*c.value as amount
                               from f_clientledger c, f_bankclearledgerconfig bc
                               where c.b_date = firmRights.b_date and c.firmId = firmRights.firmId and c.code = firmRights.code and c.code = bc.ledgercode ), 0)
            where b_date = firmRights.b_date and firmId = firmRights.firmId and code = firmRights.code;

            -- 更新银行清算权益计算费用表的当日余额为：当日余额 + 上日余额
            --（这样就可以不用到交易系统中去取这些资金项）
            update F_FirmRightsComputeFunds f
            set balance = balance + lastBalance
            where b_date = firmRights.b_date and firmId = firmRights.firmId and code = firmRights.code;

        end loop;


   -- 更新交易商清算资金

     -- 删除交易商清算资金表的当日数据
     delete from F_FirmClearFunds where b_date = p_beginDate;

     -- 将交易商当前资金表的余额插入交易商清算资金表
     insert into F_FirmClearFunds(B_date, Firmid, Balance)
     select p_beginDate, f.firmid, f.balance from f_firmfunds f;

     for firmClearFunds in (select b_date, firmId from F_FirmClearFunds where b_date = p_beginDate)
     loop
         -- 计算交易商手续费
         select nvl(sum(value), 0) sumFirmFee into v_sumFirmFee
         from F_ClientLedger c
         where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId
         and c.code in (select LedgerCode from F_BankClearLedgerConfig where FeeType = 0);

           -- 更新交易商清算资金表的交易商手续费
           update F_FirmClearFunds
           set firmFee = v_sumFirmFee
           where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

         -- 计算市场手续费

         -- 计算交易商权益冻结资金

            -- 统计银行清算权益计算费用的当日余额
            select nvl(sum(Balance), 0) sumBalance into v_sumBalance from F_FirmRightsComputeFunds where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

            -- 判断是否启用订单系统
            select count(*) into v_cnt from c_trademodule where moduleId = 15 and isbalancecheck = 'Y';
            if(v_cnt > 0) then

               -- 统计订单持仓盈亏
               select nvl(sum(FloatingLoss), 0) sumFL into v_sumFL from T_H_FirmHoldSum t where t.cleardate = firmClearFunds.b_date and t.firmid = firmClearFunds.firmId;

               update F_FirmClearFunds
               set RightsFrozenFunds = v_sumBalance + v_sumFL
               where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

            else
               update F_FirmClearFunds
               set RightsFrozenFunds = v_sumBalance
               where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

            end if;

         -- 计算交易商权益
         update F_FirmClearFunds
         set Rights = Balance + RightsFrozenFunds
         where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

     end loop;

end;
/

