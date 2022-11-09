/*-------------------------------------------------------------------
-- 2 - Histogram
-- 
-- Summary: Let's dive into the histogram
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE CookbookDemo;
GO
DBCC FREEPROCCACHE
GO


-----------
-- REVIEW SETUP 
-- Already pre-executed in 0_Reset.sql
-----------
/*
CREATE TABLE demo.RecipeReviewSummary (
	RecipeID INT PRIMARY KEY CLUSTERED,
	RecipeName VARCHAR(250),
	NumOfReviews INT,
	AvgRating TINYINT,
	AvgHelpfulScore SMALLINT
);


INSERT INTO demo.RecipeReviewSummary (
	RecipeID, RecipeName, NumOfReviews, AvgRating, AvgHelpfulScore
)
SELECT 
	Recipes.RecipeID, Recipes.RecipeName,
	COUNT(Reviews.ReviewID) AS NumOfReviews,
	AVG(Reviews.Rating) AS AvgRating,
	AVG(Reviews.HelpfulScore) AS AvgHelpfulScore
FROM demo.Recipes
INNER JOIN demo.Reviews
	ON Reviews.RecipeID = Recipes.RecipeID
GROUP BY Recipes.RecipeID,
	Recipes.RecipeName;

-- Generate some column stats
SELECT *
FROM demo.RecipeReviewSummary
WHERE RecipeID < 0
	OR NumOfReviews < 0
	OR AvgRating < 0
	OR AvgHelpfulScore < 0;
*/
---------------
-- END SETUP 
---------------








-----
-- Query sys.dm_db_stats_properties()
SELECT 
	columns.name AS column_name,
	stats.name AS stats_name,
	dm_db_stats_properties.steps, dm_db_stats_properties.rows, dm_db_stats_properties.rows_sampled, 
	dm_db_stats_properties.modification_counter, dm_db_stats_properties.last_updated
FROM sys.stats
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
CROSS APPLY sys.dm_db_stats_properties(stats.object_id, stats.stats_id) 
WHERE stats.object_id IN (
	OBJECT_ID(N'demo.RecipeReviewSummary')
);
GO








-----
-- Query sys.dm_db_stats_histogram for the histogram
-- Let's look at RecipeID first
SELECT DISTINCT
	columns.name AS column_name, --stats.name AS stats_name,
	dm_db_stats_properties.steps, dm_db_stats_properties.rows, dm_db_stats_properties.rows_sampled, 
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
	OBJECT_ID(N'demo.RecipeReviewSummary')
)
	AND columns.name = 'RecipeID'
ORDER BY 
	dm_db_stats_histogram.step_number;
GO


-- range_high_key - Upper-bound column value for a histogram step. 
-- The column value is also called a key value.

-- equal_rows - Est. num. of rows whose value equals the 
-- range_high_key value

-- range_rows - Est. num. of rows whose value falls within a 
-- histogram step, excluding the corresponding range_high_key value

-- distinct_range_rows - Est. num of rows with a distinct value 
-- within a histogram step, excluding the range_high_key value

-- average_range_rows - Avg. num. of rows with duplicate 
-- values within a histogram step, excluding the range_high_key value
-- (RANGE_ROWS / DISTINCT_RANGE_ROWS for DISTINCT_RANGE_ROWS > 0)
-----








-----
-- Query sys.dm_db_stats_histogram for the histogram
-- Let's look at NumOfReviews instead
SELECT DISTINCT
	columns.name AS column_name, stats.name AS stats_name,
	dm_db_stats_properties.steps, dm_db_stats_properties.rows, dm_db_stats_properties.rows_sampled, 
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
	OBJECT_ID(N'demo.RecipeReviewSummary')
)
	AND columns.name = 'NumOfReviews'
ORDER BY 
	dm_db_stats_histogram.step_number;
GO

/*
-- Copy out some lines with varying equal & range rows 
-- with range_key_key gaps
-- Copy all of this to new query window or notepad for faster quick reference

range_high_key, equal_rows, range_rows, distinct_range_rows, average_range_rows
175	4.226763	0	0	1
181	5.884931	18.97124	4	4.742811
182	4.226763	0	0	1
188	5.884931	23.71405	5	4.742811
*/




