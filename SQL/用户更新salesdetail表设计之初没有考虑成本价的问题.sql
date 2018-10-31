create procedure [dbo].[updatecurprice]--�û�����salesdetail�����֮��û�п��ǳɱ��۵�����
	
AS
declare @retCode int
declare @seqno varchar(50)
declare @gbarcode varchar(50)
declare @curprice decimal(18,2)
declare @id int
set @retCode=1
begin transaction
begin
	
			declare cursales1 cursor fast_forward for select ID,seqno,gbarcode from salesdetail
			OPEN cursales1
			if @@Error <> 0
			begin
				--set @msg='[' + @@Error + '���α�curMeterData����'
				set @retCode = -1
				goto ExitModule
			end
			FETCH NEXT FROM cursales1 into @id,@seqno,@gbarcode
			WHILE (@@FETCH_STATUS=0)
				begin
					select @curprice=purchaseprice from goodsinventory where gbarcode=@gbarcode
					update salesdetail set curprice=@curprice where ID=@id
				FETCH NEXT FROM cursales1 into @id,@seqno,@gbarcode
				end
			close cursales1
			deallocate cursales1
end

ExitModule:
if @retCode<>1
begin
	rollback transaction
	
end
else
begin
	commit transaction
	
end
select @retCode