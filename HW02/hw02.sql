/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

TODO: 
select StockItemID,StockItemName from Warehouse.StockItems where StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

TODO: 
select ps.SupplierID,SupplierName from Purchasing.Suppliers ps
left join Purchasing.PurchaseOrders pp on ps.SupplierID=pp.SupplierID
where pp.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

TODO:  --Да тема на group by, но в ТЗ не указано нужно ли группировать, поэтому в нескольких примерах и так и так.
select  top 100 so.OrderID,
format(OrderDate,'dd.MM.yyyy') as 'дата заказа',
DATENAME(month, GETDATE()) as 'название месяца',
DATEPART (QUARTER ,OrderDate) as 'номер квартала',
CASE
WHEN MONTH(OrderDate)<=4 THEN 1
WHEN MONTH(OrderDate)>4 and MONTH(OrderDate)<=8 THEN 2
ELSE 3
end as 'треть года',
CustomerName
from Sales.Orders so
join Sales.OrderLines sol on so.OrderID = sol.OrderID
join Sales.Customers sc on sc.CustomerID = so.CustomerID
where UnitPrice >100 or (Quantity>20 and sol.PickingCompletedWhen is not null)
and so.OrderID NOT IN(select top 1000 OrderID from Sales.Orders)
--group by  so.OrderID,OrderDate,CustomerName,UnitPrice,Quantity,sol.PickingCompletedWhen 
--having UnitPrice >100 or (Quantity>20 and sol.PickingCompletedWhen is not null)
and so.OrderID NOT IN(select top 1000 OrderID from Sales.Orders)
order by 3,4,2





/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

TODO: 
select adm.DeliveryMethodName,ppo.ExpectedDeliveryDate,ps.SupplierName,ap.FullName
from Purchasing.Suppliers ps
join Purchasing.PurchaseOrders ppo on ps.SupplierID = ppo.SupplierID
join Application.DeliveryMethods adm on adm.DeliveryMethodID = ppo.DeliveryMethodID
join Application.People ap on ap.PersonID = ps.PrimaryContactPersonID
where ppo.ExpectedDeliveryDate >='20130101' and ppo.ExpectedDeliveryDate <=EOMONTH('20130101')
and adm.DeliveryMethodName in ('Air Freight','Refrigerated Air Freight')
and ppo.IsOrderFinalized = 1
--group by adm.DeliveryMethodName,ppo.ExpectedDeliveryDate,ps.SupplierName,ap.FullName,ppo.IsOrderFinalized
--having ppo.ExpectedDeliveryDate >='20130101' and ppo.ExpectedDeliveryDate <=EOMONTH('20130101')
--and adm.DeliveryMethodName in ('Air Freight','Refrigerated Air Freight')
--and ppo.IsOrderFinalized = 1
order by ExpectedDeliveryDate

 

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/
TODO:
select top 10 sc.CustomerName,ap.FullName,so.OrderDate
from Sales.Orders so 
join Sales.Customers sc on so.CustomerID = sc.CustomerID
join Application.People ap on ap.PersonID=so.SalespersonPersonID
order by so.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/
TODO:
select sc.CustomerID,CustomerName,PhoneNumber
from Sales.Customers sc
join Sales.Orders so on sc.CustomerID = so.CustomerID
join Sales.OrderLines sol on sol.OrderID = so.OrderID
join Warehouse.StockItems ws on ws.StockItemID = sol.StockItemID
where ws.StockItemName = 'Chocolate frogs 250g'


/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO:
select YEAR(InvoiceDate) as 'Год продажи'
,MONTH(InvoiceDate) as 'Месяц продажи'
,AVG(UnitPrice) as 'Средняя цена за месяц по всем товарам'
,SUM(Quantity*UnitPrice) as 'Общая сумма продаж за месяц'
from Sales.Invoices si
join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
group by YEAR(InvoiceDate), MONTH(InvoiceDate)
order by YEAR(InvoiceDate),MONTH(InvoiceDate)
 
 
/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO:  
select YEAR(InvoiceDate) as 'Год продажи'
,MONTH(InvoiceDate) as 'Месяц продажи'
,SUM(Quantity*UnitPrice) as 'Общая сумма продаж'
from Sales.Invoices si
join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
group by YEAR(InvoiceDate),MONTH(InvoiceDate)
having SUM(Quantity*UnitPrice) >10000
order by YEAR(InvoiceDate),MONTH(InvoiceDate)

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO: 
select YEAR(InvoiceDate) as 'Год продажи'
,MONTH(InvoiceDate) as 'Месяц продажи'
,sil.Description as 'Наименование товара'
,SUM(Quantity*UnitPrice) as 'Сумма продаж'
,MIN(InvoiceDate) as 'Дата первой продажи'
,SUM(Quantity)'Количество проданного'
from Sales.Invoices si
join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
group by YEAR(InvoiceDate),MONTH(InvoiceDate),sil.Description
having SUM(Quantity) <50
order by YEAR(InvoiceDate),MONTH(InvoiceDate),sil.Description

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

select YEAR(InvoiceDate) as 'Год продажи'
,MONTH(InvoiceDate) as 'Месяц продажи'
,isnull(SUM(Quantity*UnitPrice),0) as 'Общая сумма продаж' --не совсем ясно, месяца не будет в списке или колонка будет null?
from Sales.Invoices si
join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
group by YEAR(InvoiceDate),MONTH(InvoiceDate)
having SUM(Quantity*UnitPrice) >10000
order by YEAR(InvoiceDate),MONTH(InvoiceDate)

 