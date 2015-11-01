create or replace procedure SP_E_MoveHistory(p_EndDate Date) as
/**
 * 转历史
 **/
begin
  ---------------------------委托相关
  --转议价
  insert into e_suborder_h(suborderid, orderid, subfirmid, quantity, price, warehouseid, TradePreTime, deliverymargin_b, deliverymargin_s,FrozenMargin, remark, status, createtime, reply, replytime, withdrawer, withdrawtime, DeliveryPreTime, DeliveryDayType, DeliveryDay)
  select suborderid, orderid, subfirmid, quantity, price, warehouseid, TradePreTime, deliverymargin_b, deliverymargin_s,FrozenMargin, remark, status, createtime, reply, replytime, withdrawer, withdrawtime, DeliveryPreTime, DeliveryDayType, DeliveryDay
    from e_suborder s where s.orderid in
         (select o.orderid from e_order o where o.ordertime <= p_EndDate and o.status in (2,3));--全部成交，已下架
  delete from e_suborder s where s.orderid in
         (select o.orderid from e_order o where o.ordertime <= p_EndDate and o.status in (2,3));
  --转委托属性
  insert into e_goodsproperty_h(orderid, propertyname, propertyvalue, propertyTypeID)
  select orderid, propertyname, propertyvalue, propertyTypeID
    from e_goodsproperty p where p.orderid in
         (select o.orderid from e_order o where o.ordertime <= p_EndDate and o.status in (2,3));
  delete from e_goodsproperty p where p.orderid in
         (select o.orderid from e_order o where o.ordertime <= p_EndDate and o.status in (2,3));
  --转委托图片
  insert into e_OrderPic_H(ID,OrderID,picture)
  select ID,OrderID,picture
    from e_OrderPic p where p.OrderID in
	     (select o.orderid from e_order o where o.ordertime <= p_EndDate and o.status in (2,3));
  delete from e_OrderPic p where p.OrderID in
	     (select o.orderid from e_order o where o.ordertime <= p_EndDate and o.status in (2,3));
  --转委托
  insert into e_order_h(orderid, ordertitle, breedid, bsflag, firmid, price, quantity, unit, TradePreTime, trademargin_b, trademargin_s, deliverydaytype, DeliveryPreTime, deliveryday, deliverymargin_b, deliverymargin_s, deliverytype, warehouseid, deliveryaddress, status, tradedqty, remark, ordertime, traderid, withdrawtime, withdrawtraderid, categoryid, ValidTime, pledgeflag, mintradeqty,TradeUnit,IsPickOff,IsSuborder,IsPayMargin,FrozenMargin,TradeType,PayType,EffectOfTime,StockID)
  select orderid, ordertitle, breedid, bsflag, firmid, price, quantity, unit, TradePreTime, trademargin_b, trademargin_s, deliverydaytype, DeliveryPreTime, deliveryday, deliverymargin_b, deliverymargin_s, deliverytype, warehouseid, deliveryaddress, status, tradedqty, remark, ordertime, traderid, withdrawtime, withdrawtraderid, categoryid, ValidTime, pledgeflag, mintradeqty,TradeUnit,IsPickOff,IsSuborder,IsPayMargin,FrozenMargin,TradeType,PayType,EffectOfTime,StockID
    from e_order o where o.ordertime <= p_EndDate and o.status in (2,3);
  delete from e_order o where o.ordertime <= p_EndDate and o.status in (2,3);


  ---------------------------合同相关
  --1：订单阶段违约 2：订单阶段系统撤销 4：成交阶段违约 8：正常结束
  --转订单
  insert into e_reserve_h(reserveid, tradeno, firmid, realmoney, bsflag, payablereserve, payreserve, backreserve, goodsquantity, status, breachapplyid)
  select reserveid, tradeno, firmid, realmoney, bsflag, payablereserve, payreserve, backreserve, goodsquantity, status, breachapplyid
    from e_reserve r where r.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  delete from e_reserve r where r.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  --转持仓
  insert into e_holding_h(holdingid, tradeno, firmid, bsflag, realmoney, paymargin, paygoodsmoney, payoff,Receive, transfermoney, status, breachapplyid, offsetid)
  select holdingid, tradeno, firmid, bsflag, realmoney, paymargin, paygoodsmoney, payoff,Receive, transfermoney, status, breachapplyid, offsetid
    from e_holding h where h.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  delete from e_holding h where h.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  --转合同处理日志
  insert into e_tradeprocesslog_h(logid, tradeno, firmid, operator, processinfo, processtime)
  select logid, tradeno, firmid, operator, processinfo, processtime
    from e_tradeprocesslog l where l.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  delete from e_tradeprocesslog l where l.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  --转合同属性
  insert into e_trade_goodsproperty_h
    (propertyname, tradeno, propertyvalue, propertyTypeID)
  select propertyname, tradeno, propertyvalue, propertyTypeID
    from e_trade_goodsproperty p where p.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  delete from e_trade_goodsproperty p where p.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  --转尾款申请
  insert into e_GoodsMoneyApply_H
    (ID, tradeNO, status,type, CreateTime, ProcessTime)
  select ID, tradeNO, status,type, CreateTime, ProcessTime
    from e_GoodsMoneyApply h where h.tradeNO in
	     (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  delete from e_GoodsMoneyApply l where l.tradeNO in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  --转无损益表
  insert into e_NoOffset_h
    (id, tradeno,createtime)
  select id, tradeno,createtime
    from e_NoOffset p where p.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  delete from e_NoOffset p where p.tradeno in
         (select t.tradeno from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8));
  --转成交合同
  insert into e_trade_h(tradeno, ordertitle, breedid, bfirmid, sfirmid, price, quantity, unit, TradePreTime, trademargin_b, trademargin_s, deliveryday, deliverymargin_b, deliverymargin_s, BuyTradeFee,BuyPayTradeFee,BuyDeliveryFee,BuyPayDeliveryFee,SellTradeFee,SellPayTradeFee,SellDeliveryFee,SellPayDeliveryFee,deliverytype, warehouseid, deliveryaddress, time, remark, status, orderid,TradeType,PayType)
  select tradeno, ordertitle, breedid, bfirmid, sfirmid, price, quantity, unit, TradePreTime, trademargin_b, trademargin_s, deliveryday, deliverymargin_b, deliverymargin_s,BuyTradeFee,BuyPayTradeFee,BuyDeliveryFee,BuyPayDeliveryFee,SellTradeFee,SellPayTradeFee,SellDeliveryFee,SellPayDeliveryFee,deliverytype, warehouseid, deliveryaddress, time, remark, status, orderid,TradeType,PayType
    from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8);
  delete from e_trade t where t.time <= p_EndDate and t.status in (1,2,4,8);
end;
/

