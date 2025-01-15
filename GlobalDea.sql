-- Define table aliases for clarity and consistency
-- Improved comments for better context and explanation

-- Preview of main tables
SELECT * FROM GlobalDeaths..AnnualDeaths; -- Renamed for readability
SELECT * FROM GlobalDeaths..CountryContinents;
SELECT * FROM GlobalDeaths..WorldPopulation;
SELECT * FROM GlobalDeaths..MedicalDoctors;

-- Calculate key death metrics and doctor population per 10,000 people
WITH DeathMetrics AS (
    SELECT 
        dea.Entity AS Country,
        cont.Continent_Name AS Continent,
        pop.[Population (historical estimates)] AS Population,
        dea.Year,
        med.Indicator AS Doctor_Type,
        med.FactValueNumeric AS Doctor_Count,
        ROUND((med.FactValueNumeric / pop.[Population (historical estimates)]) * 10000, 2) AS Doctors_per_10000,
        ROUND(((dea.[Acute hepatitis] + dea.[Cirrhosis and other chronic liver diseases]) / pop.[Population (historical estimates)]) * 100, 3) AS Liver_Related_Deaths_Pct,
        ROUND((dea.[Cardiovascular diseases] / pop.[Population (historical estimates)]) * 100, 3) AS Heart_Related_Deaths_Pct,
        ROUND(((dea.[Lower respiratory infections] + dea.[Chronic respiratory diseases]) / pop.[Population (historical estimates)]) * 100, 3) AS Lung_Related_Deaths_Pct,
        ROUND(((dea.[Digestive diseases] + dea.[Diarrheal diseases]) / pop.[Population (historical estimates)]) * 100, 3) AS GIT_Related_Deaths_Pct,
        ROUND((dea.[Chronic kidney disease] / pop.[Population (historical estimates)]) * 100, 3) AS Kidney_Related_Deaths_Pct
    FROM GlobalDeaths..AnnualDeaths dea
    JOIN GlobalDeaths..WorldPopulation pop ON dea.Code = pop.Code AND dea.Year = pop.Year
    JOIN GlobalDeaths..CountryContinents cont ON dea.Code = cont.Three_Letter_Country_Code
    JOIN GlobalDeaths..MedicalDoctors med ON dea.Code = med.ThreeLocCode AND dea.Year = med.Period
    WHERE dea.Year IN ('1990', '2000', '2010', '2019')
)
-- Select top countries by likelihood of seeing a specialist doctor
SELECT TOP 20 
    Country,
    Continent,
    Population,
    Year,
    Doctor_Type,
    Doctor_Count,
    Doctors_per_10000,
    CONCAT(Liver_Related_Deaths_Pct, '%') AS Liver_Related_Deaths,
    CONCAT(Heart_Related_Deaths_Pct, '%') AS Heart_Related_Deaths,
    CONCAT(Lung_Related_Deaths_Pct, '%') AS Lung_Related_Deaths,
    CONCAT(GIT_Related_Deaths_Pct, '%') AS GIT_Related_Deaths,
    CONCAT(Kidney_Related_Deaths_Pct, '%') AS Kidney_Related_Deaths
FROM DeathMetrics
WHERE Doctor_Type = 'Specialist medical practitioners (number)'
ORDER BY Doctors_per_10000 DESC, Country;

-- Calculate rolling total for heart disease deaths by population
SELECT 
    dea.Entity AS Country,
    cont.Continent_Name AS Continent,
    dea.Year,
    pop.[Population (historical estimates)] AS Population,
    dea.[Cardiovascular diseases] AS Heart_Disease_Deaths,
    SUM(dea.[Cardiovascular diseases]) OVER (PARTITION BY dea.Entity ORDER BY dea.Year) AS Rolling_Heart_Disease_Deaths
FROM GlobalDeaths..AnnualDeaths dea
JOIN GlobalDeaths..CountryContinents cont ON dea.Code = cont.Three_Letter_Country_Code
JOIN GlobalDeaths..WorldPopulation pop ON dea.Code = pop.Code AND dea.Year = pop.Year
WHERE cont.Continent_Name IS NOT NULL;
