/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
-- Я не уверен, что я верно соединил таблицы.

TODO: select PersonID,FullName from Application.People
where IsSalesperson =1 and PersonID in
(
  select SalespersonPersonID
  from Sales.Invoices si
  join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
  where InvoiceDate <> '2015-07-04' 
)
order by PersonID

;with cte as(
select distinct(SalespersonPersonID)
  from Sales.Invoices si
  join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
  where InvoiceDate <> '2015-07-04' 
) select PersonID,FullName from Application.People p
 join cte cte on cte.SalespersonPersonID = p.personID
where IsSalesperson =1 



/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

--не ясно условие, выбрать товары с минимальной ценой, логично если бы на одно наименование было несколько цен или на одну цену несколько наименований.
TODO: select StockItemID,StockItemName,UnitPrice from  Warehouse.StockItems
where UnitPrice in(
select min(UnitPrice) from Warehouse.StockItems
)

TODO: select StockItemID,StockItemName,UnitPrice from  Warehouse.StockItems
where UnitPrice in(
select  top 1 UnitPrice from Warehouse.StockItems
order by UnitPrice asc
)

;with cte as(
select min(UnitPrice) as UnitPrice from Warehouse.StockItems
)select StockItemID,StockItemName,ws.UnitPrice 
from Warehouse.StockItems ws
join cte cte on cte.UnitPrice = ws.UnitPrice

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--нужны ли здесь уникальные клиенты?
TODO:select  sc.CustomerID,CustomerName,PhoneNumber 
from Sales.Customers sc
join Sales.CustomerTransactions sct on sc.CustomerID = sct.CustomerID
where sct.TransactionAmount in( 
                               select top 5 TransactionAmount
                               from Sales.CustomerTransactions 
                               order by TransactionAmount desc)

;with cte as(
select top 5 TransactionAmount
from Sales.CustomerTransactions 
order by TransactionAmount desc
)
select  sc.CustomerID,CustomerName,PhoneNumber 
from Sales.Customers sc
join Sales.CustomerTransactions sct on sc.CustomerID = sct.CustomerID
join cte cte on cte.TransactionAmount = sct.TransactionAmount


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/



TODO: 
 Select 
       cs.CityID,
	   cs.CityName,
	   ap.FullName 
 from Sales.Invoices si 
      join Sales.InvoiceLines  sis on si.InvoiceID = sis.InvoiceID
      join Sales.Customers     sc  on sc.CustomerID = si.CustomerID
      join Application.Cities  cs  on cs.CityID = sc.DeliveryCityID
      join Application.People  ap  on ap.PersonID = si.PackedByPersonID
where sis.StockItemID in
 (
  select top 3 StockItemID from  Warehouse.StockItems order by UnitPrice desc
 )
group by CityID,CityName,FullName

;with cte as(
select top 3 StockItemID from  Warehouse.StockItems order by UnitPrice desc
)
 Select 
       cs.CityID,
	   cs.CityName,
	   ap.FullName 
 from Sales.Invoices si 
      join Sales.InvoiceLines  sis on si.InvoiceID = sis.InvoiceID
      join Sales.Customers     sc  on sc.CustomerID = si.CustomerID
      join Application.Cities  cs  on cs.CityID = sc.DeliveryCityID
      join Application.People  ap  on ap.PersonID = si.PackedByPersonID
	  join cte                 cte on cte.StockItemID = sis.StockItemID
 group by CityID,CityName,FullName

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO:  --запрос выводит ID счета продаж, дату, полное имя(продавца товара), сумму продаж(при условии что выще 27000), сумму товаров по счету
;WITH SalesTotals as(
                      SELECT InvoiceId, 
                      SUM(Quantity*UnitPrice) as TotalSumm
	                  FROM Sales.InvoiceLines
	                  GROUP by InvoiceId
	                  HAVING SUM(Quantity*UnitPrice) > 27000
					)
 SELECT 
      SI.InvoiceID,
      SI.InvoiceDate,
      AP.FullName AS SalesPersonName,
      ST.TotalSumm AS TotalSummByInvoice,
      SUM(SOS.PickedQuantity*SOS.UnitPrice) as TotalSummForPickedItems
FROM Sales.Invoices SI
JOIN SalesTotals ST on SI.InvoiceID = ST.InvoiceID
JOIN Application.People AP on AP.PersonID = SI.SalespersonPersonID
JOIN Sales.Orders SO on SO.OrderId =SI.OrderID and so.PickingCompletedWhen IS NOT NULL
JOIN Sales.OrderLines SOS on SOS.OrderId = ( 
                                              SELECT Orders.OrderId 
			                                  FROM Sales.Orders
			                                  WHERE Orders.PickingCompletedWhen IS NOT NULL	
				                              AND Orders.OrderId = SI.OrderId
											)
GROUP BY SI.InvoiceID,InvoiceDate,AP.FullName,ST.TotalSumm
ORDER BY ST.TotalSumm DESC
 
 
			                    