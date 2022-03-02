/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE FUNCTION dbo.GET_MAX_PAY_CLIENT()
RETURNS TABLE
AS
RETURN
(select  top 1 sol.OrderID,sc.CustomerID,sc.CustomerName,sum(Quantity*UnitPrice)over (partition by sol.OrderID order by  sol.orderID) as Summa
from  [Sales].[Orders] so
join  [Sales].[OrderLines] sol on so.OrderID=sol.OrderID
join  [Sales].[Customers] sc on so.CustomerID =sc.CustomerID
order by Summa desc);
--select * from dbo.GET_MAX_PAY_CLIENT()

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE PROC dbo.Summa_Client(@CustomerID int)
as 
select sum(s.summa) as SUMMA from(
Select sum(Quantity*UnitPrice) over(partition by sc.CustomerID order by  sc.CustomerID) as Summa
from Sales.Invoices si 
join Sales.InvoiceLines sil on si.InvoiceID = sil.InvoiceID
join Sales.Customers sc on sc.CustomerID = si.CustomerID
where sc.CustomerID = @CustomerID)s
--exec dbo.Summa_Client 834

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
CREATE FUNCTION dbo.SUMMA_ALL_F()
RETURNS TABLE
AS
RETURN
(
Select sum(Quantity*UnitPrice) as Summa
from Sales.Invoices si 
join Sales.InvoiceLines sil on si.InvoiceID = sil.InvoiceID
join Sales.Customers sc on sc.CustomerID = si.CustomerID)

--------
CREATE PROC dbo.SUMMA_ALL_P
as
Select sum(Quantity*UnitPrice) as Summa
from Sales.Invoices si 
join Sales.InvoiceLines sil on si.InvoiceID = sil.InvoiceID
join Sales.Customers sc on sc.CustomerID = si.CustomerID

--set statistics io on 
--set statistics time on
--select * from dbo.SUMMA_ALL_F()
--exec dbo.SUMMA_ALL_P
--set statistics io off 
--set statistics time off
--формально быстрее должна быть процедура из за выполнения на сервере.

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

ALTER FUNCTION dbo.test_join(@ID int)
RETURNS TABLE
AS
RETURN
(Select top 1 sc.CustomerName
from Sales.Invoices si 
join Sales.InvoiceLines sil on si.InvoiceID = sil.InvoiceID
join Sales.Customers sc on sc.CustomerID = si.CustomerID
where si.CustomerID = @ID)

select sc.PhoneNumber,
       p.CustomerName as name 
from Sales.Customers sc
CROSS APPLY dbo.test_join(3)p
 
/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
