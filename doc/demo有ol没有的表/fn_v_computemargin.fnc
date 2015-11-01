create or replace function FN_V_ComputeMargin(
    p_Code            varchar2,
    p_bs_flag         number,   --����ģʽ��1����2������
    p_quantity        number,
    p_price           number,
    p_userID          varchar2
) return number
/****
 * ���㱣֤�𣨾��ۣ�
 * ����ֵ �ɹ����ر�֤��;-1 �����������ݲ�ȫ;-100 ��������
****/
as
	  v_version varchar2(10):='1.0.0.1';
    v_marginRate_b         number(15,4);
    v_marginRate_s         number(15,4);
    v_marginRate           number(15,4);
    --v_commodityID          varchar2(64);
    v_marginAlgr           number(2);
    v_margin               number(12,2) default 0;
    v_BreedID              number(10,0);
    v_num                  number(10);
begin
    --��ȡ��Ʒ��Ϣ�����ױ�֤��
    select MarginAlgr,B_security,S_security,BreedID into v_marginAlgr,v_marginRate_b,v_marginRate_s,v_BreedID from v_commodity where Code=p_Code;

    --------------------------���Ᵽ֤��------------------------------------
    --��ȡ���Ᵽ֤��
    select count(*) into v_num from V_FirmSpecialMargin where userCode = p_userID and BreedID = v_BreedID and bs_flag = p_bs_flag;
    if(v_num = 1) then
        select MarginAlgr,Margin into v_marginAlgr,v_marginRate from V_FirmSpecialMargin where userCode = p_userID and BreedID = v_BreedID and bs_flag = p_bs_flag;
        if(p_bs_flag = 1) then
            v_marginRate_b := v_marginRate;
        else
            v_marginRate_s := v_marginRate;
        end if;
    end if;
    --------------------------���Ᵽ֤�� end------------------------------------

    if(v_marginAlgr=1) then  --�ٷֱ�
    	if(p_bs_flag = 1) then  --��
		    if(v_marginRate_b = -1) then --  -1��ʾ��ȫ��
		    	v_margin:=p_quantity*p_price;
		    else
			    v_margin:=p_quantity*p_price*v_marginRate_b;
		    end if;
      elsif(p_bs_flag = 2) then  --��
		    if(v_marginRate_s = -1) then --  -1��ʾ��ȫ��
		    	v_margin:=p_quantity*p_price;
		    else
			    v_margin:=p_quantity*p_price*v_marginRate_s;
		    end if;
      end if;
    elsif(v_marginAlgr=0) then  --����ֵ
    	if(p_bs_flag = 1) then  --��
		    if(v_marginRate_b = -1) then --  -1��ʾ��ȫ��
		    	v_margin:=p_quantity*p_price;
		    else
			    v_margin:=p_quantity*v_marginRate_b;
		    end if;
      elsif(p_bs_flag = 2) then  --��
		    if(v_marginRate_s = -1) then --  -1��ʾ��ȫ��
		    	v_margin:=p_quantity*p_price;
		    else
			    v_margin:=p_quantity*v_marginRate_s;
		    end if;
      end if;
    end if;

    if(v_margin is null) then
    	rollback;
      return -1;
    end if;
    return v_margin;
exception
    when no_data_found then
    	rollback;
      return -1;
    when others then
	    rollback;
    	return -100;
end;
/

