/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Starting Data
SELECT *
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;


-- Basic Data Selection
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID-19 in your country

SELECT location, date, total_cases, total_deaths, 
       (total_deaths / NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM PortfolioProject.CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL 
ORDER BY location, date;


-- Total Cases vs Population
-- Shows percentage of population infected with COVID-19

SELECT location, date, population, total_cases, 
       (total_cases / NULLIF(population, 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProject.CovidDeaths
ORDER BY location, date;


-- Countries with Highest Infection Rate Compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / NULLIF(population, 0)) * 100) AS PercentPopulationInfected
FROM PortfolioProject.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


-- Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Breaking Down by Continent

-- Continents with the Highest Death Count per Population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Global Numbers

SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS INT)) AS total_deaths, 
       (SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL;


-- Total Population vs Vaccinations
-- Shows percentage of population that has received at least one COVID vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(COALESCE(CAST(vac.new_vaccinations AS INT), 0)) 
           OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY dea.location, dea.date;


-- Using CTE to Perform Calculation on Partition By in Previous Query

WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(COALESCE(CAST(vac.new_vaccinations AS INT), 0)) 
               OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject.CovidDeaths dea
    JOIN PortfolioProject.CovidVaccinations vac
        ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;


-- Using Temp Table to Perform Calculation on Partition By in Previous Query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(COALESCE(CAST(vac.new_vaccinations AS INT), 0)) 
           OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;


-- Creating View to Store Data for Later Visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(COALESCE(CAST(vac.new_vaccinations AS INT), 0)) 
           OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

