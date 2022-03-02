/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

DROP TABLE IF EXISTS [dbo].[StockItems]
CREATE TABLE [dbo].[StockItems](
	[StockItemName] [nvarchar](100) NOT NULL,
	[SupplierID] [int] NOT NULL,
	[UnitPackageID] [int] NOT NULL,
	[OuterPackageID] [int] NOT NULL,
	[LeadTimeDays] [int] NOT NULL,
	[QuantityPerOuter] [int] NOT NULL,
	[IsChillerStock] [bit] NOT NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[UnitPrice] [decimal](18, 2) NOT NULL,
	[TypicalWeightPerUnit] [decimal](18, 3) NOT NULL
)

 declare @docxml xml
 declare @dochandle int 
 select @docxml = bulkcolumn from   OPENROWSET( 
BULK 'C:\Users\utaaa\Documents\GitHub\otus-mssql-2021-03-belov\HW08\StockItems.xml',  
   SINGLE_BLOB) AS data; 
 exec sp_xml_preparedocument @dochandle OUTPUT,@docxml

INSERT INTO [dbo].[StockItems](
StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice
) 
 select * from OPENXML(@dochandle,N'StockItems/Item')
 with(
 	  StockItemName nvarchar(100) '@Name'
      ,SupplierID int 'SupplierID'
	  ,UnitPackageID int 'Package/UnitPackageID'
	  ,OuterPackageID int 'Package/OuterPackageID'
	  ,LeadTimeDays int 'LeadTimeDays'
	  ,QuantityPerOuter int 'Package/QuantityPerOuter'
	  ,IsChillerStock bit 'IsChillerStock'
	  ,TaxRate decimal(18, 3) 'TaxRate'
	  ,UnitPrice decimal(18, 2) 'UnitPrice'
	  ,TypicalWeightPerUnit decimal(18, 3) 'Package/TypicalWeightPerUnit'
	  )  
 

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/
--для выгрузки файла на хард
--EXEC master.dbo.sp_configure 'show advanced options', 1
--RECONFIGURE
--EXEC master.dbo.sp_configure 'xp_cmdshell', 1
--RECONFIGURE

SELECT A.MyXML
INTO ##AuditLogTempTable
FROM
(SELECT CONVERT(nvarchar(max), 
    (
            select 
           StockItemID as [@ID]
          ,StockItemName as [StockItemName]
          ,SupplierID   
          ,ColorID
          ,UnitPackageID as [Package/UnitPackageID]
          ,OuterPackageID as [Package/OuterPackageID]
          ,Brand
          ,Size
          ,LeadTimeDays
          ,QuantityPerOuter as [Package/TypicalWeightPerUnit]
          ,IsChillerStock
          ,Barcode
          ,TaxRate
          ,UnitPrice
          ,RecommendedRetailPrice
          ,TypicalWeightPerUnit as [Package/TypicalWeightPerUnit]
          ,MarketingComments
          ,InternalComments
          ,Photo
          ,CustomFields
          ,Tags
          ,SearchDetails
          ,LastEditedBy
          ,ValidFrom
          ,ValidTo
          from Warehouse.StockItems 
          FOR XML PATH('StockItems'),ROOT ('StockItems')
        )
    , 0
    )   AS MyXML
) A
EXEC xp_cmdshell 'bcp "SELECT MyXML FROM ##AuditLogTempTable" queryout "E:\bcptest.xml" -T -c -t -S "LAPTOP-5EFL0IAT\UTASQL2021"' 
 

--для выгрузки файла на хард
--EXEC master.dbo.sp_configure 'show advanced options', 1
--RECONFIGURE
--EXEC master.dbo.sp_configure 'xp_cmdshell', 1
--RECONFIGURE

 



/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

 select 
  StockItemID  
 ,StockItemName
 ,JSON_VALUE(CustomFields,'$.CountryOfManufacture') as CountryOfManufacture
 ,isnull(JSON_VALUE(CustomFields,'$.Tags[0]'),'Without Tag') as FirstTag
 from Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


 select 
  StockItemID  
 ,StockItemName
 ,FirstTag.value
 from Warehouse.StockItems
 cross apply OPENJSON(CustomFields,'$.Tags') as FirstTag
 where FirstTag.value = 'Vintage'