-----
-- query where key column = range_high_key value in histogram
-- Ctrl-M: Actual Execution Plan
SELECT *
FROM demo.RecipeReviewSummary
WHERE NumOfReviews = 181;
GO

-- estimate matches equal_rows on histogram




-----
-- query with next range_high_key (that has a different equal_rows value)
SELECT *
FROM demo.RecipeReviewSummary
WHERE NumOfReviews = 182;
GO

-- Any change?
-- Why or why not?  Properties








-- For convenience
DBCC FREEPROCCACHE
GO




-----
-- query with value in between two range_high_key values
SELECT 'between two range_high_key values', *
FROM demo.RecipeReviewSummary
WHERE NumOfReviews = 185;
GO

-- Where'd this estimate come from?
-- average_range_rows




-----
-- use a local variable for range_high_key value instead
DECLARE @MyNumber INT = 181;

SELECT 'variable example', *
FROM demo.RecipeReviewSummary
WHERE NumOfReviews = @MyNumber;
GO
-- What's the estimate here?  
-- Record








-----
-- Density Vector
SELECT 
	columns.name AS column_name, stats.name as stats_name, 
	dm_db_stats_properties.rows, stats.stats_id
FROM sys.stats
CROSS APPLY sys.dm_db_stats_properties (stats.object_id, stats.stats_id)
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
WHERE stats.object_id IN (OBJECT_ID(N'demo.RecipeReviewSummary'))
GO
-- Copy stats_name AND dm_db_stats_properties.rows


DBCC SHOW_STATISTICS("demo.RecipeReviewSummary", _WA_Sys_00000003_4CB63D52) WITH DENSITY_VECTOR;
GO


-- Estimate = Density Vector * Total Number of rows in table
SELECT 
	DENSITY_VECTOR		-- DENSITY_VECTOR 
	* 
	STATS_PROPERTIES_ROWS		-- STATS_PROPERTIES_ROWS 
AS EstimatedNumOfRows;
GO




/*
Because the value of the variable not known at time of optimization, 
DENSITY VECTOR is used here!  It defines how unique is this column?
This value is NOT available in the 2016+ dmv/dmf, must use DBCC SHOW_STATISTICS

DENSITY VECTOR = 1 / (number of total distinct values)
*/








-----
-- What if I have multiple predicates?
SELECT 'multiple equality predicates', *
FROM demo.RecipeReviewSummary
WHERE AvgRating = 5
	AND AvgHelpfulScore = 10
	AND NumOfReviews = 10
GO
-- Estimate: 299.018




-----
-- Back to the histogram
SELECT DISTINCT
	columns.name AS column_name, stats.name AS stats_name,
	dm_db_stats_properties.steps, dm_db_stats_properties.rows,
	dm_db_stats_histogram.step_number, dm_db_stats_histogram.range_high_key, 
	dm_db_stats_histogram.equal_rows
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
	OBJECT_ID(N'demo.RecipeReviewSummary')
)
	AND ((
			columns.name = 'AvgRating'
			AND dm_db_stats_histogram.range_high_key = 5
		)
		OR (
			columns.name = 'AvgHelpfulScore'
			AND dm_db_stats_histogram.range_high_key = 10
		)
		OR (
			columns.name = 'NumOfReviews'
			AND dm_db_stats_histogram.range_high_key = 10
		)
	)
GO








-----
-- Selectivity for EACH COLUMN = SELECT (equal_rows / rows)
SELECT (equal_rows / rows) AS Selectivity
UNION ALL
SELECT (equal_rows / rows)
UNION ALL
SELECT (equal_rows / rows)
ORDER BY 1;




-----
-- Ranking because that is needed for exponential back-off
-- Estimate = SELECT total_num_rows * S1 * SQRT(S2) * SQRT(SQRT(S3))
SELECT total_num_rows * S1 * SQRT(S2) * SQRT(SQRT(S3))












