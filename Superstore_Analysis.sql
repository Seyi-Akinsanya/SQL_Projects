/*
A look at the main table to be used for analysis. 
This contains sales data at a transaction level for the Sample Superstore
*/

SELECT TOP 100 *
FROM PortfolioProject..D_Orders$

-- Secondary table. This contains orders that were returned.

SELECT TOP 100 *
FROM PortfolioProject..D_Returns$

-- Finding missing values before analysis. The columns tested are those that are intergral to the analysis.

SELECT COUNT(*) AS missing_values
FROM PortfolioProject..D_Orders$
WHERE [Order Date] IS NULL
   OR [Order ID] IS NULL
   OR Segment IS NULL
   OR [Customer ID] IS NULL
   OR State IS NULL
   OR Country IS NULL
   OR [Product ID] IS NULL

-- Finding duplicate values

WITH UniqueRows AS (
	SELECT CONCAT([Order ID],[Customer ID],[Product ID],[Sub-Category],[Segment],[Sales],[Quantity]) AS UniqueID, [Row ID]
    FROM PortfolioProject..D_Orders$
	)
	
SELECT *
FROM (
	SELECT [UniqueID],
	       [Row ID],
	       ROW_NUMBER() OVER (PARTITION BY UniqueID ORDER BY (SELECT NULL)) AS RowRank
	FROM UniqueRows
	   ) AS DuplicateCheck
WHERE RowRank > 1;

/*
Identifying the number of members in important field. 
State was added to determine the size of store's distribution network (& market);
Sample Superstore is likely a US-based retailer with nationwide shipping
*/

SELECT  COUNT(DISTINCT Category) AS no_of_category, 
		COUNT(DISTINCT Segment) AS no_of_segment,
		COUNT(DISTINCT [Sub-Category]) AS no_of_subcategory,
		COUNT(DISTINCT State) AS no_of_states,
		COUNT(DISTINCT Country) AS no_of_countries
FROM PortfolioProject..D_Orders$
WHERE [Row ID]<>3407

-- Identifying high level trends in revenue, volume, and profit over time

SELECT  YEAR([Order Date]) AS order_year,
		ROUND(SUM(Sales),0) AS revenue,
		COUNT(DISTINCT [Order ID]) AS no_of_orders,
		ROUND(SUM(Profit),0) AS profit,
		ROUND(((SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY YEAR([Order Date]))) / LAG(SUM(Sales)) OVER (ORDER BY YEAR([Order Date]))) * 100, 2) AS revenue_growth_percentage,
		ROUND(((SUM(Quantity) - LAG(SUM(Quantity)) OVER (ORDER BY YEAR([Order Date]))) / LAG(SUM(Quantity)) OVER (ORDER BY YEAR([Order Date]))) * 100, 2) AS volume_growth_percentage,
		ROUND(((SUM(Profit) - LAG(SUM(Profit)) OVER (ORDER BY YEAR([Order Date]))) / LAG(SUM(Profit)) OVER (ORDER BY YEAR([Order Date]))) * 100, 2) AS profit_growth_percentage
FROM PortfolioProject..D_Orders$
WHERE [Row ID]<>3407
GROUP BY YEAR([Order Date])

 -- Assessing the level of new product introduction over time.

SELECT COUNT(DISTINCT [Product ID]) AS Unique_Products
FROM PortfolioProject..D_Orders$
GROUP BY YEAR([Order Date])

/* Assessing revenue, volume, no of products as well as unit prices by category
The aim of this is seeing, at a high level, the potential relationship between unit price and order volumes.
The increase in revenue across categories coincides with higher order volumes, more product offereings and relatively lower price points
*/
USE PortfolioProject

DROP PROCEDURE IF EXISTS CategoryStatistics
GO
CREATE PROCEDURE CategoryStatistics 
		@Category nvarchar(100)
AS
BEGIN
SELECT  Category,
		YEAR([Order Date]) AS order_year,
		ROUND(SUM([Sales]),2) AS revenue,
		COUNT(DISTINCT [Order ID]) AS no_of_orders,
		COUNT(DISTINCT [Product ID]) AS Unique_Products,
		ROUND(SUM([Sales])/COUNT(DISTINCT [Order ID]),2) AS order_value,
		ROUND(SUM([Sales])/SUM(Quantity),2) AS unit_price
FROM PortfolioProject..D_Orders$
WHERE Category=@Category
GROUP BY YEAR([Order Date]),Category
ORDER BY 2,4 DESC

END;

EXEC CategoryStatistics @Category = 'Furniture' and 'Technology'

EXEC CategoryStatistics @Category = 'Technology'

EXEC CategoryStatistics @Category = 'Office Supplies'

/*Before moving on to profitability analysis, this query looks at return levels.
Returned orders as a percentage of total orders has gradually increased over time.
*/

