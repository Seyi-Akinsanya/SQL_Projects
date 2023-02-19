/* 
SuperStore Data Exploration & Analysis

Skills used: Joins, Temp Tables, Aggregate Functions, Converting Data Types


*/

-- A look at the main table to be used for analysis

SELECT *
FROM PortfolioProject..Orders$

-- ORDERS TREND OVER TIME
--Shows the performance of sales and customer orders

SELECT YEAR([Order Date]) AS Year,COUNT([Order ID]) AS Orders, ROUND(SUM(Sales),0) AS Revenue 
FROM PortfolioProject..Orders$
GROUP BY YEAR([Order Date])
ORDER BY 1

-- SALES BREAKDOWN BY ACCOUNT MANAGERS
-- Shows performance of Account Managers according to product category and customer type

DROP TABLE if exists #AccountManagerAnalysis
CREATE TABLE #AccountManagerAnalysis
(
Sales numeric,
Order_ID nvarchar(255),
Region nvarchar(255),
Segment nvarchar(255),
Category nvarchar(255),
Account_Manager nvarchar(255)
)

INSERT INTO #AccountManagerAnalysis
SELECT Sales, [Order ID], Region, Segment, Category,
CASE
	WHEN Region = 'West' THEN 'Anna Andreadi'
	WHEN Region = 'East' THEN 'Chuck Magee'
	WHEN Region = 'Central' THEN 'Kelly Williams'
	WHEN Region = 'South' THEN 'Cassandra Brandow'
END AS Account_Manager
FROM PortfolioProject..Orders$

SELECT Account_Manager, ROUND(SUM(Sales),0) AS Total_Sales
FROM #AccountManagerAnalysis
GROUP BY Account_Manager
ORDER BY 2 DESC

-- Account Managers' Performance by Product Category

SELECT Account_Manager, ROUND(SUM(Sales),0) AS Tech_Sales
FROM #AccountManagerAnalysis
WHERE Category LIKE '%Technology%'
GROUP BY Account_Manager
ORDER BY 2 DESC

SELECT Account_Manager, ROUND(SUM(Sales),0) AS Office_Sales
FROM #AccountManagerAnalysis
WHERE Category LIKE '%Office Supplies%'
GROUP BY Account_Manager
ORDER BY 2 DESC

SELECT Account_Manager, ROUND(SUM(Sales),0) AS Furniture_Sales
FROM #AccountManagerAnalysis
WHERE Category LIKE '%Furniture%'
GROUP BY Account_Manager
ORDER BY 2 DESC

-- Account Managers' Performance by Customer Type

SELECT Account_Manager, ROUND(SUM(Sales),0) AS Corporate_Sales
FROM #AccountManagerAnalysis
WHERE Segment LIKE '%Corporate%'
GROUP BY Account_Manager
ORDER BY 2 DESC

SELECT Account_Manager, ROUND(SUM(Sales),0) AS Consumer_Sales
FROM #AccountManagerAnalysis
WHERE Segment LIKE '%Consumer%'
GROUP BY Account_Manager
ORDER BY 2 DESC

SELECT Account_Manager, ROUND(SUM(Sales),0) AS Home_Office_Sales
FROM #AccountManagerAnalysis
WHERE Segment LIKE '%Home Office%'
GROUP BY Account_Manager
ORDER BY 2 DESC

-- TOTAL ORDERS BY STATE
-- A method of determining a suitable location for product warehouse

SELECT TOP 5 State, COUNT([Order ID]) AS Orders, ROUND(SUM(Sales),0) AS Sales
FROM PortfolioProject..Orders$
GROUP BY State
ORDER BY 3 DESC

-- PROFIT AND PROFIT MARGIN BY SUB-CATEGORY
-- Ranks the sub-categories by profitability to identify loss making or low margin sub-categories which may be dropped
-- Identify the relationship between profit and order volumes ie., High margin, Low volume products and vice-versa. Doing so makes it easier to set sales tartgets that are consistent with the product's dynamics in the market.


SELECT [Sub-Category], COUNT([Order ID]) AS Orders, ROUND(SUM(Profit),0) AS Profit, ROUND(SUM(Profit)/COUNT([Order ID]),2) AS Profit_per_Item, 
	CAST(ROUND ((SUM(PROFIT)/SUM(SALES))*100, 2) AS nvarchar(10)) + '%' AS Average_Profit_Margin 
FROM PortfolioProject..Orders$
GROUP BY [Sub-Category]
ORDER BY 3 DESC

-- PRODUCT RETURNS BY CUSTOMER TYPE AND PRODUCT CATEGORY

SELECT Segment,Category, COUNT(ord.[Order ID]) AS Returned_Orders
FROM PortfolioProject..Orders$ ord
LEFT JOIN PortfolioProject..Returns$ ret
	ON ord.[Order ID] = ret.[Order ID]
WHERE Returned LIKE '%Yes%'
GROUP BY Segment, Category
ORDER BY 2,3 DESC

