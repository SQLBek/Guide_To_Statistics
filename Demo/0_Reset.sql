/*-------------------------------------------------------------------
-- 0 - Reset
-- 
-- Summary: 
--
-- Written By: Andy Yun
-------------------------------------------------------------------*/
USE CookbookDemo
GO

-- Dump data into fresh tables to ensure we're starting from scratch
DROP TABLE IF EXISTS demo.Categories;
SELECT * 
INTO demo.Categories
FROM dbo.Categories;

DROP TABLE IF EXISTS demo.Authors;
SELECT * 
INTO demo.Authors
FROM dbo.Authors;

DROP TABLE IF EXISTS demo.Recipes;
SELECT * 
INTO demo.Recipes
FROM dbo.Recipes;

DROP TABLE IF EXISTS demo.Reviews;
SELECT * 
INTO demo.Reviews
FROM dbo.Reviews;

CREATE CLUSTERED INDEX CK_Categories_CategoryID_Demo ON demo.Categories (CategoryID);

CREATE CLUSTERED INDEX CK_Authors_AuthorID_Demo ON demo.Authors (AuthorID);
CREATE NONCLUSTERED INDEX IX_Authors_State_Demo ON demo.Authors (State) INCLUDE (FirstName, LastName);

CREATE CLUSTERED INDEX CK_Recipes_RecipeID_Demo ON demo.Recipes (RecipeID);
CREATE NONCLUSTERED INDEX IX_Recipes_AuthorID_Demo ON demo.Recipes (AuthorID) INCLUDE (RecipeName, DatePublished, CategoryID);
CREATE NONCLUSTERED INDEX IX_Recipes_DatePublished_Demo ON demo.Recipes (DatePublished) INCLUDE (RecipeName, CategoryID, AuthorID);
CREATE NONCLUSTERED INDEX IX_Recipes_CategoryID_Demo ON demo.Recipes (CategoryID) INCLUDE (RecipeName, DatePublished, AuthorID);

CREATE CLUSTERED INDEX CK_Reviews_ReviewID_Demo ON demo.Reviews (ReviewID);
CREATE NONCLUSTERED INDEX IX_Reviews_AuthorID_Demo ON demo.Reviews (AuthorID) INCLUDE (ReviewText, Rating, DateSubmitted, RecipeID);
CREATE NONCLUSTERED INDEX IX_Reviews_RecipeID_Demo ON demo.Reviews (RecipeID) INCLUDE (ReviewText, Rating, DateSubmitted, AuthorID);
GO

USE CookbookDemo;
GO


DROP TABLE IF EXISTS demo.RecipeReviewSummary;
GO
CREATE TABLE demo.RecipeReviewSummary (
	RecipeID INT PRIMARY KEY CLUSTERED,
	RecipeName VARCHAR(250),
	NumOfReviews INT,
	AvgRating TINYINT,
	AvgHelpfulScore SMALLINT
);
GO

INSERT INTO demo.RecipeReviewSummary (
	RecipeID,
	RecipeName,
	NumOfReviews,
	AvgRating,
	AvgHelpfulScore
)
SELECT 
	Recipes.RecipeID,
	Recipes.RecipeName,
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
GO
