/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
set statistics time,io on
select CustomerTransactionID, SC.CustomerName,SI.InvoiceDate,SCT.TransactionAmount,
(select SUM(SCT2.TransactionAmount)      from Sales.Invoices SI2
                                         join Sales.Customers SC2 on SI2.CustomerID = SC2.CustomerID
                                         join Sales.CustomerTransactions as SCT2 on SI2.InvoiceID = SCT2.InvoiceID
                                         where year(si.InvoiceDate)  = year(si2.InvoiceDate)
										 and  month(si.InvoiceDate) >= month(si2.InvoiceDate)
										 and sc2.CustomerName = sc.CustomerName
										   )as Summa 
from Sales.Invoices SI
join Sales.Customers SC on SI.CustomerID = SC.CustomerID
join Sales.CustomerTransactions as SCT on SI.InvoiceID = SCT.InvoiceID
where SI.InvoiceDate >= '01-01-2015'
group by SI.InvoiceDate, SC.CustomerName,CustomerTransactionID,SCT.TransactionAmount
order by CustomerName,InvoiceDate
--set statistics time,io off
 
 
 
/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

--set statistics time,io on
select CustomerTransactionID, SC.CustomerName,InvoiceDate,SCT.TransactionAmount,
SUM(SCT.TransactionAmount) OVER (PARTITION by SI.CustomerID order by year(transactiondate),month(transactiondate)
) as sum_cust_month
from Sales.Invoices SI
join Sales.Customers SC on SI.CustomerID = SC.CustomerID
join Sales.CustomerTransactions as SCT on SI.InvoiceID = SCT.InvoiceID
where InvoiceDate >='2015-01-01'
order by CustomerName,InvoiceDate
set statistics time,io off



/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
 
 select  stockitemid,month(transactionDate)as month,summa from(
 select 
 t.stockitemid
 ,t.transactionDate
 ,t.summa
 ,dense_rank()over (partition by month(t.transactionDate) order by summa desc) as n
               from(
 	           select distinct si.stockitemid,transactionDate, sum(Quantity) over(partition by si.stockitemid order by month(transactionDate))  as summa
                  from [Sales].[InvoiceLines] si
				join Sales.CustomerTransactions sct on si.InvoiceID = sct.InvoiceID
				where year(transactionDate) = '2016'
				--order by TransactionDate,summa desc
				)t
)s
where s.n <=2
group by month(transactionDate),stockitemid,summa
order by month(transactionDate),summa desc


 


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/
select StockItemID,StockItemName,Brand,UnitPrice
,sum(number) over (partition by  left(s.StockItemName,1)) as num
,lead(StockItemID) over (order by s.StockItemName) as lead
,lead(StockItemID) over (order by s.StockItemName desc) as lead_rev
,lead(StockItemName,2,'No items') over (order by s.StockItemID desc) as lead_2strback
,ntile(30) over (order by s.TypicalWeightPerUnit desc) as type_weight
--,s.TypicalWeightPerUnit
from(
select StockItemID,StockItemName,Brand,UnitPrice,
DENSE_RANK() OVER (partition by left(StockItemName,1) order by StockItemID,StockItemName) as D_R,
rank() over (order by StockItemID) as cnt, 
1 as number
,TypicalWeightPerUnit
from  [Warehouse].[StockItems] 
)s
order by StockItemID


 

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select s.PersonID,s.FullName,s.CustomerID,s.CustomerName,OrderDate,Summa
from(
select ap.PersonID,ap.FullName
,sc.CustomerID,sc.CustomerName
,so.OrderDate
,sos.Quantity*sos.UnitPrice as Summa
,row_number() over (partition by PersonID order by orderdate desc) as okno
from [Sales].[Invoices] si
join [Sales].[Customers] sc 
on si.CustomerID = sc.CustomerID
join [Application].[People] ap 
on  si.SalespersonPersonID = ap.PersonID
join [Sales].[Orders] so 
on so.OrderID = si.OrderID
join [Sales].[OrderLines] sos
on so.OrderID = sos.OrderID
)s 
where s.okno <2
 
/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/


SELECT   *
FROM 
	(
		SELECT  cust.CustomerID
		       ,cust.CustomerName
		       ,InvoiceLines.Description
			   ,InvoiceLines.StockitemID
			   ,InvoiceLines.UnitPrice
			   ,Invoices.InvoiceDate
               ,ROW_NUMBER() OVER (PARTITION BY Invoices.CustomerId ORDER BY InvoiceLines.UnitPrice DESC) AS CustomerTransRank
		FROM Sales.Invoices as Invoices
			join Sales.CustomerTransactions as trans
				ON Invoices.InvoiceID = trans.InvoiceID
            join Sales.Customers as cust 
			    ON Invoices.CustomerID = cust.CustomerID
            join  Sales.InvoiceLines as InvoiceLines
			    ON Invoices.InvoiceID = InvoiceLines.InvoiceID
	) AS tbl
WHERE CustomerTransRank <3
order by CustomerID, UnitPrice desc

 