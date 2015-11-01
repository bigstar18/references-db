create or replace function FN_F_Balance_old
(
    p_beginDate date:=null --����һ�쿪ʼ����
) return number
/**
 ���ӷ���ֵ-101����������Ϊ��
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
               note = '������';
  commit; --�˴��ύ��Ϊ�˽�����״̬��Χ�ܿ�����

   --�Բ���ϵͳ״̬���������ֹ������㲢��
   select b_date,status into v_b_date,v_status from F_systemstatus for update;

  --���㿪ʼ
  SP_F_ClearAction_Done(p_actionid => 0);

  --��ȡ����ƾ֤
  v_rtn := FN_F_ExtractVoucher();
  SP_F_ClearAction_Done(p_actionid => 1);

  if p_beginDate is not null then
   v_beginDate:=trunc(p_beginDate);
  else
    v_beginDate:= trunc(sysdate);
  end if;
 /* --���������
  select nvl(max(b_date),to_date('2000-01-01','yyyy-MM-dd')) into v_lastDate from f_dailybalance;
  --������¼�����������յ�ƾ֤�������������ǰһ�졣
  select count(*) into v_cnt from f_voucher where b_date=v_lastDate and status='audited';
  if(v_cnt>0) then
    v_lastDate:=v_lastDate-1;
  end if;

  if(v_beginDate is null) then
    v_beginDate := v_lastDate + 1;
  else
    --�ж�ָ���������ں��������ռ��Ƿ���ƾ֤������д���������պ�һ�쿪ʼ
    select count(*) into v_cnt from f_voucher where b_date>v_lastDate and b_date<p_beginDate;
    if(v_cnt>0) then
      v_beginDate := v_lastDate + 1;
    end if;
  end if;*/

  --������ˮ��ƾ֤����
  update f_fundflow set b_date=v_beginDate;
  update f_voucher set b_date=v_beginDate where status='audited';
  SP_F_ClearAction_Done(p_actionid => 2);



  insert into f_log
    (occurtime, type, userid, description)
  values
    (sysdate, 'sysinfo', 'system', 'Balance specify date:'||nvl(to_char(p_beginDate,'yyyy-MM-dd'),'No')||' ->exec date:'||to_char(v_beginDate,'yyyy-MM-dd'));

  --��ƾ֤�������˲�
  SP_F_PutVoucherToBook(v_beginDate);
  SP_F_ClearAction_Done(p_actionid => 3);
  --�����˻�
  SP_F_BalanceAccount(v_beginDate);
  SP_F_ClearAction_Done(p_actionid => 4);
  --���ɿͻ�����
  SP_F_ClientLedger(v_beginDate);
  SP_F_ClearAction_Done(p_actionid => 5);


  --������ʷ��ˮ��
  insert into f_h_fundflow
  select * from f_fundflow where b_date is not null;
  --ɾ����ǰ��ˮ���¼
  delete from F_Fundflow where b_date is not null;

  --���붳���ʽ���ʷ��ˮ��
  insert into f_h_frozenfundflow
  select * from f_frozenfundflow;

  --ɾ����ǰ�Ķ����ʽ���ˮ��
  delete from f_frozenfundflow;
  SP_F_ClearAction_Done(p_actionid => 6);


  update F_systemstatus
           set b_date = v_beginDate,
               status = 2,
               note = '�������',
               cleartime = sysdate;
 SP_F_ClearAction_Done(p_actionid => 7);
  return 1;
 exception
    when others then
        rollback;

        -- �ָ�״̬Ϊδ����
        update f_systemstatus
           set status = 0,
               note = 'δ����';
        commit;

        return -100;
end;
/

