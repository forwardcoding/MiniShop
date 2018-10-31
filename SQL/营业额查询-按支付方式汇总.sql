CREATE FUNCTION dbo.turnoverreport
(
	@startdate varchar(10),
	@enddate varchar(10)
)
RETURNS @turnoverreport TABLE
(
	[ID] [int] IDENTITY (1, 1) NOT NULL ,
	[currentdate] datetime,
	[totalmoney] decimal(18,2),--
	[cashpay] decimal(18,2),--
	[weixinpay] decimal(18,2),--
	[alipay] decimal(18,2),--
	[cardpay] decimal(18,2),--
	[jdpay] decimal(18,2),--
	[otherpay] decimal(18,2)--
) --with ENCRYPTION
AS
BEGIN
declare @i int
declare @currentdate datetime
declare @days int
declare @totalmoney decimal(18,2)
declare @cashpay decimal(18,2)
declare @weixinpay decimal(18,2)
declare @alipay decimal(18,2)
declare @cardpay decimal(18,2)
declare @jdpay decimal(18,2)
declare @otherpay decimal(18,2)

	--set language N'Simplified Chinese'
	select @days=(select datediff(day,cast(@startdate as datetime),cast(@enddate as datetime))) 
	select @currentdate=cast(@startdate as datetime)
	select @i=1
	while(@i<=@days+1)
	begin	
			select @totalmoney=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0
			select @cashpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=1--现金
			select @weixinpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=2--微信
			select @alipay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=3--支付宝
			select @cardpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=5--银行卡
			select @jdpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=4--京东钱包
			select @otherpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=6--京东钱包
		insert @turnoverreport (currentdate,totalmoney,cashpay,weixinpay,alipay,cardpay,jdpay,otherpay)
			values (@currentdate,@totalmoney,@cashpay,@weixinpay,@alipay,@cardpay,@jdpay,@otherpay)
	
		select @currentdate=dateadd(day,1,@currentdate)
		select @i=@i+1
	end

	
	
RETURN 
END