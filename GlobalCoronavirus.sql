-- COVID DEATHS TABLE
SELECT *
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL

-- Information of table 
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'CovidDeaths'

-- Select Data that we are going to be using 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths 
-- Shows likelihood of dying if you are diagnosed with Covid in your country 
SELECT location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths/total_cases)*100 AS DeathPercentage 
FROM [dbo].[CovidDeaths]
  -- WHERE location LIKE '%states'
ORDER BY 1,2

-- Looking at Total Cases vs Total Population 
-- Shows what percentage of population got Covid 
SELECT location, 
    date, 
    population, 
    total_cases, 
    (total_cases/population)*100 AS PercentPopulationInfected 
FROM [dbo].[CovidDeaths]
  -- WHERE location LIKE '%states'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population 
SELECT location, 
    population, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX(total_cases/population)*100 AS PercentPopulationInfected 
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with highest death count 
SELECT location, 
    MAX(total_deaths) AS HighestDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

-- Showing Continent with highest death count 
SELECT location, 
    MAX(total_deaths) AS HighestDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

SELECT continent, 
    MAX(total_deaths) AS HighestDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC

-- Death Percentage across the world (Tableau)
SELECT date, 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths,
    SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage 
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL 
GROUP BY date 
ORDER BY date

-- Global Death percentage 
SELECT  
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths,
    SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage 
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL 

-- COVID VACCINATIONS TABLE
SELECT *
FROM [dbo].[CovidVaccinations]

-- Looking at Total Population vs Vaccinations 
-- 1. Use CTE 
WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS(
SELECT cd.continent, 
  cd.location, 
  cd.date, 
  cd.population, 
  cv.new_vaccinations, 
  SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] cd
JOIN [dbo].[CovidVaccinations] cv
  ON cd.date = cv.date AND cd.location = cv.location 
WHERE cd.continent IS NOT NULL
)

SELECT *, 
  (RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM POPvsVac
ORDER BY 2, 3

-- 2. Use Temp Table 
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated 
(
  Continent nvarchar(50), 
  Location nvarchar(50),  
  Date datetime, 
  Population numeric, 
  New_Vaccinations numeric,
  RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated 
SELECT cd.continent, 
  cd.location, 
  cd.date, 
  cd.population, 
  cv.new_vaccinations, 
  SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] cd
JOIN [dbo].[CovidVaccinations] cv
  ON cd.date = cv.date AND cd.location = cv.location 
-- WHERE cd.continent IS NOT NULL

SELECT *, 
  (RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM #PercentPopulationVaccinated 
ORDER BY 2, 3

-- Creating View to store data for visualisations
CREATE VIEW PercentPopulationVaccinated 
AS
SELECT cd.continent, 
  cd.location, 
  cd.date, 
  cd.population, 
  cv.new_vaccinations, 
  SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] cd
JOIN [dbo].[CovidVaccinations] cv
  ON cd.date = cv.date AND cd.location = cv.location 
WHERE cd.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated
