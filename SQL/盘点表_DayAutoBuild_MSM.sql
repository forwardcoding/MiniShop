--USE [MiniSuperMarket]
--GO
/****** ����:  StoredProcedure [dbo].[Createchecks]    �ű�����: 08/09/2018 14:56:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DayAutoCreatechecks]--������(�����)
	--@date varchar(6),
	--@msg varchar(100) output
AS
SET NOCOUNT ON
declare @lastdate varchar(50)
declare @lastdate1 varchar(20)
declare @gbarcode varchar(20)  --

declare @rowcount int
declare @retCode int	--������
declare @errCode int	--������

set @retCode=0
declare @date varchar(10)
declare curgoodschecks_autoMSMday cursor fast_forward for
select gbarcode from goodsinfo order by gbarcode
--declare @gbarcode varchar(20)
declare @thisperiodin decimal --�������
declare @thisperiodout decimal --���۳���
declare @thisallocation decimal --��������
declare @thisallocationin decimal --�������
declare @thisdiscardingout decimal --���ϴ������
declare @thissplitout decimal --�����
declare @thissplitin decimal --�����
declare @lastfinalnumber decimal
declare @thisfinalnumber decimal
declare @lastprice decimal(18,2)
declare @curprice decimal(18,2)
declare @finalamount decimal(18,2) --������
declare @curinventory decimal(18,2)--��ǰʵʱ���
declare @recordcount int--�����̵��¼����
--select ISNULL(@lastmonths=checkmonths,'201703') from materielchecksmaster where ID=(SELECT MAX(ID) FROM materielchecksmaster)
--select @date=substring(CONVERT(varchar(100), GETDATE(), 112),1,6)
select @date=CONVERT(varchar(100), dateadd(day,-1,getdate()), 23)--��õ�ǰ����ǰһ��(�˴洢�����趨Ϊÿ��0��1������)
begin transaction
select @recordcount=count(*) from daychecksmaster where checkdate=@date--ɾ�����е��̵��¼���Զ����ɼ�¼
if @recordcount<>0
begin
	delete from daychecksmaster where checkdate=@date
	delete from daychecksdetail where checkdate=@date
end
select @lastdate1=CheckDate from daychecksmaster where ID=(SELECT MAX(ID) FROM daychecksmaster)--����һ��Ҫ��41-45��֮������ȡ����ʱ���ɵ��̵������
--����ȡ����'�ڳ�'ֵ�����ݣ�20180901�޸���bug
select @lastdate=ISNULL(@lastdate1,'2018-09-16')

/*���α�*/
OPEN curgoodschecks_autoMSMday
if @@Error <> 0
begin
	--set @msg='[' + @@Error + '���α�curgoodschecks����'
	set @retCode = -1
	goto ExitModule
end
FETCH NEXT FROM curgoodschecks_autoMSMday into @gbarcode
WHILE (@@FETCH_STATUS=0)
begin
	select @lastfinalnumber=0,@lastprice=0
	select @lastfinalnumber=0
	select @thisperiodin=0
	select @thisperiodout=0
	select @curprice=0
	select @thisallocation=0
	select @thisallocationin=0
	select @thisdiscardingout=0
	select @thissplitout=0
	select @thissplitin=0
	select @thisfinalnumber=0
	--20180928�ĳ�ȡ���¡���������������ĩʵ�ʿ����
	--select @lastfinalnumber=ISNULL(currinventorynumber,0),@lastprice=ISNULL(curprice,0) from checksdetail where CheckMonths=@lastmonths and gbarcode=@gbarcode--�����ڳ���
	--select @lastfinalnumber=ISNULL(finalnumber,0),@lastprice=ISNULL(curprice,0) from daychecksdetail where CheckDate=@lastdate and gbarcode=@gbarcode--�����ڳ���
	select @lastfinalnumber=ISNULL(currinventorynumber,0),@lastprice=ISNULL(curprice,0) from daychecksdetail where CheckDate=@lastdate and gbarcode=@gbarcode--�����ڳ���
	select @thisperiodin=ISNULL(SUM(quantity),0) from purchasedetail where datediff(day,builddate,cast(@date + ' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=0--�������
	select @thisperiodout=ISNULL(SUM(quantity),0) from salesdetail where datediff(day,builddate,cast(@date+' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=1--���ڳ���
	select @curprice=ISNULL(purchaseprice,0),@curinventory=ISNULL(quantity,0) from goodsinventory where gbarcode=@gbarcode--��ǰ��浥��
	--20180915�޸ģ����������ͳ��ֿ�����direction��Ϊ���֣�0-����1-��,�����ݿ�����ֶηֿ�
	select @thisallocation=ISNULL(SUM(quantity),0) from allocationdetail where datediff(day,happenddate,cast(@date+' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=0 and direction=0--���ڵ�������
	select @thisallocationin=ISNULL(SUM(quantity),0) from allocationdetail where datediff(day,happenddate,cast(@date+' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=0 and direction=1--���ڵ������
	select @thisdiscardingout=ISNULL(SUM(quantity),0) from discardingdetail where datediff(day,submitdate,cast(@date+' 00:00:01' as datetime))=0 and gbarcode=@gbarcode and status=0 --���ڱ��ϴ������
	--20180921����������
	select @thissplitout=ISNULL(SUM(tofitquantity),0) from splitdetail where datediff(day,submitdate,cast(@date+' 00:00:01' as datetime))=0 and tofitgbarcode=@gbarcode and status=0 --���ڲ����
	select @thissplitin=ISNULL(SUM(fitquantity),0) from splitdetail where datediff(day,submitdate,cast(@date+' 00:00:01' as datetime))=0 and fitgbarcode=@gbarcode and status=0 --���ڲ����
	select @thisfinalnumber=@lastfinalnumber+@thisperiodin-@thisperiodout-@thisallocation+@thisallocationin-@thisdiscardingout-@thissplitout+@thissplitin
	insert into daychecksdetail(CheckDate,gbarcode,initialnumber,thisperiodin,thisperiodout,finalnumber,initialprice,curprice,thisallocationout,thisallocationin,thisdiscardingout,currinventorynumber,thissplitout,thissplitin)
		values(@date,@gbarcode,@lastfinalnumber,@thisperiodin,@thisperiodout,@thisfinalnumber,@lastprice,@curprice,@thisallocation,@thisallocationin,@thisdiscardingout,@curinventory,@thissplitout,@thissplitin)
		if @@Error <> 0
					begin
						--set @msg='[' + @@Error + '���������'
						set @retCode = -1
						goto ExitModule
					end
FETCH NEXT FROM curgoodschecks_autoMSMday into @gbarcode
end
select @finalamount=sum(quantity*purchaseprice) from goodsinventory
insert into daychecksmaster(CheckDate,finalamount) values(@date,@finalamount)--������ĩ�������
ExitModule:

/*����ع����ύ*/
if @retCode <> 0
begin
	rollback transaction
	--set @msg = '����ʧ�� - ' + @msg
	close curgoodschecks_autoMSMday
	deallocate curgoodschecks_autoMSMday

end
else
begin
	commit transaction
	--set @msg = '�����ɹ�'
	close curgoodschecks_autoMSMday
	deallocate curgoodschecks_autoMSMday

end

return @retCode
