/*-------------------------------------------------------------------
-- 3 - Nested Loop Joins
-- 
-- Summary: 
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE CookbookDemo;
GO


-----
-- Disable Adaptive Joins first
ALTER DATABASE SCOPED CONFIGURATION
SET BATCH_MODE_ADAPTIVE_JOINS = OFF;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO








-----
-- Query our sample data
-- Note: state already weighted towards MA, then IL, then WI
SELECT 
	State,
	COUNT(1)
FROM demo.Authors
GROUP BY State
ORDER BY 2 DESC;
GO








-----
-- Test query
-- Ctrl-M: Actual Execution Plan
SELECT 
	Authors.State, Authors.LastName, Authors.FirstName,
	Reviews.Rating, Reviews.DateSubmitted,
	Authors.AuthorID, Reviews.ReviewID
FROM demo.Authors
LEFT OUTER JOIN demo.Reviews
	ON Authors.AuthorID = Reviews.AuthorID
WHERE Authors.State = 'WA'
OPTION(MAXDOP 1);
GO

SELECT 
	Authors.State, Authors.LastName, Authors.FirstName,
	Reviews.Rating, Reviews.DateSubmitted,
	Authors.AuthorID, Reviews.ReviewID
FROM demo.Authors
LEFT OUTER JOIN demo.Reviews
	ON Authors.AuthorID = Reviews.AuthorID
WHERE Authors.State = 'IL'
OPTION(MAXDOP 1);
GO

/*
-- Record messages -> perf stats output for baseline
Logical Reads: 
SQL Server Execution Times:

Logical Reads
SQL Server Execution Times:
*/








-----
-- Encapsulate code within a stored procedure 
-- (yes, I'm intentionally not using CREATE OR ALTER)
DROP PROCEDURE IF EXISTS demo.sp_Reviews;
GO

CREATE PROCEDURE demo.sp_Reviews (
	@State CHAR(2)
)
AS
BEGIN
	SELECT 
		Authors.LastName,
		Authors.FirstName,
		Authors.State,
		Reviews.Rating, Reviews.DateSubmitted,
		Authors.AuthorID, Reviews.ReviewID
	FROM demo.Authors
	LEFT OUTER JOIN demo.Reviews
		ON Authors.AuthorID = Reviews.AuthorID
	WHERE Authors.State = @State
	OPTION(MAXDOP 1);

	PRINT '-----';
END
GO








-----
-- Now re-execute
EXEC demo.sp_Reviews 'WA';
EXEC demo.sp_Reviews 'IL';
GO








-----
-- Flush!
DBCC FREEPROCCACHE;
GO


-- And Re-run, opposite order this time
EXEC demo.sp_Reviews 'IL';
EXEC demo.sp_Reviews 'WA';
GO




