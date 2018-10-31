CREATE FUNCTION dbo.SalesProfit
(
	@startdate varchar(10),
	@enddate varchar(10)
)
RETURNS @SalesProfit TABLE
(
	[ID] [int] IDENTITY (1, 1) NOT NULL ,
	[curdate] varchar(10),
	[turnover] decimal(18,2),--营业额
	[profit] decimal(18,2),--毛利润
	[profitrate] decimal(18,2)--利润率
) with ENCRYPTION
AS
BEGIN

declare @Item varchar(20)
declare @currentdayturnover decimal(18,2)
declare @profit decimal(18,2)
declare @profitrate decimal(18,2)
declare cursales cursor fast_forward for
select distinct substring(convert(varchar,builddate,120),1,10) as curdate from salesmaster --convert(varchar,builddate,120)转换为yyyy-mm-dd的格式
	where builddate between cast(@startdate+' 0:00:00' as datetime) and cast(@enddate+' 23:59:59' as datetime) order by curdate desc

declare @empid int
declare @currentdate varchar(10)


/*打开游标*/

OPEN cursales
FETCH NEXT FROM cursales into @currentdate
WHILE (@@FETCH_STATUS=0)
begin
	select @currentdayturnover=sum(paymoney) from salesmaster where datediff(day,builddate,cast(@currentdate+' 0:00:00' as datetime))=0 and status=0--正常单汇总，不包括取消单
	select @profit=sum(price*quantity-curprice*quantity) from salesdetail where datediff(day,builddate,cast(@currentdate+' 0:00:00' as datetime))=0 and status=1--正常单汇总，不包括取消单
	select @profitrate=round(@profit/@currentdayturnover,2)*100
	insert @SalesProfit (curdate,turnover,profit,profitrate)
			values (@currentdate,@currentdayturnover,@profit,@profitrate)
FETCH NEXT FROM cursales into @currentdate
end

close cursales
deallocate cursales
RETURN 
END