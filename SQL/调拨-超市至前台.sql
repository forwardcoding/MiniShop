USE [MiniSuperMarket]
GO
/****** 对象:  StoredProcedure [dbo].[allocation]    脚本日期: 09/05/2018 15:35:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[allocation]
	@gbarcode varchar(20),
	@thisnumber decimal(18,2),
	--@curoutprice decimal(18,2),--调拨时当前价格
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
declare @memo varchar(200)
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
	select @rowcount=count(*) from MiniShop.dbo.goodsinventory where gbarcode=@gbarcode--当前是否有此商品
	--没有，增加
	if @rowcount=0
	begin
		select @rowcount1=count(*) from MiniShop.dbo.goodsinfo where gbarcode=@gbarcode--当前是否有此商品
		if @rowcount1=0
		begin
			select @gname=gname,@gclass=gclass,@memo=memo,@brand=brand,@rack=rack,@box=box,@minthriftynumber=minthriftynumber,
					@unitname=unitname,@retailprice=retailprice,@picurl=picurl from MiniSuperMarket.dbo.goodsinfo where gbarcode=@gbarcode
			insert into MiniShop.dbo.goodsinfo(gbarcode,gname,gclass,memo,brand,rack,box,minthriftynumber,unitname,retailprice,picurl) values (
				@gbarcode,@gname,@gclass,@memo,@brand,@rack,@box,@minthriftynumber,@unitname,@retailprice,@picurl)
			if @@Error <> 0
					begin
						set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end
			insert into MiniShop.dbo.goodsinventory (gbarcode,quantity,purchaseprice) values (@gbarcode,@thisnumber,@curprice)
			if @@Error <> 0
					begin
						set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end
		end
	end
	else
	begin
		update MiniShop.dbo.goodsinventory set quantity=quantity+@thisnumber where gbarcode=@gbarcode
		if @@Error <> 0
					begin
						set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end
	end
	--插入调拨记录-超市表
	insert into MiniSuperMarket.dbo.allocationdetail(gbarcode,quantity,status,shopid,direction) values (@gbarcode,@thisnumber,0,1,0) --暂时shopid都定为1
		if @@Error <> 0
					begin
						set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end
	--插入调拨记录-前台表
	insert into MiniShop.dbo.allocationdetail(gbarcode,quantity,status,shopid,direction) values (@gbarcode,@thisnumber,0,1,1) --暂时shopid都定为1，direction：0出1入
		if @@Error <> 0
					begin
						set @msg='[' + @@Error + '操作表出错'
						set @retCode = -1
						goto ExitModule
					end
	insert into MiniShop.dbo.purchasedetail(gbarcode,quantity,purchaseprice,status) values (@gbarcode,@thisnumber,@curprice,0)--前台用暂时不考虑加权平均价
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
	set @msg = '调拨失败 - ' + @msg
	--close curgoodschecks
	--deallocate curgoodschecks

end
else
begin
	commit transaction
	set @msg = '调拨成功'
	--close curgoodschecks
	--deallocate curgoodschecks

end

return @retCode