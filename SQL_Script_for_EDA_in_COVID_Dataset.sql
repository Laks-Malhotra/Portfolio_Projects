---Portfolio Project: Data Cleaning & EDA for Covid19 Dataset in SQL
---SQL Script by: Laks Malhotra
---Data Source: https://ourworldindata.org/coronavirus
---Author: Laks Malhotra

---Note: Download the dataset and save it in the appropriate system directory for streamline process.


--Initial exploration

SELECT *
FROM dbo.Coviddeaths$

SELECT *
FROM CovidVaccinations$

SELECT DISTINCT(continent)
FROM DBO.Coviddeaths$


--From the object explorer side bar, we should check the data typre for every column to avoid any discrepencies in the future

--- For example; From "Coviddeath" table we observed "total_deaths" column in in NVARCHAR format , which should be INT.
--look out for these minor issues before the analysis.

---Now, let's select the important data columns that we will use in this project

SELECT location, date, total_cases, new_cases, total_deaths,population
FROM dbo.Coviddeaths$
ORDER BY 1,2


---Let's see the percentage of people died in Canada, by computing Death percent = (total deaths/total cases) * 100

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_percentage
FROM dbo.Coviddeaths$
WHERE location like '%Canada%'
ORDER BY 1,2

---Let's see the percentage of population contacted Covid, by computing Infected_Poplutation = (total cases/population)*100

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Infected_Population_percentage
FROM dbo.Coviddeaths$
WHERE location like '%Canada%'
ORDER BY 1,2


--To explore the Infected population for the world, just comment out the WHERE argument from the previous query:

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Infected_Population_percentage
FROM dbo.Coviddeaths$
--WHERE location like '%Canada%'
ORDER BY 1,2


---Let's see which countries have highest infection rate

SELECT location, MAX(total_cases) AS Highest_Infection_count, population, MAX((total_cases/population))*100 AS Infected_Population_percentage

FROM dbo.Coviddeaths$
GROUP BY location, population
ORDER BY population DESC

--Let's see which countries have highest death rate

SELECT location, population, MAX(total_cases) AS Highest_Case_count, MAX(CAST(total_deaths AS INT)) AS Highest_death_count, MAX((CAST(total_deaths AS INT)/population))*100 AS Death_percentage
FROM dbo.Coviddeaths$
WHERE continent is not null
GROUP BY location, population
ORDER BY Death_percentage DESC

---Let's see highlevel overview for the highest death COUNT by continent

SELECT DISTINCT(continent), MAX(CAST(total_deaths AS INT)) AS Highest_death_count
FROM dbo.Coviddeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY Highest_death_count DESC

----Let's see how total cases & total deaths are observed each day across the world, creating a timeline

SELECT date, MAX(CAST(total_cases AS INT)) AS Daily_infection_count, MAX(CAST(total_deaths AS INT)) AS Daily_Death_count
FROM dbo.Coviddeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

---Create the summary for total cases and total deaths observed throughout the world until now:

SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Infection_to_death_Rate
FROM dbo.Coviddeaths$
WHERE continent is not null
ORDER BY 1,2

--OR

SELECT SUM(total_cases) AS Total_Cases, SUM(CAST(total_deaths AS INT)) AS Total_deaths, SUM(CAST(total_deaths AS INT))/SUM(total_cases)*100 AS Infection_to_death_Rate
FROM dbo.Coviddeaths$
WHERE continent is not null
ORDER BY 1,2
---This query provides error for me, as there are many null values which hinders the aggregate function and conversion of datatype, whereas the first query is better because "new_Cases" & "new_deaths" are commulative data which updates regularly.



---Now, let,s use our other dataset and conduct some combined querys from both datasets.

SELECT *
FROM dbo.Coviddeaths$ AS DEA
JOIN dbo.CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date

---Let's now see the timeline on how the vaccination drive is going on around the world:

SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
SUM(CONVERT(INT, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Rolling_Vaccination_count
FROM dbo.Coviddeaths$ AS DEA
JOIN dbo.CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date

WHERE DEA.continent is not null
ORDER BY 2,3

---"SUM (required column) OVER PARTITION BY(conditional column)" argument helps in aggregating the data as we move to the next value, but make sure you call the relevant columns.
---In this case, we want the "vacinnations" to be aggregated by the location rolling through every date.
--Therefore, we use OVER(PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Rolling_Vaccination_count





---Let's take it one step further, as we know we cannot use a created variable in the same select arugument
----For example , from previous query "Rolling_vaccination_count" cannot be called in the same select clause.

--Time to use CTE-(Commaon table expressions)

--We will use CTE to view the timeline for the count on people vaccinated on daily basis and the percentage of population vaccinated.

WITH Population_vaccinated (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccination_count)
AS
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
SUM(CONVERT(INT, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Rolling_Vaccination_count
FROM dbo.Coviddeaths$ AS DEA
JOIN dbo.CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date

WHERE DEA.continent is not null
--ORDER BY 2,3
)
SELECT *, (Rolling_Vaccination_count/Population)*100 AS Percent_population_vaccinated
FROM Population_vaccinated

---Remember, if the number of columns in CTE is different than the number of columns in the subquery, we'll get an error
--Also, remember to comment out the "ORDER BY" clause because it will generate error, as it is invalid expression here in this CTE.


---Let's create a TEMP table to find out the world population vaccination drive

DROP TABLE IF EXISTS dbo.Population_Vaccinated
CREATE TABLE dbo.Population_Vaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
Rolling_Vaccination_count NUMERIC
)
INSERT INTO dbo.Population_Vaccinated
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
SUM(CAST(VAC.new_vaccinations AS INT)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Rolling_Vaccination_count
FROM dbo.Coviddeaths$ AS DEA
JOIN dbo.CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date

--WHERE DEA.continent is not null
--ORDER BY 2,3

SELECT *, (Rolling_Vaccination_count/Population)*100 AS Percent_population_vaccinated
FROM dbo.Population_Vaccinated




---Let's create Views to save our tables, to be used for the visualization


---Let's Create a VIEW for highlevel overview for the highest death COUNT by continent

CREATE VIEW Highest_Death_Count_by_continent AS

SELECT DISTINCT(continent), MAX(CAST(total_deaths AS INT)) AS Highest_death_count
FROM dbo.Coviddeaths$
WHERE continent is not null
GROUP BY continent
--ORDER BY Highest_death_count DESC

---Create VIEW for the summary for total cases and total deaths observed throughout the world until now:

CREATE VIEW Covid_Summary AS
SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Infection_to_death_Rate
FROM dbo.Coviddeaths$
WHERE continent is not null
--ORDER BY 1,2



---Create VIEW for the Vaccinattion drive throughout the world

CREATE VIEW Population_Vaccinated_VIEW AS

WITH Population_vaccinated (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccination_count)
AS
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
SUM(CONVERT(INT, VAC.new_vaccinations)) OVER (PARTITION BY DEA.location ORDER BY DEA.location, DEA.date) AS Rolling_Vaccination_count
FROM dbo.Coviddeaths$ AS DEA
JOIN dbo.CovidVaccinations$ AS VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date

WHERE DEA.continent is not null
--ORDER BY 2,3
)
SELECT *, (Rolling_Vaccination_count/Population)*100 AS Percent_population_vaccinated
FROM Population_vaccinated


---Create a VIEW for the Canadian population contacted Covid19

CREATE VIEW Canadian_Population_infection_rate AS
SELECT location, date, total_cases, population, (total_cases/population)*100 AS Infected_Population_percentage
FROM dbo.Coviddeaths$
WHERE location like '%Canada%'
--ORDER BY 1,2

