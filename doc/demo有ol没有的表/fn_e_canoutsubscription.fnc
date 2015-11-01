create or replace function FN_E_CanOutSubscription(p_firmid varchar2, --交易商代码
                                                   p_lock   number --是否上锁 1:上锁 0：不上锁
                                                   ) return number
/***
  * 获取可出诚信保证金
  * 返回值：可出诚信保证金
  ****/
 is
  v_LeastSubscription     number(15, 2); --最少应该保留的诚信保障金
  v_SumSubscription       number(15, 2); --订单全部违约所需诚信保障金
  v_CanOut                number(15, 2); --可出诚信保障金
  v_UnTradecnt            number(10); --未成交的委托数量
  v_OneTradeMargin        number(15, 2); --单笔委托所需诚信保障金
  v_OrderHoldSubscription number(15, 2); --委托占用的诚信保障金
begin

  select a.totalOrder + b.totalSubOrder
    into v_UnTradecnt
    from -- 委托状态 0：未成交 1：部分成交 2：全部成交 3：已下架 11：待后台管理员审核
         (select count(*) totalOrder
            from E_order o
           where o.firmid = p_firmid
             and (o.status = 0 or o.status = 1 or o.status = 11)
             and o.ispaymargin = 'N' --没有支付保证金
             and o.pledgeflag = 0) a, --不是卖仓单
         --议价表状态 0：等待挂牌方答复 并且是没有交保证金的
         (select count(*) totalSubOrder from(
           select case
                    when o.bsflag = 'B' then
                     t.deliverymargin_s
                    else
                     t.deliverymargin_b
                  end as margin,t.frozenmargin
             from E_suborder t, E_order o
             where t.subFirmID = p_firmid and t.orderid=o.orderid and t.status = 0) where margin!=frozenmargin) b;

  --计算全部订单违约所需诚信保证金
  select sum(trademargin)
    into v_SumSubscription
    from (select case
                   when r.bsflag = 'B' then
                    t.trademargin_b
                   else
                    t.trademargin_s
                 end as trademargin
            from E_reserve r, E_trade t
           where r.tradeno = t.tradeno
             and r.firmid = p_firmid
             and r.status = 0);

  select x.runtimevalue
    into v_OneTradeMargin
    from E_systemprops x
   where x.key = 'OneTradeMargin'; --单笔委托所需诚信保障金
  --计算委托占用的诚信保障金
  v_OrderHoldSubscription := v_UnTradecnt * v_OneTradeMargin;

  if v_SumSubscription is NULL then
    v_SumSubscription := 0;
  end if;

  if v_OrderHoldSubscription is NULL then
    v_OrderHoldSubscription := 0;
  end if;

  v_LeastSubscription := v_OrderHoldSubscription + v_SumSubscription;

  if (p_lock = 1) then
    select f.subscription - v_LeastSubscription
      into v_CanOut
      from E_funds f
     where firmid = p_firmid
       for update;
  else
    select f.subscription - v_LeastSubscription
      into v_CanOut
      from E_funds f
     where firmid = p_firmid;
  end if;

  if (v_CanOut < 0) then
    v_CanOut := 0;
  end if;

  return v_CanOut;
end;
/

