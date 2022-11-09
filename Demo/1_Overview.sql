/*-------------------------------------------------------------------
-- 1 - Overview
-- 
-- Summary: 
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE CookbookDemo;
GO




----------
-- SETUP 
----------
DROP TABLE IF EXISTS demo.tmpRecipes;
GO
SELECT * 
INTO demo.tmpRecipes
FROM dbo.Recipes;
GO
---------------
-- END SETUP 
---------------








-----
-- Fresh table: any stats?
-- Check sys.stats
SELECT 
	schemas.name + '.' + objects.name AS table_name,
	stats.name as stats_name,
	stats.auto_created,
	stats.user_created,
	stats.stats_id
FROM sys.objects
INNER JOIN sys.schemas
	ON objects.schema_id = schemas.schema_id
LEFT OUTER JOIN sys.stats
	ON objects.object_id = stats.object_id
WHERE schemas.name = 'demo'
	AND objects.name = 'tmpRecipes';
GO








-----
-- Will SQL Server auto-create stats for me?
-- Query the table
SELECT TOP 1000 *
FROM demo.tmpRecipes;
GO


-- Check sys.stats
SELECT 
	schemas.name + '.' + objects.name AS table_name, stats.name as stats_name, 
	stats.auto_created, stats.user_created, stats.stats_id
FROM sys.objects
INNER JOIN sys.schemas
	ON objects.schema_id = schemas.schema_id
LEFT OUTER JOIN sys.stats
	ON objects.object_id = stats.object_id
WHERE schemas.name = 'demo'
	AND objects.name = 'tmpRecipes';
GO








-----
-- Need a predicate of some sort!
SELECT TOP 1000 *
FROM demo.tmpRecipes
WHERE DatePublished >= '2020-01-01';
GO








-----
-- Check sys.stats
SELECT 
	schemas.name + '.' + objects.name AS table_name, stats.name as stats_name, 
	stats.auto_created, stats.user_created, stats.stats_id
FROM sys.objects
INNER JOIN sys.schemas
	ON objects.schema_id = schemas.schema_id
LEFT OUTER JOIN sys.stats
	ON objects.object_id = stats.object_id
WHERE schemas.name = 'demo'
	AND objects.name = 'tmpRecipes';
GO








-----
-- Let's see the details of what was just created
SELECT 
	schemas.name + '.' + objects.name + '.' + columns.name AS object_name,
	stats.name as stats_name, 
	dm_db_stats_properties.last_updated,
	dm_db_stats_properties.rows,
	dm_db_stats_properties.rows_sampled,
	dm_db_stats_properties.modification_counter, stats.stats_id
FROM sys.objects
INNER JOIN sys.schemas
	ON objects.schema_id = schemas.schema_id
LEFT OUTER JOIN sys.stats
	ON objects.object_id = stats.object_id
CROSS APPLY sys.dm_db_stats_properties (stats.object_id, stats.stats_id)
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
WHERE schemas.name = 'demo'
	AND objects.name = 'tmpRecipes';
GO
-- Note the last_updated timestamp: 








-----
-- Let's mess with modification_counter
UPDATE demo.tmpRecipes
SET DatePublished = DATEADD(minute, 1, DatePublished)
FROM demo.tmpRecipes
WHERE DatePublished >= '2020-01-01';
GO


-- Let's see the details of what was just created
SELECT 
	schemas.name + '.' + objects.name + '.' + columns.name AS object_name,
	stats.name as stats_name, 
	dm_db_stats_properties.last_updated,
	dm_db_stats_properties.rows,
	dm_db_stats_properties.rows_sampled,
	dm_db_stats_properties.modification_counter, stats.stats_id
FROM sys.objects
INNER JOIN sys.schemas
	ON objects.schema_id = schemas.schema_id
LEFT OUTER JOIN sys.stats
	ON objects.object_id = stats.object_id
CROSS APPLY sys.dm_db_stats_properties (stats.object_id, stats.stats_id)
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
WHERE schemas.name = 'demo'
	AND objects.name = 'tmpRecipes';
GO








-----
-- When will stats get auto-updated?
-- Update more data
UPDATE demo.tmpRecipes
SET DatePublished = DATEADD(minute, 1, DatePublished)
FROM demo.tmpRecipes
WHERE DatePublished >= '2010-01-01';
GO


-- Let's see the details of what was just created
SELECT 
	schemas.name + '.' + objects.name + '.' + columns.name AS object_name,
	stats.name as stats_name, stats.auto_created, stats.user_created,
	dm_db_stats_properties.last_updated, dm_db_stats_properties.rows,
	dm_db_stats_properties.rows_sampled, dm_db_stats_properties.modification_counter, stats.stats_id
FROM sys.objects
INNER JOIN sys.schemas
	ON objects.schema_id = schemas.schema_id
LEFT OUTER JOIN sys.stats
	ON objects.object_id = stats.object_id
CROSS APPLY sys.dm_db_stats_properties (stats.object_id, stats.stats_id)
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
WHERE schemas.name = 'demo'
	AND objects.name = 'tmpRecipes';
GO








-----
-- Auto-Update calculation?
SELECT 
	500 + (0.20 * COUNT(1)) AS [SQL_2014 -],
	SQRT(1000 * (COUNT(1))) AS [SQL_2016 +]		
FROM demo.tmpRecipes;
GO
-- Actually is lower of the two values








-----
-- Andy - you forgot, we need a predicate!
SELECT TOP 1000 *
FROM demo.tmpRecipes
WHERE DatePublished >= '2020-01-01';
GO








-----
-- Let's see the details of what was just created
SELECT 
	schemas.name + '.' + objects.name + '.' + columns.name AS object_name,
	stats.name as stats_name, stats.auto_created, stats.user_created,
	dm_db_stats_properties.last_updated, dm_db_stats_properties.rows,
	dm_db_stats_properties.rows_sampled, dm_db_stats_properties.modification_counter, stats.stats_id
FROM sys.objects
INNER JOIN sys.schemas
	ON objects.schema_id = schemas.schema_id
LEFT OUTER JOIN sys.stats
	ON objects.object_id = stats.object_id
CROSS APPLY sys.dm_db_stats_properties (stats.object_id, stats.stats_id)
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
WHERE schemas.name = 'demo'
	AND objects.name = 'tmpRecipes';
GO

-- What happened?








-----
-- OPTIONAL
-- What's up with those names?!
SELECT 
	stats.name as stats_name
FROM sys.stats
WHERE stats.object_id = OBJECT_ID(N'demo.tmpRecipes');
GO




/*
Reference: https://www.sqlskills.com/blogs/paul/how-are-auto-created-column-statistics-names-generated/
_WA = Washington State -> because the SQL team was based there
_Sys = Denotes was automatically created

What about the other two values?
*/


SELECT 
	stats.name AS stats_name,
	stats_columns.column_id, 
	CONVERT(VARBINARY(8), objects.object_id) AS object_id_as_hexadecimal
FROM sys.objects
INNER JOIN sys.schemas
	ON objects.schema_id = schemas.schema_id
INNER JOIN sys.stats
	ON objects.object_id = stats.object_id
CROSS APPLY sys.dm_db_stats_properties (stats.object_id, stats.stats_id)
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
WHERE schemas.name = 'demo'
	AND objects.name = 'tmpRecipes';
GO



--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
