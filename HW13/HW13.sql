/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "13 - CLR".
*/

Варианты ДЗ (сделать любой один):

1) Взять готовую dll, подключить ее и продемонстрировать использование. 
Например, https://sqlsharp.com
--sp_configure 'show advanced options',1
--sp_configure 'clr enabled',1
--sp_configure 'clr strict security',0
--alter database WideWorldImporters SET TRUSTWORTHY ON
--RECONFIGURE
select * from sys.assemblies
select * from sys.assembly_modules  
--как же по тупому сделаны имена внутри сборки, я пол дня убил на то чтобы понять какое имя задается!!!!!!!!!!!1
--в описании указано что функция String_cut, в dependens тоже, но нужно догадаться посмотрев в sys.assembly_modules....
create function dbo.fn_string_cut(@StringValue NVARCHAR(MAX), @Delimiter NVARCHAR(4000), @Fields NVARCHAR(4000))
returns nvarchar(max)
as external name [SQL#].[STRING].[Cut];
go
--select  dbo.fn_string_cut('one two three four five',' ','2')

 create function dbo.fn_inet_html(@HTML NVARCHAR(MAX))
 returns nvarchar(max)
as external name [SQL#.Network].[INET].[HTMLDecode];
go
--print  dbo.fn_inet_html(N'&#128584;&#9;test<br>&#x1F648;<br><br />&Ofr;<BR/>&lopf; -- &Lopf;')


2) Взять готовые исходники из какой-нибудь статьи, скомпилировать, подключить dll, продемонстрировать использование.
Например, 
https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel

https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/

https://habr.com/ru/post/88396/

3) Написать полностью свое (что-то одно):
* Тип: JSON с валидацией, IP / MAC - адреса, ...
* Функция: работа с JSON, ...
* Агрегат: аналог STRING_AGG, ...
* (любой ваш вариант)

Результат ДЗ:
* исходники (если они есть), желательно проект Visual Studio
* откомпилированная сборка dll
* скрипт подключения dll
* демонстрация использования

