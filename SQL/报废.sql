USE [MiniSuperMarket]
GO
/****** ����:  StoredProcedure [dbo].[allocation]    �ű�����: 09/05/2018 15:35:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[discarding]
	@gbarcode varchar(20),
	@thisnumber decimal(18,2),
	@reason int,
	--@curoutprice decimal(18,2),--����ʱ��ǰ�۸�
	@memo varchar(200),
	@msg varchar(100) output
AS
SET NOCOUNT ON


declare @rowcount int
declare @rowcount1 int
declare @retCode int	--������
declare @errCode int	--������

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
	select @curprice=ISNULL(purchaseprice,0) from MiniSuperMarket.dbo.goodsinventory where gbarcode=@gbarcode--��ǰ��浥��
	--select @rowcount=count(*) from MiniShop.dbo.goodsinventory where gbarcode=@gbarcode--��ǰ�Ƿ��д���Ʒ
		
	--���뱨�ϼ�¼
	insert into MiniSuperMarket.dbo.discardingdetail(gbarcode,quantity,status,curprice,reason,memo) 
		values (@gbarcode,@thisnumber,0,@curprice,@reason,@memo)
		if @@Error <> 0
					begin
						set @msg='[' + @@Error + '���������'
						set @retCode = -1
						goto ExitModule
					end
	update MiniSuperMarket.dbo.goodsinventory set quantity=quantity-@thisnumber where gbarcode=@gbarcode
	if @@Error <> 0
					begin
						set @msg='[' + @@Error + '���������'
						set @retCode = -1
						goto ExitModule
					end

ExitModule:

/*����ع����ύ*/
if @retCode <> 0
begin
	rollback transaction
	set @msg = '����ʧ�� - ' + @msg
	--close curgoodschecks
	--deallocate curgoodschecks

end
else
begin
	commit transaction
	set @msg = '���ϳɹ�'
	--close curgoodschecks
	--deallocate curgoodschecks

end

return @retCode