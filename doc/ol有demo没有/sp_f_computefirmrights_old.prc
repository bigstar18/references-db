create or replace procedure SP_F_ComputeFirmRights_old(
  p_beginDate date
)
/****
 * ���㽻����Ȩ��
****/
as
	v_lastDate     date;           -- ��һ��������
  v_cnt          number(4);      --���ֱ���
  v_sumFirmFee   number(15, 2);  -- �����������Ѻϼ�
  v_sumFL        number(15, 2);  -- �����̶���ӯ���ϼ�
  v_sumBalance   number(15, 2);  -- ������Ȩ�������úϼ�
begin

   -- ������������Ȩ��������

        -- ɾ����������Ȩ�������ñ�ĵ�������
        delete from F_FirmRightsComputeFunds where b_date = p_beginDate;

        -- ȡ����������Ȩ�������ñ����һ��������
        select max(b_Date) into v_lastDate from F_FirmRightsComputeFunds;

        if(v_lastDate is null) then
          v_lastDate := to_date('2000-01-01','yyyy-MM-dd');
        end if;

       -- �������̵�ǰ�ʽ��Ľ����̺������������˷������ñ��з���������Ȩ�������õ����˴�������
       -- ������������Ȩ�������ñ���Ϊ���յĳ�ʼ����
       insert into F_FirmRightsComputeFunds(B_date, Firmid, Code)
         select p_beginDate,f.firmid, bc.ledgercode
         from f_firmfunds f,F_BankClearLedgerConfig bc
         where bc.feetype = 1;

        for firmRights in (select b_date, firmId, code from F_FirmRightsComputeFunds where b_date = p_beginDate)
        loop
            -- ������������Ȩ�������ñ���������
            update F_FirmRightsComputeFunds f
            set lastBalance = nvl((select balance
                 from F_FirmRightsComputeFunds where b_date = v_lastDate and firmId = firmRights.firmId and code = firmRights.code ), 0)
            where b_date = firmRights.b_date and firmId = firmRights.firmId and code = firmRights.code;

            -- ������������Ȩ�������ñ�ĵ������
            update F_FirmRightsComputeFunds f
            set balance = nvl((select bc.fieldsign*c.value as amount
                               from f_clientledger c, f_bankclearledgerconfig bc
                               where c.b_date = firmRights.b_date and c.firmId = firmRights.firmId and c.code = firmRights.code and c.code = bc.ledgercode ), 0)
            where b_date = firmRights.b_date and firmId = firmRights.firmId and code = firmRights.code;

            -- ������������Ȩ�������ñ�ĵ������Ϊ��������� + �������
            --�������Ϳ��Բ��õ�����ϵͳ��ȥȡ��Щ�ʽ��
            update F_FirmRightsComputeFunds f
            set balance = balance + lastBalance
            where b_date = firmRights.b_date and firmId = firmRights.firmId and code = firmRights.code;

        end loop;


   -- ���½����������ʽ�

     -- ɾ�������������ʽ��ĵ�������
     delete from F_FirmClearFunds where b_date = p_beginDate;

     -- �������̵�ǰ�ʽ��������뽻���������ʽ��
     insert into F_FirmClearFunds(B_date, Firmid, Balance)
     select p_beginDate, f.firmid, f.balance from f_firmfunds f;

     for firmClearFunds in (select b_date, firmId from F_FirmClearFunds where b_date = p_beginDate)
     loop
         -- ���㽻����������
         select nvl(sum(value), 0) sumFirmFee into v_sumFirmFee
         from F_ClientLedger c
         where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId
         and c.code in (select LedgerCode from F_BankClearLedgerConfig where FeeType = 0);

           -- ���½����������ʽ��Ľ�����������
           update F_FirmClearFunds
           set firmFee = v_sumFirmFee
           where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

         -- �����г�������

         -- ���㽻����Ȩ�涳���ʽ�

            -- ͳ����������Ȩ�������õĵ������
            select nvl(sum(Balance), 0) sumBalance into v_sumBalance from F_FirmRightsComputeFunds where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

            -- �ж��Ƿ����ö���ϵͳ
            select count(*) into v_cnt from c_trademodule where moduleId = 15 and isbalancecheck = 'Y';
            if(v_cnt > 0) then

               -- ͳ�ƶ����ֲ�ӯ��
               select nvl(sum(FloatingLoss), 0) sumFL into v_sumFL from T_H_FirmHoldSum t where t.cleardate = firmClearFunds.b_date and t.firmid = firmClearFunds.firmId;

               update F_FirmClearFunds
               set RightsFrozenFunds = v_sumBalance + v_sumFL
               where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

            else
               update F_FirmClearFunds
               set RightsFrozenFunds = v_sumBalance
               where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

            end if;

         -- ���㽻����Ȩ��
         update F_FirmClearFunds
         set Rights = Balance + RightsFrozenFunds
         where b_date = firmClearFunds.b_date and firmId = firmClearFunds.firmId;

     end loop;

end;
/