SELECT YEAR(ord.[Order Date]) AS Order_Year,
	   COUNT(DISTINCT ord.[Order ID]) AS Total_Orders, 
       COUNT(DISTINCT ret.[Order ID]) AS Returned_Orders,
       CAST(COUNT(DISTINCT ret.[Order ID]) AS DECIMAL(6,0)) / CAST(COUNT(DISTINCT ord.[Order ID]) AS DECIMAL(6,0)) * 100.0 AS Return_percentage
FROM  
    PortfolioProject..D_Orders$ ord
LEFT JOIN 
    PortfolioProject..D_Returns$ ret ON ord.[Order ID] = ret.[Order ID]
WHERE 
    ord.[Row ID] <> 3407
GROUP BY 
    YEAR(ord.[Order Date])

/* This section looks at profitability. 
Grouping and ranking at a sub-category level makes it easier to focus key areas of strength and weakness.
*/

SELECT ROUND(SUM([Profit]),0) AS Profit, 
	   [Sub-Category],
	   [Category],
	   ROUND(SUM(Profit)/SUM(Sales)*100,1) AS Profit_Margin, 
	   DENSE_RANK() OVER (ORDER BY SUM(Profit)/SUM(Sales) DESC) AS Margin_Rank
FROM PortfolioProject..D_Orders$
GROUP BY [Category],[Sub-Category]

/*Looking at the largest sub-category losses by year. 
This is doen to see if a sub-category had a poor year like Machines in 2017
or it's a true laggard like Tables
*/
SELECT TOP 15 YEAR([Order Date]) AS Order_Year, SUM([Profit]) AS Profit, [Sub-Category],[Category]
FROM PortfolioProject..D_Orders$
GROUP BY [Sub-Category],[Category],YEAR([Order Date])
ORDER BY 2

/* To find out why Tables is a loss making sub-category, we look at costs.
We determine costs using a formula that assumes the discount is applied before calculating profit.
We also calculate using undiscounted sales to get the discount applied to regions in a given year
The East has the highest losses as well as discount applied to its sales.
The issue can either be down to the region or the level of discounts on offer.
*/

DROP PROCEDURE IF EXISTS SubCategoryAnalysis
GO
CREATE PROCEDURE SubCategoryAnalysis
		@SubCategory nvarchar(100)
AS
BEGIN

SELECT Region,
       [Sub-Category],
       YEAR([Order Date]) AS Order_Year,
	   SUM(Sales) AS Revenue, 
	   SUM([Quantity]) AS Quantity_bought, 
	   COUNT(DISTINCT [Order ID]) AS Orders, 
	   SUM((Sales-Profit)/(1-Discount)) AS Cost, 
	   SUM([Profit]) AS Profit, 
	   SUM((Sales/(1-Discount))-Sales) AS Discount_value,
	   SUM(Sales/(1-Discount)) AS Undiscounted_revenue,
	   ROUND((SUM((Sales/(1-Discount))-Sales)/SUM(Sales/(1-Discount)))*100,1) AS Discount_percentage
FROM PortfolioProject..D_Orders$
WHERE [Sub-Category]=@SubCategory
GROUP BY YEAR([Order Date]),Region,[Sub-Category]
ORDER BY 11 DESC

END;

EXEC SubCategoryAnalysis @SubCategory = 'Tables';

/*By looking at the top 15 profitability results by region and year,
We find comparatively high discount can be accompanied by sizable profits.
Therefore, discounts alone cannot explain the lack of profitability in Tables
Region plays a larger role.
*/

SELECT TOP 15 Region,
       YEAR([Order Date]) AS Order_Year,
	   [Sub-Category],
	   SUM(Sales) AS Revenue, 
	   SUM([Quantity]) AS Quantity_bought, 
	   COUNT(DISTINCT [Order ID]) AS Orders, 
	   SUM((Sales-Profit)/(1-Discount)) AS Cost, 
	   SUM([Profit]) AS Profit, 
	   SUM((Sales/(1-Discount))-Sales) AS Discount_value,
	   SUM(Sales/(1-Discount)) AS Undiscounted_revenue,
	   ROUND(AVG(Discount)*100,1) AS Average_Discount,
	   ROUND((SUM((Sales/(1-Discount))-Sales)/SUM(Sales/(1-Discount)))*100,1) AS Discount_percentage
FROM PortfolioProject..D_Orders$
GROUP BY YEAR([Order Date]),Region, [Sub-Category]
ORDER BY 8 DESC

/*Taking a look at the sub-category with the second highest loss; Bookcases
Once again, highest discounts seem to point to deeper losses overall.
While there's no conclusive evidence, 
it would be wise to look into discounting rules on a region by region basis
*/

EXEC SubCategoryAnalysis @SubCategory = 'Bookcases';

