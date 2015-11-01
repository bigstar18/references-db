create or replace function FN_E_FirmDel
(
    p_FirmID   m_firm.firmid%type--交易商代码
)
return integer is
  /**
  * 删除交易商
  * 返回值： 1 成功
  **/
  v_cnt                number(4); --数字变量
  v_ordercount         number(4); --委托数字变量
  v_tradecount         number(4); --合同数字变量
  v_subordercount      number(4); --议价数字变量
  f_margin               number(15,2); --保证金变量
  f_goodsmoney           number(15,2); --货款变量
  f_transferloss         number(15,2); --转出金额变量
  f_subscription         number(15,2); --诚信保证金变量
  RET_ORDERERROR integer:=-230;--有未结束的委托
  RET_TRADEERROR integer:=-231;--有未结束的合同
  RET_SUBORDERERROR integer:=-232;--有未答复的议价
  RET_MARGINERROR integer:=-233;--交易商保证金不为0
  RET_MONEYERROR integer:=-234;--交易商货款不为0
  RET_TRANERROR integer:=-235;--交易商转出金额不为0
  RET_SUBERROR integer:=-236;--交易商诚信金不为0
begin
   --委托若存在状态不是2:全部成交或者3:已下架 不能注销交易商
   select count(*) into v_ordercount from e_order o where o.firmid=p_FirmID and o.status not in(2,3);
   if(v_ordercount>0)then
   return RET_ORDERERROR;
   end if;
    --合同若存在状态不是8:结束或者1:订单阶段违约 或者2:系统撤销订单或者4:成交阶段违约 不能注销交易商
   select count(*) into v_tradecount from e_trade t where (t.bfirmid=p_FirmID or t.sfirmid=p_FirmID) and t.status not in (1,2,4,8);
   if(v_tradecount>0)then
   return RET_TRADEERROR;
   end if;
   --议价若存在状态为0:等待答复 不能注销交易商
   select count(*) into v_subordercount from e_suborder s where s.subfirmid=p_FirmID and s.status=0;
   if(v_subordercount>0)then
   return RET_SUBORDERERROR;
   end if;

    --该交易商的资金信息若某一项资金值不为0 不能注销交易商
   select f.margin,f.goodsmoney,f.transferloss,f.subscription into f_margin,f_goodsmoney,f_transferloss,f_subscription from e_funds f where f.firmid=p_FirmID;
   if(f_margin>0)then
     return RET_MARGINERROR;
   end if;
   if(f_goodsmoney>0)then
     return RET_MONEYERROR;
   end if;
   if(f_transferloss>0)then
     return RET_TRANERROR;
   end if;
   if(f_subscription>0)then
     return RET_SUBERROR;
   end if;
   /**
   For循环是属于该交易商的模版信息并删除模版属性查询出来。

   for template in (select g.templateid from e_goodstemplate g where g.belongtouser=p_FirmID) loop
       delete from e_goodstemplateproperty tp where tp.templateid=template.templateid;
       end loop;
   --删除该交易商模版信息
   delete from e_goodstemplate te where te.belongtouser=p_FirmID;
    **/
   /**
   For循环是属于该交易商的预备委托信息并删除预备委托属性查询出来。

   for goodsresource in (select r.resourceid from e_goodsresource r where r.firmid=p_FirmID) loop
       delete from e_goodsresourceproperty rp where rp.resourceid=goodsresource.resourceid;
       delete from e_goodsresourcepic gpic where gpic.resourceid=goodsresource.resourceid;
       end loop;
    --删除该交易商预备委托信息
   delete from e_goodsresource r where r.firmid=p_FirmID;
   --删除特殊交易手续费
   delete from e_tradefee f where f.firmid=p_FirmID;
   --删除特殊交收手续费
   delete from e_deliveryfee f where f.firmid=p_FirmID;
   --删除特殊履约保证金
   delete from e_deliverymargin f where f.firmid=p_FirmID;
   --删除特殊交易商权限
   delete from e_traderight f where f.firmid=p_FirmID;
   **/
   --删除推荐店铺
   delete from e_recommendshop f where f.firmid=p_FirmID;
   return 1;
end;
/

