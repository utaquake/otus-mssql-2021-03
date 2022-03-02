/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

insert Purchasing.Suppliers(
 SupplierName,SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryCityID,PostalCityID
,PaymentDays,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1,PostalAddressLine1,PostalPostalCode,LastEditedBy,DeliveryPostalCode
)select   top 5   'test'+cast(SupplierID as varchar(10))  ,SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryCityID,PostalCityID
,PaymentDays,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1,PostalAddressLine1,PostalPostalCode,LastEditedBy,DeliveryPostalCode
from Purchasing.Suppliers

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/
 
delete Purchasing.Suppliers where SupplierID = 21


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update Purchasing.Suppliers 
set SupplierName = 'test20'
where SupplierID = 20

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
;with cte 
as(
select top 1* from Sales.Customers)
merge Sales.Customers t
using(select 
             99 as CustomerID
            ,'test' as CustomerName
            ,BillToCustomerID
            ,CustomerCategoryID
            ,PrimaryContactPersonID
            ,DeliveryMethodID
            ,DeliveryCityID
            ,PostalCityID
            ,AccountOpenedDate
            ,StandardDiscountPercentage
            ,IsStatementSent
            ,IsOnCreditHold
            ,PaymentDays
            ,PhoneNumber
            ,FaxNumber
            ,WebsiteURL
            ,DeliveryAddressLine1
            ,DeliveryPostalCode
            ,PostalAddressLine1
            ,PostalPostalCode
            ,LastEditedBy from cte)s
			on s.CustomerID = t.CustomerID
when matched and exists(
select       t.CustomerName,t.BillToCustomerID,t.CustomerCategoryID,t.PrimaryContactPersonID,t.DeliveryMethodID
            ,t.DeliveryCityID,t.PostalCityID,t.AccountOpenedDate,t.StandardDiscountPercentage,t.IsStatementSent
            ,t.IsOnCreditHold,t.PaymentDays,t.PhoneNumber,t.FaxNumber,t.WebsiteURL,t.DeliveryAddressLine1
            ,t.DeliveryPostalCode,t.PostalAddressLine1,t.PostalPostalCode,t.LastEditedBy
except
select
             s.CustomerName as CustomerName,s.BillToCustomerID,s.CustomerCategoryID,s.PrimaryContactPersonID,s.DeliveryMethodID
            ,s.DeliveryCityID,s.PostalCityID,s.AccountOpenedDate,s.StandardDiscountPercentage,s.IsStatementSent
            ,s.IsOnCreditHold,s.PaymentDays,s.PhoneNumber,s.FaxNumber,s.WebsiteURL,s.DeliveryAddressLine1
            ,s.DeliveryPostalCode,s.PostalAddressLine1,s.PostalPostalCode,s.LastEditedBy
			)
then update set
             t.CustomerName = s.CustomerName
            ,t.BillToCustomerID = s.BillToCustomerID
            ,t.CustomerCategoryID = s.CustomerCategoryID
            ,t.PrimaryContactPersonID = s.PrimaryContactPersonID
            ,t.DeliveryMethodID = s.DeliveryMethodID
            ,t.DeliveryCityID = s.DeliveryCityID
            ,t.PostalCityID = s.PostalCityID
            ,t.AccountOpenedDate = s.AccountOpenedDate
            ,t.StandardDiscountPercentage = s.StandardDiscountPercentage
            ,t.IsStatementSent = s.IsStatementSent
            ,t.IsOnCreditHold = s.IsOnCreditHold
            ,t.PaymentDays = s.PaymentDays
            ,t.PhoneNumber = s.PhoneNumber
            ,t.FaxNumber = s.FaxNumber
            ,t.WebsiteURL = s.WebsiteURL
            ,t.DeliveryAddressLine1 = s.DeliveryAddressLine1
            ,t.DeliveryPostalCode = s.DeliveryPostalCode
            ,t.PostalAddressLine1 = s.PostalAddressLine1
            ,t.PostalPostalCode = s.PostalPostalCode
            ,t.LastEditedBy = s.LastEditedBy
when not matched by target
then insert(
             CustomerName,BillToCustomerID,CustomerCategoryID,PrimaryContactPersonID,DeliveryMethodID
            ,DeliveryCityID,PostalCityID,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent
            ,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1
            ,DeliveryPostalCode,PostalAddressLine1,PostalPostalCode,LastEditedBy)
values(      s.CustomerName,s.BillToCustomerID,s.CustomerCategoryID,s.PrimaryContactPersonID,s.DeliveryMethodID
            ,s.DeliveryCityID,s.PostalCityID,s.AccountOpenedDate,s.StandardDiscountPercentage,s.IsStatementSent
            ,s.IsOnCreditHold,s.PaymentDays,s.PhoneNumber,s.FaxNumber,s.WebsiteURL,s.DeliveryAddressLine1
            ,s.DeliveryPostalCode,s.PostalAddressLine1,s.PostalPostalCode,s.LastEditedBy);

--select  * from Sales.Customers where CustomerName = 'test'
 

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

--exec sp_configure 'show advanced options',1
--reconfigure
--exec sp_configure 'xp_cmdshell',1
--reconfigure
--select @@SERVERNAME

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.InvoiceLines" out E:\bcp.txt -T -w -t "@W&" -S LAPTOP-5EFL0IAT\UTASQL2021'

--DROP TABLE IF EXISTS [Sales].[InvoiceLines_demo]
--CREATE TABLE [Sales].[InvoiceLines_demo](
--	[InvoiceLineID] [int] NOT NULL,
--	[InvoiceID] [int] NOT NULL,
--	[StockItemID] [int] NOT NULL,
--	[Description] [nvarchar](100) NOT NULL,
--	[PackageTypeID] [int] NOT NULL,
--	[Quantity] [int] NOT NULL,
--	[UnitPrice] [decimal](18, 2) NULL,
--	[TaxRate] [decimal](18, 3) NOT NULL,
--	[TaxAmount] [decimal](18, 2) NOT NULL,
--	[LineProfit] [decimal](18, 2) NOT NULL,
--	[ExtendedPrice] [decimal](18, 2) NOT NULL,
--	[LastEditedBy] [int] NOT NULL,
--	[LastEditedWhen] [datetime2](7) NOT NULL
--)

BULK INSERT [WideWorldImporters].[Sales].[InvoiceLines_demo]
from "E:\bcp.txt"
with(
batchsize =1000,
datafiletype = 'widechar',
fieldterminator ='@W&',
rowterminator = '\n',
keepnulls,
tablock
)

--select * from Sales.InvoiceLines_demo