/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/


select  CONVERT(varchar,pvt.LastEditedWhen,104) as [InvoiceMonth],--не совсем понимаю почему я могу обращаться к первой колонке LastEditedWhen через алиас pvt и не могу обращаться через алиас s
pvt.[Peeples Valley, AZ],pvt.[Sylvanite, MT],pvt.[Gasport, NY],pvt.[Medicine Lodge, KS],pvt.[Head Office],pvt.[Jessie, ND]
from 
(
select 
     SOL.LastEditedWhen 
    ,SUBSTRING(CustomerName,(CHARINDEX('(',CustomerName)+1),(CHARINDEX(')',CustomerName)-CHARINDEX('(',CustomerName)-1)) as names
     ,Quantity 
from Sales.Customers  SC
join Sales.Orders SI on SC.CustomerID = SI.CustomerID
join Sales.OrderLines SOL on SI.OrderID = SOL.OrderID
where SC.CustomerID<=6 
) as s 
PIVOT(
SUM(s.Quantity) for s.names in([Peeples Valley, AZ],[Sylvanite, MT],[Gasport, NY],[Medicine Lodge, KS],[Head Office],[Jessie, ND])
)as pvt
 order by pvt.LastEditedWhen



/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
select t.CustomerName,s.AddresLine from 
(
select DeliveryAddressLine1 as AddresLine from Sales.Customers 
union
select DeliveryAddressLine2 from Sales.Customers
union 
select PostalAddressLine1 from Sales.Customers
union
select PostalAddressLine1 from Sales.Customers 
)s
outer apply (select CustomerName from  Sales.Customers )t
where t.CustomerName like'Tailspin Toys%'


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/


select  CountryID,CountryName,cast(IsoNumericCode as varchar(max)) as CODE from Application.Countries
union 
select  CountryID,CountryName,IsoAlpha3Code from Application.Countries
order by CountryID,CountryName, CODE desc --наверное это неправильное решение раз тут нет pivot и outer apply
------
;with cte as
(
select CountryID,cast(IsoNumericCode as varchar(max)) as CODE from Application.Countries
union 
select CountryID, IsoAlpha3Code as CODE from Application.Countries
)
select CountryID,s.CountryName,CODE from cte cte 
outer apply(select CountryName from  Application.Countries  ac where ac.CountryID = cte.CountryID)s
order by CountryID,CountryName, CODE desc --так?))

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
--Я пока не могу сообразить, задание должно сделано быть через outer apply?
select  SC.CustomerID,SC.CustomerName,s.StockItemID,s.UnitPrice,si.OrderDate  from Sales.Customers SC
join Sales.Orders SI on SC.CustomerID = SI.CustomerID
join Sales.OrderLines SOL on SI.OrderID = SOL.OrderID   
outer apply(
             select top 2 WS.StockItemID,WS.UnitPrice from Warehouse.StockItems WS
			 where ws.StockItemID=sol.StockItemID
			 order by UnitPrice desc
			 )s
order by CustomerID,CustomerName,UnitPrice desc
 --логичным вариантом решения видится, это пронумеровать и взять каждую 1ую строчку, но и тут я столкнулся с трудностями, которые так и не могу понять.
select * from (
select  SC.CustomerID,SC.CustomerName,ws.StockItemID,ws.UnitPrice,si.OrderDate,
ROW_NUMBER() over(partition by SC.CustomerID--, ws.UnitPrice  не понимаю, почему он начинает сортировать по увелечению цены.
order by ws.UnitPrice desc) rn
from Sales.Customers SC
join Sales.Orders SI on SC.CustomerID = SI.CustomerID
join Sales.OrderLines SOL on SI.OrderID = SOL.OrderID
join Warehouse.StockItems WS on ws.StockItemID=sol.StockItemID
)s
order by CustomerID,UnitPrice,rn
 

 