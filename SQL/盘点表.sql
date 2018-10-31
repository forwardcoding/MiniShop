CREATE PROCEDURE [dbo].[Createchecks]
	@date varchar(6),--�̵���
	@msg varchar(100) output
AS
SET NOCOUNT ON
declare @lastmonths varchar(50)
declare @lastmonths1 varchar(20)
declare @gbarcode varchar(20)  --

declare @rowcount int
declare @retCode int	--������
declare @errCode int	--������

set @retCode=0

declare curgoodschecks cursor fast_forward for
select gbarcode from goodsinfo order by gbarcode
--declare @gbarcode varchar(20)
declare @thisperiodin decimal
declare @thisperiodout decimal
declare @lastfinalnumber decimal
declare @thisfinalnumber decimal
declare @lastprice decimal(18,2)
declare @curprice decimal(18,2)
declare @finalamount decimal(18,2)
--select ISNULL(@lastmonths=checkmonths,'201703') from materielchecksmaster where ID=(SELECT MAX(ID) FROM materielchecksmaster)
select @lastmonths1=CheckMonths from checksmaster where ID=(SELECT MAX(ID) FROM checksmaster)
select @lastmonths=ISNULL(@lastmonths1,'201805')
begin transaction
/*���α�*/
OPEN curgoodschecks
if @@Error <> 0
begin
	set @msg='[' + @@Error + '���α�curgoodschecks����'
	set @retCode = -1
	goto ExitModule
end
FETCH NEXT FROM curgoodschecks into @gbarcode
WHILE (@@FETCH_STATUS=0)
begin
	--set @rowcount=(select count(*) from 
	select @lastfinalnumber=ISNULL(finalnumber,0),@lastprice=ISNULL(curprice,0) from checksdetail where CheckMonths=@lastmonths and gbarcode=@gbarcode--�����ڳ���
	select @thisperiodin=ISNULL(SUM(quantity),0) from purchasedetail where datediff(month,builddate,cast(@date+'30' as datetime))=0 and gbarcode=@gbarcode and status=0--�������
	select @thisperiodout=ISNULL(SUM(quantity),0) from salesdetail where datediff(month,builddate,cast(@date+'30' as datetime))=0 and gbarcode=@gbarcode and status=1--���ڳ���
	select @curprice=ISNULL(purchaseprice,0) from goodsinventory where gbarcode=@gbarcode--��ǰ��浥��
	select @thisfinalnumber=@lastfinalnumber+@thisperiodin-@thisperiodout
	insert into checksdetail(CheckMonths,gbarcode,initialnumber,thisperiodin,thisperiodout,finalnumber,initialprice,curprice)
		values(@date,@gbarcode,@lastfinalnumber,@thisperiodin,@thisperiodout,@thisfinalnumber,@lastprice,@curprice)
		if @@Error <> 0
					begin
						set @msg='[' + @@Error + '���������'
						set @retCode = -1
						goto ExitModule
					end
FETCH NEXT FROM curgoodschecks into @gbarcode
end
select @finalamount=sum(quantity*purchaseprice) from goodsinventory
insert into checksmaster(CheckMonths,finalamount) values(@date,@finalamount)--������ĩ�������
ExitModule:

/*����ع����ύ*/
if @retCode <> 0
begin
	rollback transaction
	set @msg = '����ʧ�� - ' + @msg
	close curgoodschecks
	deallocate curgoodschecks

end
else
begin
	commit transaction
	set @msg = '�����ɹ�'
	close curgoodschecks
	deallocate curgoodschecks

end

return @retCode
