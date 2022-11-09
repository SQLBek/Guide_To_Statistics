/*-------------------------------------------------------------------
-- 5 - Temp Tables
-- 
-- Summary: 
-- Common pattern = create a temp table, pre-fill with data, then
-- do something else against that

-- Typically better than putting it all into one single gigantic query
-- HOWEVER, caching of temp tables could potential cause some unexpected
-- behavior!
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE CookbookDemo
GO








-----
-- Review Example Code
CREATE OR ALTER PROCEDURE demo.tmpTable (
	@CategoryName VARCHAR(250) = 'Dessert'
)
AS
BEGIN
	-----
	-- Sample code from prior demo
	DROP TABLE IF EXISTS #tmpRecipes;

	CREATE TABLE #tmpRecipes (
		CategoryName VARCHAR(250), RecipeName VARCHAR(250),
		CategoryID INT, RecipeID INT PRIMARY KEY CLUSTERED
	);

	INSERT INTO #tmpRecipes
	SELECT 
		Categories.CategoryName, Recipes.RecipeName,
		Categories.CategoryID, Recipes.RecipeID
	FROM demo.Categories
	INNER JOIN demo.Recipes
		ON Recipes.CategoryID = Categories.CategoryID
	WHERE CategoryName = @CategoryName;

	-----
	-- Convenience statement to auto-create some statistics
	SELECT *
	FROM #tmpRecipes 
	WHERE RecipeID < 0;

	-- Reference query to show parameter & # of records in temp table
	SELECT 
		@CategoryName AS Parameter, 
		COUNT(1) AS NumberOfRecipes,
		OBJECT_ID(N'tempdb..#tmpRecipes') AS TempTableObjectID
	FROM #tmpRecipes ;

	-- Histogram 
	SELECT 
		stats.stats_id,
		stats.name AS stats_name,
		dm_db_stats_properties.steps, dm_db_stats_properties.rows, dm_db_stats_properties.rows_sampled
	FROM tempdb.sys.stats
	CROSS APPLY tempdb.sys.dm_db_stats_properties(stats.object_id, stats.stats_id) 
	WHERE stats.object_id IN (OBJECT_ID(N'tempdb..#tmpRecipes'));
	
    DROP TABLE #tmpRecipes;
END;
GO








-----
-- Execute our code
EXECUTE demo.tmpTable;








-----
-- Execute again with different parameter values
EXECUTE demo.tmpTable 'Lunch/Snacks';
GO
EXECUTE demo.tmpTable 'Asian';
GO








-----
-- Quick Reset
DBCC FREEPROCCACHE
GO


-- Re-run in reverse order
EXECUTE demo.tmpTable 'Asian';
EXECUTE demo.tmpTable 'Lunch/Snacks';
EXECUTE demo.tmpTable;
GO







/*
References:
https://www.brentozar.com/archive/2020/11/paul-white-explains-temp-table-caching-3-ways/
https://www.sql.kiwi/2012/08/temporary-tables-in-stored-procedures.html
https://www.sql.kiwi/2012/08/temporary-object-caching-explained.html
*/