-----
-- So... what about inequality predicates?
-- >= > < <=
DECLARE @MyNumber INT = 168;

SELECT 'inequality w variable', *
FROM demo.RecipeReviewSummary
WHERE NumOfReviews >= @MyNumber;
GO

-- What's the estimate here?  
-- Record 








-----
-- A simple answer... 30%
SELECT COUNT(1) * 0.3
FROM demo.RecipeReviewSummary;
GO








-----
-- So... what about inequality predicates?
-- >= > < <=
-- It's... complicated...
-- 
-- Let's get some new histogram data first
SELECT DISTINCT
	columns.name AS column_name, stats.name AS stats_name,
	dm_db_stats_properties.steps, dm_db_stats_properties.rows, dm_db_stats_properties.rows_sampled, 
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
	OBJECT_ID(N'demo.RecipeReviewSummary')
)
	AND columns.name = 'NumOfReviews'
ORDER BY 
	dm_db_stats_histogram.step_number;
GO
/*
-- Copy out the last three steps
range_high_key, equal_rows, range_rows, distinct_range_rows, average_range_rows
411	2.38166	26.08546	11	2.371405
575	2.38166	54.54232	23	2.371405
2892	1	109.0846	45	2.424103
*/




-----
-- example query
DBCC FREEPROCCACHE
GO
SELECT 'inequality example 2', *
FROM demo.RecipeReviewSummary
WHERE NumOfReviews >= 450;
GO

-- Estimate: 154.771








-----
-- Cardinality = EQ_ROWS + (AVG_RANGE_ROWS * ((F * (DISTINCT_RANGE_ROWS - 1)) + 1))
-- Run everything until STOP
DECLARE 
    @Q float = 450,		-- query value
    @K1 float = 411,	-- prior step high_range_key
    @K2 float = 575;	-- current step high_range_key

DECLARE
    @QR float = @Q - @K2, -- predicate range
    @SR float = @K1 - @K2, -- whole step range
	@F float,
	@PartialStep float;

SELECT @F = @QR / @SR;

SELECT 
	@PartialStep =
		dm_db_stats_histogram.equal_rows + (
			dm_db_stats_histogram.average_range_rows 
			* (
				(
					@F * (
						dm_db_stats_histogram.distinct_range_rows - 1
					)
				) 
			+ 1
		)
	)
FROM sys.stats
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
CROSS APPLY sys.dm_db_stats_histogram(stats.object_id, stats.stats_id)
WHERE stats.object_id IN (
	OBJECT_ID(N'demo.RecipeReviewSummary')
)
	AND columns.name = 'NumOfReviews'
	AND range_high_key = 575

SELECT 
	@PartialStep + dm_db_stats_histogram.equal_rows + dm_db_stats_histogram.range_rows
FROM sys.stats
INNER JOIN sys.stats_columns
    ON stats.object_id = stats_columns.object_id 
	AND stats.stats_id = stats_columns.stats_id  
INNER JOIN sys.columns  
    ON stats_columns.object_id = columns.object_id 
	AND columns.column_id = stats_columns.column_id  
CROSS APPLY sys.dm_db_stats_histogram(stats.object_id, stats.stats_id)
WHERE stats.object_id IN (
	OBJECT_ID(N'demo.RecipeReviewSummary')
)
	AND columns.name = 'NumOfReviews'
	AND range_high_key = 2892;
GO

-- STOP HERE




		
/*
-- References: 
https://sqlserverscotsman.wordpress.com/2016/11/10/statistics-cardinality-estimator-model-variations/
https://sqlperformance.com/2014/01/sql-plan/cardinality-estimation-for-multiple-predicates
https://www.sql.kiwi/2014/04/cardinality-estimation-for-disjunctive-predicates-in-2014.html
https://dba.stackexchange.com/questions/312816/how-does-sql-estimate-the-number-of-rows-in-a-less-than-predicate
https://dba.stackexchange.com/questions/148523/cardinality-estimation-for-and-for-intra-step-statistics-value/169384#169384
*/



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
