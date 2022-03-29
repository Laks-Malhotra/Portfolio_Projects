SELECT *
FROM	Portfolio_Project..[owid-covid-data_vaccinations]

WHERE	continent is not null	

ORDER BY 3,4

--SELECT *
--FROM	Portfolio_Project..['owid-covid-data_deaths$']

--ORDER BY 3,4

--Select data that we are using

SELECT location, date, total_cases, new_cases, total_deaths, population

FROM	Portfolio_Project..['owid-covid-data_deaths$']

WHERE	continent is not null

ORDER BY	1,2

-- lOOKING AT TOTAL_CASE VS tOTAL_Deaths
--liklihood of dying if your contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage

FROM	Portfolio_Project..['owid-covid-data_deaths$']

WHERE	location like '%canada%'
ORDER BY	1,2

--Looking at total_cases vs population

SELECT location, date, population, total_cases,  total_deaths, (total_cases/population)*100 AS Population_Percentage

FROM	Portfolio_Project..['owid-covid-data_deaths$']

WHERE	location like '%canada%'
ORDER BY	1,2

--Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS Highest_Infection_Count,  MAX(total_deaths) AS Highest_Death_Count, MAX((total_cases/population))*100 AS Population_Infection_Percentage

FROM	Portfolio_Project..['owid-covid-data_deaths$']

--WHERE	location like '%canada%'

GROUP BY	location, population
ORDER BY	Population_Infection_Percentage desc

--Countries with highest death count per population

SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount

FROM	Portfolio_Project..['owid-covid-data_deaths$']

--WHERE	location like '%canada%'

WHERE	continent is not null
GROUP BY	location
ORDER BY	TotalDeathCount desc






--Countries with highest deaths percent

SELECT location, population, MAX(total_cases) AS Highest_Infection_Count,  MAX(total_deaths) AS Highest_Death_Count, MAX((total_deaths/population))*100 AS Population_Death_Percentage

FROM	Portfolio_Project..['owid-covid-data_deaths$']

--WHERE	location like '%canada%'
 WHERE	continent is not null
GROUP BY	location, population
ORDER BY	Population_Death_Percentage desc

--Now let's break it down by continents

--Continents with the highest Death count

SELECT	continent, MAX (CAST(total_deaths AS INT)) AS TotalDeathCount

FROM	Portfolio_Project..['owid-covid-data_deaths$']

--WHERE	location like '%canada%'
 WHERE	continent is not null
GROUP BY	continent
ORDER BY	TotalDeathCount desc

--Continents with the highest Death count

--Global Covid Cases

SELECT	SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage

FROM	Portfolio_Project..['owid-covid-data_deaths$']

WHERE	continent IS NOT NULL

ORDER BY	1,2

--JOIN the two dataset with meaningful data


SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location, dea.date) AS RollingPeopleVaccinated

FROM	Portfolio_Project..['owid-covid-data_deaths$'] AS dea JOIN Portfolio_Project..[owid-covid-data_vaccinations] AS vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE	dea.continent IS NOT NULL

ORDER BY 2,3

----Let's use CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location, dea.date) AS RollingPeopleVaccinated

FROM	Portfolio_Project..['owid-covid-data_deaths$'] AS dea JOIN Portfolio_Project..[owid-covid-data_vaccinations] AS vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE	dea.continent IS NOT NULL


)
SELECT	*, (RollingPeopleVaccinated/Population)*100
FROM	PopvsVac

--Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location, dea.date) AS RollingPeopleVaccinated

FROM	Portfolio_Project..['owid-covid-data_deaths$'] AS dea JOIN Portfolio_Project..[owid-covid-data_vaccinations] AS vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE	dea.continent IS NOT NULL

--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM	#PercentPopulationVaccinated

---Creating Views to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS

SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location, dea.date) AS RollingPeopleVaccinated

FROM	Portfolio_Project..['owid-covid-data_deaths$'] AS dea JOIN Portfolio_Project..[owid-covid-data_vaccinations] AS vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE	dea.continent IS NOT NULL

--ORDER BY 2,3

SELECT	*
FROM	PercentPopulationVaccinated
--






