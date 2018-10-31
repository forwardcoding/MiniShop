CREATE FUNCTION dbo.SalesProfit
(
	@startdate varchar(10),
	@enddate varchar(10)
)
RETURNS @SalesProfit TABLE
(
	[ID] [int] IDENTITY (1, 1) NOT NULL ,
	[curdate] varchar(10),
	[turnover] decimal(18,2),--Ӫҵ��
	[profit] decimal(18,2),--ë����
	[profitrate] decimal(18,2)--������
) with ENCRYPTION
AS
BEGIN

declare @Item varchar(20)
declare @currentdayturnover decimal(18,2)
declare @profit decimal(18,2)
declare @profitrate decimal(18,2)
declare cursales cursor fast_forward for
select distinct substring(convert(varchar,builddate,120),1,10) as curdate from salesmaster --convert(varchar,builddate,120)ת��Ϊyyyy-mm-dd�ĸ�ʽ
	where builddate between cast(@startdate+' 0:00:00' as datetime) and cast(@enddate+' 23:59:59' as datetime) order by curdate desc

declare @empid int
declare @currentdate varchar(10)


/*���α�*/

OPEN cursales
FETCH NEXT FROM cursales into @currentdate
WHILE (@@FETCH_STATUS=0)
begin
	select @currentdayturnover=sum(paymoney) from salesmaster where datediff(day,builddate,cast(@currentdate+' 0:00:00' as datetime))=0 and status=0--���������ܣ�������ȡ����
	select @profit=sum(price*quantity-curprice*quantity) from salesdetail where datediff(day,builddate,cast(@currentdate+' 0:00:00' as datetime))=0 and status=1--���������ܣ�������ȡ����
	select @profitrate=round(@profit/@currentdayturnover,2)*100
	insert @SalesProfit (curdate,turnover,profit,profitrate)
			values (@currentdate,@currentdayturnover,@profit,@profitrate)
FETCH NEXT FROM cursales into @currentdate
end

close cursales
deallocate cursales
RETURN 
END