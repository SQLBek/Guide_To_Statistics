/*-------------------------------------------------------------------
-- 4 - Scenario X
-- 
-- Summary: 
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE CookbookDemo;
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON








-----
-- Example Query 1
-- Ctrl-M: Actual Execution Plan
SELECT 
	Categories.CategoryName, Recipes.RecipeName, Reviews.Rating,
	ReviewAuthors.LastName, ReviewAuthors.FirstName,
	Categories.CategoryID, Recipes.RecipeID, Reviews.ReviewID, ReviewAuthors.AuthorID
FROM demo.Categories
INNER JOIN demo.Recipes
	ON Recipes.CategoryID = Categories.CategoryID
INNER JOIN demo.Reviews
	ON Recipes.RecipeID = Reviews.RecipeID
INNER JOIN demo.Authors AS ReviewAuthors
	ON ReviewAuthors.AuthorID = Reviews.AuthorID
WHERE Categories.CategoryName = 'Dessert'
OPTION(MAXDOP 1);
GO

-- What's going on here?
-- Example of a poor estimate causing headaches further downstream
--
-- Ideally the JOIN between (Categories + Recipes) -> Reviews, 
-- should be a HASH MATCH because both are larger datasets









-----
-- Knee jerk reaction
UPDATE STATISTICS demo.Recipes IX_Recipes_CategoryID_Demo WITH FULLSCAN;
GO




-----
-- Re-run the query
SELECT 
	Categories.CategoryName,
	Recipes.RecipeName,
	LEFT(Reviews.ReviewText, 100) AS ReviewText,
	ReviewAuthors.LastName + ', ' + ReviewAuthors.FirstName AS ReviewAuthorName,
	Categories.CategoryID, Recipes.RecipeID, Reviews.ReviewID, ReviewAuthors.AuthorID
FROM demo.Categories
INNER JOIN demo.Recipes
	ON Recipes.CategoryID = Categories.CategoryID
INNER JOIN demo.Reviews
	ON Recipes.RecipeID = Reviews.RecipeID
INNER JOIN demo.Authors AS ReviewAuthors
	ON ReviewAuthors.AuthorID = Reviews.AuthorID
WHERE CategoryName = 'Dessert'
OPTION(MAXDOP 1);
GO

-- Did that fix it?
-- Estimate: 








-----
-- Okay, let's dig deeper
-- First, what's the index definition for reference?
-- Ctrl-M: Turn off Actual Execution Plan
EXEC sp_SQLskills_helpindex 'demo.recipes';
GO




-----
-- Now let's check the histogram to figure out this estimate
-- First, grab CategoryID to figure out range_high_key to look for
SELECT CategoryID
FROM demo.Categories
WHERE CategoryName = 'Dessert';
GO




-----
-- Histogram
SELECT 
	dm_db_stats_properties.steps, dm_db_stats_properties.rows, 
	dm_db_stats_histogram.step_number, dm_db_stats_histogram.range_high_key, 
	dm_db_stats_histogram.equal_rows, dm_db_stats_histogram.range_rows,
	dm_db_stats_histogram.distinct_range_rows, dm_db_stats_histogram.average_range_rows
FROM sys.stats
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
CROSS APPLY sys.dm_db_stats_properties(stats.object_id, stats.stats_id) 
CROSS APPLY sys.dm_db_stats_histogram(stats.object_id, stats.stats_id)
WHERE stats.object_id IN (
	OBJECT_ID(N'demo.Recipes')
)
	AND columns.name = 'CategoryID'
	AND range_high_key = 85
ORDER BY 
	dm_db_stats_histogram.step_number;
GO








-----
-- What about Density Vector?  Remember that?
DBCC SHOW_STATISTICS("demo.Recipes", IX_Recipes_CategoryID_Demo) WITH DENSITY_VECTOR;
GO


-- Paste in values from prior queries
SELECT ROWS_SAMPLED * DENSITY_VECTOR;
GO








-----
-- ???  
-- Didn't you say before that density vector is used 
-- when variables are used?
--
-- Simplify query to help isolate the issue
-- Ctrl-M: Actual Execution Plan
SELECT 
	Categories.CategoryName,
	Recipes.RecipeName,
	Categories.CategoryID, Recipes.RecipeID
FROM demo.Categories
INNER JOIN demo.Recipes
	ON Recipes.CategoryID = Categories.CategoryID
WHERE CategoryName = 'Dessert'
OPTION(MAXDOP 1);
GO




-----
-- Remember one key statement
-- Density vector is used if a given values is NOT KNOWN at compliation
-- Execution plan has no idea what the CategoryID of 'Dessert' is
-- so must make an assumption using... density vector






-----
-- But... this is an edge case too
SELECT 
	Categories.CategoryName, Categories.CategoryID, 
	COUNT(Recipes.RecipeID) AS NumOfRecipes
FROM demo.Categories
INNER JOIN demo.Recipes
	ON Recipes.CategoryID = Categories.CategoryID
GROUP BY Categories.CategoryName,
	Categories.CategoryID
ORDER BY 3 DESC
GO








-----
-- So how can we fix this?
-- You don't... in a sense...
--
-- What ELSE can get statistics?  temp tables
-- Run until STOP
DROP TABLE IF EXISTS #tmpRecipes;
CREATE TABLE #tmpRecipes (
	CategoryName VARCHAR(250),
	RecipeName VARCHAR(250),
	CategoryID INT,  
	RecipeID INT PRIMARY KEY CLUSTERED
);

INSERT INTO #tmpRecipes
SELECT 
	Categories.CategoryName, Recipes.RecipeName,
	Categories.CategoryID, Recipes.RecipeID
FROM demo.Categories
INNER JOIN demo.Recipes
	ON Recipes.CategoryID = Categories.CategoryID
WHERE CategoryName = 'Dessert'
OPTION(MAXDOP 1);

-- Step two
SELECT 
	#tmpRecipes.CategoryName,
	#tmpRecipes.RecipeName,
	LEFT(Reviews.ReviewText, 100) AS ReviewText,
	ReviewAuthors.LastName + ', ' + ReviewAuthors.FirstName AS ReviewAuthorName,
	#tmpRecipes.CategoryID, #tmpRecipes.RecipeID, Reviews.ReviewID, ReviewAuthors.AuthorID
FROM #tmpRecipes
INNER JOIN demo.Reviews
	ON #tmpRecipes.RecipeID = Reviews.RecipeID
INNER JOIN demo.Authors AS ReviewAuthors
	ON ReviewAuthors.AuthorID = Reviews.AuthorID
OPTION(MAXDOP 1);
GO


-- Original Again
PRINT '------';
SELECT 
	Categories.CategoryName,
	Recipes.RecipeName,
	LEFT(Reviews.ReviewText, 100) AS ReviewText,
	ReviewAuthors.LastName + ', ' + ReviewAuthors.FirstName AS ReviewAuthorName,
	Categories.CategoryID, Recipes.RecipeID, Reviews.ReviewID, ReviewAuthors.AuthorID
FROM demo.Categories
INNER JOIN demo.Recipes
	ON Recipes.CategoryID = Categories.CategoryID
INNER JOIN demo.Reviews
	ON Recipes.RecipeID = Reviews.RecipeID
INNER JOIN demo.Authors AS ReviewAuthors
	ON ReviewAuthors.AuthorID = Reviews.AuthorID
WHERE CategoryName = 'Dessert'
OPTION(MAXDOP 1);
GO
-- STOP



-- Side note:
-- Memory Grant Feedback


--------------------------------------------
--------------------------------------------
--------------------------------------------
--------------------------------------------
