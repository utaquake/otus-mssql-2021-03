/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, GROUP BY, HAVING".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

TODO: 
select StockItemID,StockItemName from Warehouse.StockItems where StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

TODO: 
select ps.SupplierID,SupplierName from Purchasing.Suppliers ps
left join Purchasing.PurchaseOrders pp on ps.SupplierID=pp.SupplierID
where pp.PurchaseOrderID is null

/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

TODO:  --�� ���� �� group by, �� � �� �� ������� ����� �� ������������, ������� � ���������� �������� � ��� � ���.
select  top 100 so.OrderID,
format(OrderDate,'dd.MM.yyyy') as '���� ������',
DATENAME(month, GETDATE()) as '�������� ������',
DATEPART (QUARTER ,OrderDate) as '����� ��������',
CASE
WHEN MONTH(OrderDate)<=4 THEN 1
WHEN MONTH(OrderDate)>4 and MONTH(OrderDate)<=8 THEN 2
ELSE 3
end as '����� ����',
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
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
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
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/
TODO:
select top 10 sc.CustomerName,ap.FullName,so.OrderDate
from Sales.Orders so 
join Sales.Customers sc on so.CustomerID = sc.CustomerID
join Application.People ap on ap.PersonID=so.SalespersonPersonID
order by so.OrderDate DESC

/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/
TODO:
select sc.CustomerID,CustomerName,PhoneNumber
from Sales.Customers sc
join Sales.Orders so on sc.CustomerID = so.CustomerID
join Sales.OrderLines sol on sol.OrderID = so.OrderID
join Warehouse.StockItems ws on ws.StockItemID = sol.StockItemID
where ws.StockItemName = 'Chocolate frogs 250g'


/*
7. ��������� ������� ���� ������, ����� ����� ������� �� �������
�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ������� ���� �� ����� �� ���� �������
* ����� ����� ������ �� �����

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

TODO:
select YEAR(InvoiceDate) as '��� �������'
,MONTH(InvoiceDate) as '����� �������'
,AVG(UnitPrice) as '������� ���� �� ����� �� ���� �������'
,SUM(Quantity*UnitPrice) as '����� ����� ������ �� �����'
from Sales.Invoices si
join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
group by YEAR(InvoiceDate), MONTH(InvoiceDate)
order by YEAR(InvoiceDate),MONTH(InvoiceDate)
 
 
/*
8. ���������� ��� ������, ��� ����� ����� ������ ��������� 10 000

�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ����� ����� ������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

TODO:  
select YEAR(InvoiceDate) as '��� �������'
,MONTH(InvoiceDate) as '����� �������'
,SUM(Quantity*UnitPrice) as '����� ����� ������'
from Sales.Invoices si
join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
group by YEAR(InvoiceDate),MONTH(InvoiceDate)
having SUM(Quantity*UnitPrice) >10000
order by YEAR(InvoiceDate),MONTH(InvoiceDate)

/*
9. ������� ����� ������, ���� ������ �������
� ���������� ���������� �� �������, �� �������,
������� ������� ����� 50 �� � �����.
����������� ������ ���� �� ����,  ������, ������.

�������:
* ��� �������
* ����� �������
* ������������ ������
* ����� ������
* ���� ������ �������
* ���������� ����������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

TODO: 
select YEAR(InvoiceDate) as '��� �������'
,MONTH(InvoiceDate) as '����� �������'
,sil.Description as '������������ ������'
,SUM(Quantity*UnitPrice) as '����� ������'
,MIN(InvoiceDate) as '���� ������ �������'
,SUM(Quantity)'���������� ����������'
from Sales.Invoices si
join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
group by YEAR(InvoiceDate),MONTH(InvoiceDate),sil.Description
having SUM(Quantity) <50
order by YEAR(InvoiceDate),MONTH(InvoiceDate),sil.Description

-- ---------------------------------------------------------------------------
-- �����������
-- ---------------------------------------------------------------------------
/*
�������� ������� 8-9 ���, ����� ���� � �����-�� ������ �� ���� ������,
�� ���� ����� ����� ����������� �� � �����������, �� ��� ���� ����.
*/

select YEAR(InvoiceDate) as '��� �������'
,MONTH(InvoiceDate) as '����� �������'
,isnull(SUM(Quantity*UnitPrice),0) as '����� ����� ������' --�� ������ ����, ������ �� ����� � ������ ��� ������� ����� null?
from Sales.Invoices si
join Sales.InvoiceLines sil on sil.InvoiceID = si.InvoiceID
group by YEAR(InvoiceDate),MONTH(InvoiceDate)
having SUM(Quantity*UnitPrice) >10000
order by YEAR(InvoiceDate),MONTH(InvoiceDate)

 