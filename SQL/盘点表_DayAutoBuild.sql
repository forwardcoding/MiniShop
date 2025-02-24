USE [MiniShop]
GO
/****** 对象:  StoredProcedure [dbo].[DayAutoCreatechecks]    脚本日期: 09/17/2018 08:18:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DayAutoCreatechecks]--前台用(没有报废功能)
	--@date varchar(6),
	--@msg varchar(100) output
AS
SET NOCOUNT ON
declare @lastdate varchar(50)
declare @lastdate1 varchar(20)
declare @gbarcode varchar(20)  --

declare @rowcount int
declare @retCode int	--返回码
declare @errCode int	--错误码

set @retCode=0
declare @date varchar(10)
declare curgoodschecks_autoday cursor fast_forward for
select gbarcode from goodsinfo order by gbarcode
--declare @gbarcode varchar(20)
declare @thisperiodin decimal --进货入库
declare @thisperiodout decimal --销售出库
declare @thisallocation decimal --调拨出库
declare @thisallocationin decimal --调拨入库
declare @lastfinalnumber decimal
declare @thisfinalnumber decimal
declare @lastprice decimal(18,2)
declare @curprice decimal(18,2)
declare @finalamount decimal(18,2) --账面数
declare @curinventory decimal(18,2)--当前实时库存
declare @recordcount int--已有盘点记录行数
--select ISNULL(@lastmonths=checkmonths,'201703') from materielchecksmaster where ID=(SELECT MAX(ID) FROM materielchecksmaster)
--select @date=substring(CONVERT(varchar(100), GETDATE(), 112),1,6)
select @date=CONVERT(varchar(100), dateadd(day,-1,getdate()), 23)--获得当前日期前一天(此存储过程设定为每天0点2分运行)
begin transaction
select @recordcount=count(*) from daychecksmaster where checkdate=@date--删除已有的盘点记录以自动生成记录
if @recordcount<>0
begin
	delete from daychecksmaster where checkdate=@date
	delete from daychecksdetail where checkdate=@date
end
select @lastdate1=CheckDate from daychecksmaster where ID=(SELECT MAX(ID) FROM daychecksmaster)--本行一定要在41-45行之后否则会取试盘时生成的盘点表数据
--导致取不到'期初'值等数据，20180901修复此bug
select @lastdate=ISNULL(@lastdate1,'2018-09-16')

/*打开游标*/
OPEN curgoodschecks_autoday
if @@Error <> 0
begin
	--set @msg='[' + @@Error + '打开游标curgoodschecks出错'
	set @retCode = -1
	goto ExitModule
end
FETCH NEXT FROM curgoodschecks_autoday into @gbarcode
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
	--select @thisdiscardingout=0
	--select @thissplitout=0
	--select @thissplitin=0
	select @thisfinalnumber=0
	
	--set @rowcount=(select count(*) from 
	--20180928改成取上月‘账面库存数’即期末实际库存数
	--select @lastfinalnumber=ISNULL(finalnumber,0),@lastprice=ISNULL(curprice,0) from checksdetail where CheckMonths=@lastmonths and gbarcode=@gbarcode--本月期初数
	--select @lastfinalnumber=ISNULL(currinventorynumber,0),@lastprice=ISNULL(curprice,0) from checksdetail where CheckMonths=@lastmonths and gbarcode=@gbarcode--本月期初数
	--select @lastfinalnumber=ISNULL(finalnumber,0),@lastprice=ISNULL(curprice,0) from daychecksdetail where CheckDate=@lastdate and gbarcode=@gbarcode--本月期初数
	select @lastfinalnumber=ISNULL(currinventorynumber,0),@lastprice=ISNULL(curprice,0) from daychecksdetail where CheckDate=@lastdate and gbarcode=@gbarcode--本月期初数
	--select @thisperiodin=ISNULL(SUM(quantity),0) from purchasedetail where datediff(day,builddate,cast(@date+ ' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=0--本期入库(前台无直接进货功能)
	select @thisperiodout=ISNULL(SUM(quantity),0) from salesdetail where datediff(day,builddate,cast(@date+ ' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=1--本期出库
	select @curprice=ISNULL(purchaseprice,0),@curinventory=ISNULL(quantity,0) from goodsinventory where gbarcode=@gbarcode--当前库存单价
	--20180915修改，将调拨进和出分开，以direction作为区分，0-出，1-入,因数据库表中字段分开
	select @thisallocation=ISNULL(SUM(quantity),0) from allocationdetail where datediff(day,happenddate,cast(@date+ ' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=0 and direction=0--本期调拨出库
	select @thisallocationin=ISNULL(SUM(quantity),0) from allocationdetail where datediff(day,happenddate,cast(@date+ ' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=0 and direction=1--本期调拨入库
	--select @thisfinalnumber=@lastfinalnumber+@thisperiodin-@thisperiodout-@thisallocation+@thisallocationin
	select @thisfinalnumber=@lastfinalnumber-@thisperiodout-@thisallocation+@thisallocationin
	insert into daychecksdetail(CheckDate,gbarcode,initialnumber,thisperiodout,finalnumber,initialprice,curprice,thisallocationout,thisallocationin,currinventorynumber)
		values(@date,@gbarcode,@lastfinalnumber,@thisperiodout,@thisfinalnumber,@lastprice,@curprice,@thisallocation,@thisallocationin,@curinventory)
		if @@Error <> 0
					begin
						--set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end
FETCH NEXT FROM curgoodschecks_autoday into @gbarcode
end
select @finalamount=sum(quantity*purchaseprice) from goodsinventory
insert into daychecksmaster(CheckDate,finalamount) values(@date,@finalamount)--本期期末账面余额
ExitModule:

/*事务回滚或提交*/
if @retCode <> 0
begin
	rollback transaction
	--set @msg = '创建失败 - ' + @msg
	close curgoodschecks_autoday
	deallocate curgoodschecks_autoday

end
else
begin
	commit transaction
	--set @msg = '创建成功'
	close curgoodschecks_autoday
	deallocate curgoodschecks_autoday

end

return @retCode
