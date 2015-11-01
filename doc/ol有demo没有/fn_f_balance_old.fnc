create or replace function FN_F_Balance_old
(
    p_beginDate date:=null --从哪一天开始结算
) return number
/**
 增加返回值-101，结算日期为空
**/
is
  v_lastDate date;
  v_beginDate date;
  v_b_date f_systemstatus.b_date%type;
  v_status f_systemstatus.status%type;
  v_cnt number(10);
  v_rtn number(10);
  v_errorcode      number;
    v_errormsg       varchar2(200);
begin
/*  if(p_beginDate is null) then
   p_beginDate := trunc(sysdate);
  end if;*/
   update F_systemstatus
           set status = 1,
               note = '结算中';
  commit; --此处提交是为了结算中状态外围能看到。

   --对财务系统状态表加锁，防止财务结算并发
   select b_date,status into v_b_date,v_status from F_systemstatus for update;

  --结算开始
  SP_F_ClearAction_Done(p_actionid => 0);

  --抽取电脑凭证
  v_rtn := FN_F_ExtractVoucher();
  SP_F_ClearAction_Done(p_actionid => 1);

  if p_beginDate is not null then
   v_beginDate:=trunc(p_beginDate);
  else
    v_beginDate:= trunc(sysdate);
  end if;
 /* --最近结算日
  select nvl(max(b_date),to_date('2000-01-01','yyyy-MM-dd')) into v_lastDate from f_dailybalance;
  --如果有新加入最近结算日的凭证，最近结算日提前一天。
  select count(*) into v_cnt from f_voucher where b_date=v_lastDate and status='audited';
  if(v_cnt>0) then
    v_lastDate:=v_lastDate-1;
  end if;

  if(v_beginDate is null) then
    v_beginDate := v_lastDate + 1;
  else
    --判断指定结算日期和最后结算日间是否有凭证，如果有从最近结算日后一天开始
    select count(*) into v_cnt from f_voucher where b_date>v_lastDate and b_date<p_beginDate;
    if(v_cnt>0) then
      v_beginDate := v_lastDate + 1;
    end if;
  end if;*/

  --归属流水及凭证日期
  update f_fundflow set b_date=v_beginDate;
  update f_voucher set b_date=v_beginDate where status='audited';
  SP_F_ClearAction_Done(p_actionid => 2);



  insert into f_log
    (occurtime, type, userid, description)
  values
    (sysdate, 'sysinfo', 'system', 'Balance specify date:'||nvl(to_char(p_beginDate,'yyyy-MM-dd'),'No')||' ->exec date:'||to_char(v_beginDate,'yyyy-MM-dd'));

  --将凭证记入会计账簿
  SP_F_PutVoucherToBook(v_beginDate);
  SP_F_ClearAction_Done(p_actionid => 3);
  --结算账户
  SP_F_BalanceAccount(v_beginDate);
  SP_F_ClearAction_Done(p_actionid => 4);
  --生成客户总账
  SP_F_ClientLedger(v_beginDate);
  SP_F_ClearAction_Done(p_actionid => 5);


  --插入历史流水表
  insert into f_h_fundflow
  select * from f_fundflow where b_date is not null;
  --删除当前流水表记录
  delete from F_Fundflow where b_date is not null;

  --插入冻结资金历史流水表
  insert into f_h_frozenfundflow
  select * from f_frozenfundflow;

  --删除当前的冻结资金流水表
  delete from f_frozenfundflow;
  SP_F_ClearAction_Done(p_actionid => 6);


  update F_systemstatus
           set b_date = v_beginDate,
               status = 2,
               note = '结算完成',
               cleartime = sysdate;
 SP_F_ClearAction_Done(p_actionid => 7);
  return 1;
 exception
    when others then
        rollback;

        -- 恢复状态为未结算
        update f_systemstatus
           set status = 0,
               note = '未结算';
        commit;

        return -100;
end;
/

