USE [MiniSuperMarket]
GO
/****** ����:  UserDefinedFunction [dbo].[turnoverreport]    �ű�����: 09/29/2018 10:47:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[turnoverreport]
(
	@startdate varchar(10),
	@enddate varchar(10)
)
RETURNS @turnoverreport TABLE
(
	[ID] [int] IDENTITY (1, 1) NOT NULL ,
	[currentdate] datetime,
	[item] varchar(50),
	[shifts] int,
	[emp] int,
	[shiftstotalmoney] decimal(18,2),
	[emptotalmoney] decimal(18,2),
	[totalmoney] decimal(18,2),--
	[cashpay] decimal(18,2),--
	[weixinpay] decimal(18,2),--
	[alipay] decimal(18,2),--
	[cardpay] decimal(18,2),--
	[jdpay] decimal(18,2),--
	[otherpay] decimal(18,2),--
	[ICpay] decimal(18,2)--
) --with ENCRYPTION
AS
BEGIN
declare @i int
declare @currentdate datetime
declare @days int
declare @totalmoney decimal(18,2)
declare @curshifts_totalmoney decimal(18,2)
declare @curemp_totalmoney decimal(18,2)
declare @cashpay decimal(18,2)
declare @weixinpay decimal(18,2)
declare @alipay decimal(18,2)
declare @cardpay decimal(18,2)
declare @jdpay decimal(18,2)
declare @otherpay decimal(18,2)
declare @ICpay decimal(18,2)
declare @staffshifts varchar(10)--20180728�޸ģ���ʱ�����α�ķ�ʽȡֵ
declare @emp int
declare @cur_emp int

declare @shiftsname varchar(50)
declare @shiftsid int

	--set language N'Simplified Chinese'
	select @days=(select datediff(day,cast(@startdate as datetime),cast(@enddate as datetime))) 
	select @currentdate=cast(@startdate as datetime)
	select @i=1
	while(@i<=@days+1)
	begin	
			declare curshifts cursor fast_forward for
				select ID,shiftsname from staffshifts order by ID
			OPEN curshifts
			FETCH NEXT FROM curshifts into @shiftsid,@shiftsname
			declare curemp cursor fast_forward for
				select distinct emp from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and staffshifts=@shiftsid
			OPEN curemp
				FETCH NEXT FROM curemp into @cur_emp 
				select @curemp_totalmoney=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and staffshifts=@shiftsid and emp=@cur_emp
				select @cashpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=1 and staffshifts=@shiftsid and emp=@cur_emp--�ֽ�
				select @weixinpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=2 and staffshifts=@shiftsid and emp=@cur_emp--΢��
				select @alipay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=3 and staffshifts=@shiftsid and emp=@cur_emp--֧����
				select @cardpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=5 and staffshifts=@shiftsid and emp=@cur_emp--���п�
				select @jdpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=4 and staffshifts=@shiftsid and emp=@cur_emp--����Ǯ��
				select @otherpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=6 and staffshifts=@shiftsid and emp=@cur_emp--����Ǯ��
				select @ICpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=7 and staffshifts=@shiftsid and emp=@cur_emp--���IC��
			--����С��	
			insert @turnoverreport (currentdate,item,shifts,emp,emptotalmoney,cashpay,weixinpay,alipay,cardpay,jdpay,otherpay,ICpay)
			values (@currentdate,'Ա��С��',@shiftsid,@cur_emp,@curemp_totalmoney,@cashpay,@weixinpay,@alipay,@cardpay,@jdpay,@otherpay,@ICpay)
			FETCH NEXT FROM curemp into @cur_emp
			select @curshifts_totalmoney=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and staffshifts=@shiftsid
			select @cashpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=1 and staffshifts=@shiftsid--�ֽ�
				select @weixinpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=2 and staffshifts=@shiftsid--΢��
				select @alipay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=3 and staffshifts=@shiftsid--֧����
				select @cardpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=5 and staffshifts=@shiftsid--���п�
				select @jdpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=4 and staffshifts=@shiftsid--����Ǯ��
				select @otherpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=6 and staffshifts=@shiftsid--����Ǯ��
				select @ICpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=7 and staffshifts=@shiftsid--���IC��
			--���С��
			insert @turnoverreport (currentdate,item,shifts,shiftstotalmoney,cashpay,weixinpay,alipay,cardpay,jdpay,otherpay,ICpay)
			values (@currentdate,'���С��',@shiftsid,@curshifts_totalmoney,@cashpay,@weixinpay,@alipay,@cardpay,@jdpay,@otherpay,@ICpay)
			close curemp
			deallocate curemp
			--ȫ��ϼ�
			select @totalmoney=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0
			select @cashpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=1--�ֽ�
			select @weixinpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=2--΢��
			select @alipay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=3--֧����
			select @cardpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=5--���п�
			select @jdpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=4--����Ǯ��
			select @otherpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=6--����Ǯ��
			select @ICpay=ISNULL(sum(paymoney),0) from salesmaster where datediff(day,builddate,@currentdate)=0 and status=0 and paymethod=7--���IC��
		insert @turnoverreport (currentdate,item,totalmoney,cashpay,weixinpay,alipay,cardpay,jdpay,otherpay,ICpay)
			values (@currentdate,'ȫ��С��',@totalmoney,@cashpay,@weixinpay,@alipay,@cardpay,@jdpay,@otherpay,@ICpay)
		FETCH NEXT FROM curshifts into @shiftsid,@shiftsname
		close curshifts
			deallocate curshifts
		select @currentdate=dateadd(day,1,@currentdate)
		select @i=@i+1
	end

	
	
RETURN 
END