USE [MiniSuperMarket]
GO
/****** 对象:  StoredProcedure [dbo].[allocation]    脚本日期: 09/05/2018 15:35:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[discarding]
	@gbarcode varchar(20),
	@thisnumber decimal(18,2),
	@reason int,
	--@curoutprice decimal(18,2),--调拨时当前价格
	@memo varchar(200),
	@msg varchar(100) output
AS
SET NOCOUNT ON


declare @rowcount int
declare @rowcount1 int
declare @retCode int	--返回码
declare @errCode int	--错误码

set @retCode=0

declare @gname varchar(200)
declare @gclass int
--declare @memo varchar(200)
declare @brand varchar(50)
declare @rack int
declare @box int
declare @minthriftynumber int
declare @unitname int
declare @retailprice decimal(18,2)
declare @picurl varchar(500)
declare @curprice decimal(18,2)

begin transaction
	select @curprice=ISNULL(purchaseprice,0) from MiniSuperMarket.dbo.goodsinventory where gbarcode=@gbarcode--当前库存单价
	--select @rowcount=count(*) from MiniShop.dbo.goodsinventory where gbarcode=@gbarcode--当前是否有此商品
		
	--插入报废记录
	insert into MiniSuperMarket.dbo.discardingdetail(gbarcode,quantity,status,curprice,reason,memo) 
		values (@gbarcode,@thisnumber,0,@curprice,@reason,@memo)
		if @@Error <> 0
					begin
						set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end
	update MiniSuperMarket.dbo.goodsinventory set quantity=quantity-@thisnumber where gbarcode=@gbarcode
	if @@Error <> 0
					begin
						set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end

ExitModule:

/*事务回滚或提交*/
if @retCode <> 0
begin
	rollback transaction
	set @msg = '报废失败 - ' + @msg
	--close curgoodschecks
	--deallocate curgoodschecks

end
else
begin
	commit transaction
	set @msg = '报废成功'
	--close curgoodschecks
	--deallocate curgoodschecks

end

return @retCode