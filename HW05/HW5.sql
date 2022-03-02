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


select  
 pvt.LastEditedWhen as [InvoiceMonth]
,isnull(pvt.[Peeples Valley, AZ],0) as [Peeples Valley, AZ]
,isnull(pvt.[Sylvanite, MT],0) as [Sylvanite, MT]
,isnull(pvt.[Gasport, NY],0) as [Gasport, NY]
,isnull(pvt.[Medicine Lodge, KS],0) as [Medicine Lodge, KS]
,isnull(pvt.[Head Office],0) as [Head Office]
,isnull(pvt.[Jessie, ND],0) as [Jessie, ND]
from 
(
  select 
	 FORMAT(DATEADD(MONTH, DATEDIFF(MONTH, 0, SOL.LastEditedWhen), 0),'dd-MM-yyyy') as LastEditedWhen
     ,SUBSTRING(CustomerName,(CHARINDEX('(',CustomerName)+1),(CHARINDEX(')',CustomerName)-CHARINDEX('(',CustomerName)-1)) as names
     ,Quantity
   from Sales.Customers  SC
   join Sales.Orders SI on SC.CustomerID = SI.CustomerID
   join Sales.OrderLines SOL on SI.OrderID = SOL.OrderID
   where SC.CustomerID<=6
   group by YEAR(SOL.LastEditedWhen)
        ,MONTH(SOL.LastEditedWhen)
		,FORMAT(DATEADD(MONTH, DATEDIFF(MONTH, 0, SOL.LastEditedWhen), 0),'dd-MM-yyyy')
		,Quantity
		,SUBSTRING(CustomerName,(CHARINDEX('(',CustomerName)+1),(CHARINDEX(')',CustomerName)-CHARINDEX('(',CustomerName)-1)) 
) as s 
PIVOT(
SUM(s.Quantity) for s.names in([Peeples Valley, AZ],[Sylvanite, MT],[Gasport, NY],[Medicine Lodge, KS],[Head Office],[Jessie, ND])
)as pvt
order by year(LastEditedWhen),month(LastEditedWhen)



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

SELECT CustomerName,Adress
FROM (
SELECT DeliveryAddressLine1,
       DeliveryAddressLine2,
	   PostalAddressLine1,
	   PostalAddressLine2,
	   CustomerName
from Sales.Customers) as ADRESS
UNPIVOT (Adress FOR Customer IN (DeliveryAddressLine1, DeliveryAddressLine2,PostalAddressLine1,PostalAddressLine2)) AS unpt;


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


select CountryID,CountryName,CODE
from(
      select CountryID,
	         CountryName,
			 cast(IsoNumericCode as nvarchar(6))as IsoNumericCode,
			 cast(IsoAlpha3Code as nvarchar(6))as IsoAlpha3Code  --не понимаю, почему мне приходится оборачивать в каст эту колонку, если она и так имеет по дефолту тип нварчар(6)
			 from Application.Countries)as Main
			 UNPIVOT (CODE FOR Customer IN (IsoNumericCode,IsoAlpha3Code)) AS unpt
			 order by CountryID,CountryName, CODE desc;


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select   SC.CustomerID, --так или каждый купленный товар должен быть уникальным?
         SC.CustomerName,
		 s.StockItemID,
		 s.UnitPrice,
		 s.OrderDate  
		 from Sales.Customers SC 
outer apply(
             select top 2 ws.StockItemID,ws.UnitPrice,OrderDate 
			 from Warehouse.StockItems WS
             join Sales.OrderLines SOL on WS.StockItemID = SOL.StockItemID
             join Sales.Orders SO on SO.OrderID = SOL.OrderID
			 where so.CustomerID=sc.CustomerID 
			 order by ws.UnitPrice desc
			 )s
order by CustomerID,CustomerName,s.UnitPrice desc

 


 