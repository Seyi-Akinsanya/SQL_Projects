USE SeyiAkinsDB;
GO

-- Create the 2017 Forecast table

DROP TABLE IF EXISTS [2017Forecast]

CREATE TABLE [2017Forecast] (
    Year INT,
    Week NVARCHAR(10),
    Market NVARCHAR(50),
    Region NVARCHAR(50),
    Sales FLOAT,
    Profit FLOAT,
    Order_Count INT
);

-- Populate the 2017 Forecast table with calculations and handle nulls
INSERT INTO [2017Forecast] (Year, Week, Market, Region, Sales, Profit, Order_Count)
SELECT 
    2017 AS Year,
    Week,
    Market,
    Region,
    ROUND(ISNULL(Sales, 0) * 1.05, 2) AS Sales, -- 2017 Sales Forecast with 5% growth
    ROUND(ISNULL(Sales, 0) * 1.05 * 0.10, 2) AS Profit, -- 10% profit margin on 2017 Sales Forecast
    ROUND(ISNULL(Order_Count, 0) * 1.10, 0) AS Order_Count -- 10% growth for Order Count
FROM 
    [dbo].[2016Actuals]
