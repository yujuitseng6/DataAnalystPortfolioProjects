/* 
Queries Used for Tableau Project 
*/

/* 1. */

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS death_percentage
FROM PortfolioProject.CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
-- GROUP BY date
ORDER BY 1, 2

-- Just a double-check based on the data provided
-- Numbers are extremely close, so we will keep them. The second includes "International" location

-- SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, 
--     SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS death_percentage
-- FROM PortfolioProject.CovidDeaths
-- WHERE location = 'World'
-- ORDER BY 1, 2

/* 2. */

-- We exclude some locations to stay consistent with the above queries
-- "European Union" is part of Europe

SELECT location, SUM(CAST(new_deaths AS INT)) AS total_death_count
FROM PortfolioProject.CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NULL 
    AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC

/* 3. */

SELECT location, population, MAX(total_cases) AS highest_infection_count,  
    MAX((total_cases / population) * 100) AS percent_population_infected
FROM PortfolioProject.CovidDeaths
-- WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY percent_population_infected DESC

/* 4. */

SELECT location, population, date, MAX(total_cases) AS highest_infection_count,  
    MAX((total_cases / population) * 100) AS percent_population_infected
FROM PortfolioProject.CovidDeaths
-- WHERE location LIKE '%states%'
GROUP BY location, population, date
ORDER BY percent_population_infected DESC

/* Additional Queries */

-- Original queries to check for reference

/* 1. */

SELECT dea.continent, dea.location, dea.date, dea.population, 
    MAX(vac.total_vaccinations) AS rolling_people_vaccinated
-- , (rolling_people_vaccinated / population) * 100 AS percent_population_vaccinated
FROM PortfolioProject.CovidDeaths dea
JOIN PortfolioProject.CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
GROUP BY dea.continent, dea.location, dea.date, dea.population
ORDER BY 1, 2, 3

/* 2. */

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS death_percentage
FROM PortfolioProject.CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
ORDER BY 1, 2

/* 3. */

SELECT location, SUM(CAST(new_deaths AS INT)) AS total_death_count
FROM PortfolioProject.CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NULL 
    AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC

/* 4. */

SELECT location, population, MAX(total_cases) AS highest_infection_count,  
    MAX((total_cases / population) * 100) AS percent_population_infected
FROM PortfolioProject.CovidDeaths
-- WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY percent_population_infected DESC

/* 5. */

-- SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS death_percentage
-- FROM PortfolioProject.CovidDeaths
-- WHERE continent IS NOT NULL 
-- ORDER BY 1, 2

SELECT location, date, population, total_cases, total_deaths
FROM PortfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2

/* 6. */

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject.CovidDeaths dea
    JOIN PortfolioProject.CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
)
SELECT *, (rolling_people_vaccinated / population) * 100 AS percent_people_vaccinated
FROM PopvsVac

/* 7. */

SELECT location, population, date, MAX(total_cases) AS highest_infection_count, 
    MAX((total_cases / population) * 100) AS percent_population_infected
FROM PortfolioProject.CovidDeaths
-- WHERE location LIKE '%states%'
GROUP BY location, population, date
ORDER BY percent_population_infected DESC
