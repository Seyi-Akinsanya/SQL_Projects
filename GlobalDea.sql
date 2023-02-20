/* 
Global Deaths and Causes Exploration

Skills used: Joins, CTEs, Aggregate Functions, Windowed Functions, Converting Data Types


*/

-- A look at the main table to be used for analysis

-- Select Data Tables that we are going to be working with

SELECT *
FROM GlobalDeaths..['1# annual-number-of-deaths-by-c$']

SELECT *
FROM GlobalDeaths..['4# ISO 3166_country-and-contine$']

SELECT *
FROM GlobalDeaths..['5# World Population$']

SELECT *
FROM GlobalDeaths..['Medical Doctors$']

/*
COUNTRIES, POPULATION, SELECTED CAUSES OF DEATH BY POPULATION 
Shows the likelihood of deaths caused by selected organ failures as well as the chances of seeing a doctor given by Doctors per 10,000 (the higher, the better)
By expressing deaths as a percentage of population, we arrive at values which do not penalize countries with large populations; 
this would have been the case if reported figures were used.
Using only 1990, 2000, 2010 and 2019 to show intracountry differences over time
*/

SELECT dea.Entity,cont.Continent_Name,pop.[Population (historical estimates)],dea. Year, med.Indicator, med.FactValueNumeric, 
		ROUND((med.FactValueNumeric/pop.[Population (historical estimates)])*10000,2) AS Doctors_per_10000,
		CAST(ROUND (((dea.[Acute hepatitis]+dea.[Cirrhosis and other chronic liver diseases])/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS Liver_Related_Deaths,
		CAST(ROUND ((dea.[Cardiovascular diseases]/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS Heart_Related_Deaths,
		CAST(ROUND (((dea.[Lower respiratory infections]+dea.[Chronic respiratory diseases])/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS Lung_Related_Deaths,
		CAST(ROUND (((dea.[Digestive diseases]+dea.[Diarrheal diseases])/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS GIT_Related_Deaths,
		CAST(ROUND ((dea.[Chronic kidney disease]/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS Kidney_Related_Deaths
FROM GlobalDeaths..['1# annual-number-of-deaths-by-c$'] dea
JOIN GlobalDeaths..['5# World Population$'] pop
	ON dea.Code = pop.Code
	AND dea.Year = pop.Year
JOIN GlobalDeaths..['4# ISO 3166_country-and-contine$'] cont
	ON dea.Code = cont.Three_Letter_Country_Code
JOIN GlobalDeaths..['Medical Doctors$'] med
	ON dea.Code = med.ThreeLocCode
	AND dea.Year = med.Period
WHERE dea.Year IN ('1990', '2000', '2010', '2019')
	AND med.Indicator != 'Medical doctors (per 10,000)'
ORDER BY 1,4

-- Top 20 countries by the likelihood of seeing a specialist doctors and thier respective death metrics
-- Shows the presence (or absence) of a meaningful relationship between doctor population and deaths due to special organ failure

WITH Top_Countries (Country, Continent, Population, Year, Doctor_ID, Doctor_Population, Doctors_per_10000, Liver_Related_Deaths, Heart_Related_Deaths, Lung_Related_Deaths, GIT_Related_Deaths, Kidney_Related_Deaths)
AS
(
SELECT dea.Entity,cont.Continent_Name,pop.[Population (historical estimates)],dea. Year, med.Indicator, med.FactValueNumeric, 
		ROUND((med.FactValueNumeric/pop.[Population (historical estimates)])*10000,2) AS Doctors_per_10000,
		CAST(ROUND (((dea.[Acute hepatitis]+dea.[Cirrhosis and other chronic liver diseases])/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS Liver_Related_Deaths,
		CAST(ROUND ((dea.[Cardiovascular diseases]/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS Heart_Related_Deaths,
		CAST(ROUND (((dea.[Lower respiratory infections]+dea.[Chronic respiratory diseases])/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS Lung_Related_Deaths,
		CAST(ROUND (((dea.[Digestive diseases]+dea.[Diarrheal diseases])/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS GIT_Related_Deaths,
		CAST(ROUND ((dea.[Chronic kidney disease]/pop.[Population (historical estimates)])*100,3) AS nvarchar(10)) + '%' AS Kidney_Related_Deaths
FROM GlobalDeaths..['1# annual-number-of-deaths-by-c$'] dea
JOIN GlobalDeaths..['5# World Population$'] pop
	ON dea.Code = pop.Code
	AND dea.Year = pop.Year
JOIN GlobalDeaths..['4# ISO 3166_country-and-contine$'] cont
	ON dea.Code = cont.Three_Letter_Country_Code
JOIN GlobalDeaths..['Medical Doctors$'] med
	ON dea.Code = med.ThreeLocCode
	AND dea.Year = med.Period
WHERE dea.Year IN ('1990', '2000', '2010', '2019')
	AND med.Indicator = 'Specialist medical practitioners (number)'
)
SELECT TOP 20 *
FROM Top_Countries
ORDER BY 7 DESC,1

-- Total deaths due to heart diseases by population using Partition

SELECT  dea.Entity, cont.Continent_Name, dea.Year, pop.[Population (historical estimates)], dea.[Cardiovascular diseases],SUM(dea.[Cardiovascular diseases]) OVER (Partition by dea.Entity ORDER BY dea.Entity, dea.Year) AS Rolling_Heart_Related_Deaths
FROM GlobalDeaths..['1# annual-number-of-deaths-by-c$'] dea
JOIN GlobalDeaths..['4# ISO 3166_country-and-contine$'] cont
	ON dea.Code = cont.Three_Letter_Country_Code
JOIN GlobalDeaths..['5# World Population$'] pop
	ON dea.Code = pop.Code
	AND dea.Year = pop.Year
WHERE cont.Continent_Name IS NOT NULL


/*
CLOSING REMARKS



*/
