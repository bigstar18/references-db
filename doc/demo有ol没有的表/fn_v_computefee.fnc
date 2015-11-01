create or replace function FN_V_ComputeFee(
    p_Code           varchar2,
    p_bs_flag        number,      --买卖标志（1：买；2：卖）
    p_quantity       number,
    p_price          number,
    p_userID         varchar2
) return number
/****
 * 计算手续费（竞价）
 * 返回值 成功返回手续费;-1 计算交易费用所需数据不全;-100 其它错误
****/
as
    v_feeRate_b         number(15,5);
    v_feeRate_s         number(15,5);
    v_feeAlgr           number(2);
    v_feeRate           number(15,5);
    v_fee               number(15,2) default 0;
    --v_commodityID       varchar2(64);
    v_BreedID           number(10,0);
    v_num               number(10);
begin
    --获取商品信息：交易手续费
    select FeeAlgr,B_fee,S_fee,BreedID into v_feeAlgr,v_feeRate_b,v_feeRate_s,v_BreedID from v_commodity where Code=p_Code;

    --------------------------特殊手续费------------------------------------
    --获取特殊手续费
    select count(*) into v_num from V_FirmSpecialFee where userCode = p_userID and BreedID = v_BreedID and bs_flag = p_bs_flag;
    if(v_num = 1) then
        select FeeAlgr,Fee into v_feeAlgr,v_feeRate from V_FirmSpecialFee where userCode = p_userID and BreedID = v_BreedID and bs_flag = p_bs_flag;
        if(p_bs_flag = 1) then
            v_feeRate_b := v_feeRate;
        else
            v_feeRate_s := v_feeRate;
        end if;
    end if;
    --------------------------特殊手续费 end------------------------------------

    if(v_feeAlgr=1) then  --百分比
    	if(p_bs_flag = 1) then  --买
        	v_fee:=p_quantity*p_price*v_feeRate_b;
        elsif(p_bs_flag = 2) then  --卖
        	v_fee:=p_quantity*p_price*v_feeRate_s;
        end if;
    elsif(v_feeAlgr=0) then  --绝对值
    	if(p_bs_flag = 1) then  --买
        	v_fee:=p_quantity*v_feeRate_b;
        elsif(p_bs_flag = 2) then  --卖
        	v_fee:=p_quantity*v_feeRate_s;
        end if;
    end if;
    if(v_fee is null) then
    	  rollback;
        return -1;
    end if;
    return v_fee;
exception
    when no_data_found then
    	rollback;
        return -1;
    when others then
    	rollback;
   		return -100;
end;
/

