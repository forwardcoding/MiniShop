USE [MiniSuperMarket]
GO
/****** 对象:  StoredProcedure [dbo].[Createchecks]    脚本日期: 09/28/2018 22:00:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Createchecks]--超市用
	@date varchar(6),--盘点月
	@msg varchar(100) output
AS
SET NOCOUNT ON
declare @lastmonths varchar(50)
declare @lastmonths1 varchar(20)
declare @gbarcode varchar(20)  --

declare @rowcount int
declare @retCode int	--返回码
declare @errCode int	--错误码

set @retCode=0

declare curgoodschecks cursor fast_forward for
select gbarcode from goodsinfo order by gbarcode
--declare @gbarcode varchar(20)
declare @thisperiodin decimal --进货入库
declare @thisperiodout decimal --销售出库
declare @thisallocation decimal --调拨出库
declare @thisallocationin decimal --调拨入库
declare @thisdiscardingout decimal --报废处理出库
declare @thissplitout decimal --拆包出
declare @thissplitin decimal --拆包入
declare @lastfinalnumber decimal
declare @thisfinalnumber decimal
declare @lastprice decimal(18,2)
declare @curprice decimal(18,2)
declare @finalamount decimal(18,2) --账面数
declare @curinventory decimal(18,2)--当前实时库存
--select ISNULL(@lastmonths=checkmonths,'201703') from materielchecksmaster where ID=(SELECT MAX(ID) FROM materielchecksmaster)
select @lastmonths1=CheckMonths from checksmaster where ID=(SELECT MAX(ID) FROM checksmaster)
select @lastmonths=ISNULL(@lastmonths1,'201805')
begin transaction
/*打开游标*/
OPEN curgoodschecks
if @@Error <> 0
begin
	set @msg='[' + @@Error + '打开游标curgoodschecks出错'
	set @retCode = -1
	goto ExitModule
end
FETCH NEXT FROM curgoodschecks into @gbarcode
WHILE (@@FETCH_STATUS=0)
begin
	--set @rowcount=(select count(*) from 
	select @lastfinalnumber=0,@lastprice=0
	select @lastfinalnumber=0
	select @thisperiodin=0
	select @thisperiodout=0
	select @curprice=0
	select @thisallocation=0
	select @thisallocationin=0
	select @thisdiscardingout=0
	select @thissplitout=0
	select @thissplitin=0
	select @thisfinalnumber=0
	
	--set @rowcount=(select count(*) from 
	--20180928改成取上月‘账面库存数’即期末实际库存数
	--select @lastfinalnumber=ISNULL(finalnumber,0),@lastprice=ISNULL(curprice,0) from checksdetail where CheckMonths=@lastmonths and gbarcode=@gbarcode--本月期初数
	select @lastfinalnumber=ISNULL(currinventorynumber,0),@lastprice=ISNULL(curprice,0) from checksdetail where CheckMonths=@lastmonths and gbarcode=@gbarcode--本月期初数
	select @thisperiodin=ISNULL(SUM(quantity),0) from purchasedetail where datediff(month,builddate,cast(@date+'30' as datetime))=0 and gbarcode=@gbarcode and status=0--本期入库
	select @thisperiodout=ISNULL(SUM(quantity),0) from salesdetail where datediff(month,builddate,cast(@date+'30' as datetime))=0 and gbarcode=@gbarcode and status=1--本期出库
	select @curprice=ISNULL(purchaseprice,0),@curinventory=ISNULL(quantity,0) from goodsinventory where gbarcode=@gbarcode--当前库存单价
	--20180915修改，将调拨进和出分开，以direction作为区分，0-出，1-入,因数据库表中字段分开
	select @thisallocation=ISNULL(SUM(quantity),0) from allocationdetail where datediff(month,happenddate,cast(@date+'30' as datetime))=0 and gbarcode=@gbarcode and status=0 and direction=0--本期调拨出库
	select @thisallocationin=ISNULL(SUM(quantity),0) from allocationdetail where datediff(month,happenddate,cast(@date+'30' as datetime))=0 and gbarcode=@gbarcode and status=0 and direction=1--本期调拨入库
	select @thisdiscardingout=ISNULL(SUM(quantity),0) from discardingdetail where datediff(month,submitdate,cast(@date+'30' as datetime))=0 and gbarcode=@gbarcode and status=0 --本期报废处理出库
	--20180921加入拆包问题
	select @thissplitout=ISNULL(SUM(tofitquantity),0) from splitdetail where datediff(month,submitdate,cast(@date+'30' as datetime))=0 and tofitgbarcode=@gbarcode and status=0 --本期拆包出
	select @thissplitin=ISNULL(SUM(fitquantity),0) from splitdetail where datediff(month,submitdate,cast(@date+'30' as datetime))=0 and fitgbarcode=@gbarcode and status=0 --本期拆包入
	select @thisfinalnumber=@lastfinalnumber+@thisperiodin-@thisperiodout-@thisallocation+@thisallocationin-@thisdiscardingout
	insert into checksdetail(CheckMonths,gbarcode,initialnumber,thisperiodin,thisperiodout,finalnumber,initialprice,curprice,thisallocationout,thisallocationin,thisdiscardingout,currinventorynumber,thissplitout,thissplitin)
		values(@date,@gbarcode,@lastfinalnumber,@thisperiodin,@thisperiodout,@thisfinalnumber,@lastprice,@curprice,@thisallocation,@thisallocationin,@thisdiscardingout,@curinventory,@thissplitout,@thissplitin)
		if @@Error <> 0
					begin
						set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end
FETCH NEXT FROM curgoodschecks into @gbarcode
end
select @finalamount=sum(quantity*purchaseprice) from goodsinventory
insert into checksmaster(CheckMonths,finalamount) values(@date,@finalamount)--本期期末账面余额
ExitModule:

/*事务回滚或提交*/
if @retCode <> 0
begin
	rollback transaction
	set @msg = '创建失败 - ' + @msg
	close curgoodschecks
	deallocate curgoodschecks

end
else
begin
	commit transaction
	set @msg = '创建成功'
	close curgoodschecks
	deallocate curgoodschecks

end

return @retCode
