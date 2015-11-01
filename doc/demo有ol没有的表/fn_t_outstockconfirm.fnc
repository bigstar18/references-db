create or replace function FN_T_OUTSTOCKCONFIRM(
p_stockId  varchar2, --确认收货的仓单ID
p_operator varchar2 --操作员
)
return number
/**
   *  出库的仓单进行确认收货（如果有多个关联仓单，按本仓单占所有关联仓单数量百分比进行付尾款）
   *  返回值
   *  1 确认收货成功
   *  0 仓单正在使用中
   * -1 未找到此仓单交收配对信息无法确认收货
   * by 张天骥 2015-08-14
  ****/
 as
  v_tradeNo t_Settlematch.Matchid%type; --交收配对编号
  v_buyTax number(15,2);--交收配对税费
  v_hl_Amout number(15,2);--升贴水
  v_sellIncome number(15,2);--卖方收货款
  v_sellIncome_Ref number(15,2);--卖方基准货款
  v_payMent number(15,2);--全部尾款
  v_realpayMent number(15,2);--本仓单尾款
  v_amount number(15,2);--金额
  v_firmId_S t_Settlematch.Firmid_s%type;--卖方 ID
  v_firmId_B t_Settlematch.Firmid_b%type;--买方 ID
  v_commodityId t_Settlematch.Commodityid%type;--商品代码
  v_everyAmount number(15,2):=0;--单个关联的仓单数量
  v_confirmAmount number(15,2);--确认收货的商品数量
  v_stockTotal number(15,2):=0; --商品数量
  v_received number(1); --是否收货
  v_stockAmont number(15):=0;--关联仓单数量
begin
  --找到时间最近的关于此仓单的交收配对号
  begin
    select tradeNo into v_tradeNo from (select tradeNo from Bi_tradeStock where stockid = p_stockId and status = 1 order by releasetime desc) where Rownum = 1;
  exception
    when NO_DATA_FOUND then
      return 0;
  end;

  --查找对应的交收配对信息
  begin
    select sellincome,hl_Amount,sellincome_ref,Buytax,Firmid_s,Commodityid,Firmid_b  into
           v_sellIncome,v_hl_Amout,v_sellIncome_Ref,v_buyTax,v_firmId_S,v_commodityId,v_firmId_B from T_SETTLEMATCH where matchid = v_tradeNo for update;
  exception
    when NO_DATA_FOUND then
      return - 1;
  end;
  --查询所有关联仓单,计算关联的所有仓当数量
  for stock in (select * from BI_TRADESTOCK where tradeNo=v_tradeNo)
    loop
      --先确认关联的仓单是否确认收货
     select RECEIVED into v_received from (select RECEIVED from BI_BUSINESSRELATIONSHIP where  stockid=stock.stockId and BUYER=v_firmId_B
                 and seller=v_firmId_S order by selltime desc) where rowNum=1;
      --如果没有收货
      if(v_received=0) then
      select quantity into v_everyAmount from BI_STOCK where stockId = stock.stockid ;
       v_stockTotal:=v_stockTotal+v_everyAmount;
       v_stockAmont:=v_stockAmont+1;
       end if;
      end loop;

      select quantity into v_confirmAmount from Bi_Stock where stockId = p_stockId;
      --如果仓单数为0
      if(v_stockTotal=0) then
      return -1;
      end if;

      --计算尾款 ( 卖方基准货款 +升贴水 +税费 - 卖方收到的钱 +税费 )
      v_payMent:=(v_sellIncome_Ref+v_hl_Amout+v_buyTax)-(v_sellIncome+v_buyTax);
  --如果只剩下一个仓单没确认收货进行减法算钱
  if(v_stockAmont=1) then
  v_realpayMent:=v_payMent;
  else
    v_realpayMent:=(v_payMent/v_stockTotal)*v_confirmAmount;
  end if;

  --打尾款
  if(v_realpayMent!=0) then
    update t_Settlematch t set  t.Sellincome=t.Sellincome+v_realpayMent where t.matchId=v_tradeNo;
    --写流水
    v_amount:=FN_F_UpdateFundsFull(v_firmId_S,'15009',v_realpayMent,v_tradeNo,v_commodityId,null,null);
    --写入交收配对金额日志
    insert into t_Settlematchfundmanage(Id, Matchid, Firmid, Summaryno, Amount, Operatedate, Commodityid)
           values(seq_t_settlematchfundmanage.nextval,v_tradeNo,v_firmId_S,'15009',v_realpayMent,sysdate,v_commodityId);
    --写入交收配对日志
    insert into t_Settlematchlog(Id, Matchid, Operator, Operatelog, Updatetime)
           values(seq_t_settlematchlog.nextval,v_tradeNo,p_operator,'卖方确认收货,仓单号:'||p_stockId||',收货款,配对ID:'||v_tradeNo||'金额:'||v_realpayMent,sysdate);
    end if;
    --更新交收配对时间与变动人
    update t_Settlematch t set t.modifier=p_operator,t.modifytime=sysdate where t.matchid=v_tradeNo;

    --最后将买卖关系表置为完成状态
    update BI_BUSINESSRELATIONSHIP B set received=1,receiveddate=sysdate where b.selltime =
                 (select selltime from ( select selltime from BI_BUSINESSRELATIONSHIP where  stockid=p_stockId and BUYER=v_firmId_B
                 and seller=v_firmId_S order by selltime desc) where rowNum=1) and BUYER=v_firmId_B and seller=v_firmId_S and stockid=p_stockId;
      return 1;
end;
/

