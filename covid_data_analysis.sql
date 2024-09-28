SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProtfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM ProtfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2

-- Looking at total cases vs population for each country
-- Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infection_pop_percentage
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at countries with heighest infection rates compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)) * 100 AS infection_pop_percentage
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_pop_percentage DESC

-- Looking at countries with heightest death count per population
SELECT location, MAX(total_deaths) AS highest_death_count
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count DESC

-- BREAKING THINGS DOWN BY CONTINENT --

-- Showing contintents with highest death count per population
SELECT location, MAX(total_deaths) AS highest_death_count
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY highest_death_count DESC

-- Showing contintents with highest infection count per population
SELECT location, population, MAX(total_cases) AS highest_infection_count, 
    MAX((total_cases/population)) * 100 AS infection_pop_percentage
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NULL AND location != 'International'
GROUP BY location, population
ORDER BY infection_pop_percentage DESC


-- GLOBAL NUMBERS --

SELECT SUM(new_cases) AS total_new_cases, 
    SUM(new_deaths) AS total_new_deaths, 
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS death_percentage
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

SELECT date, SUM(new_cases) AS total_new_cases, 
    SUM(new_deaths) AS total_new_deaths, 
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS death_percentage
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Looking at total population vs vaccinations
WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_vacc_count)
AS
(
    SELECT cd.continent, cd.location, cd.date, population, cv.new_vaccinations,
        SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vacc_count
    FROM ProtfolioProject..CovidDeaths cd
    JOIN ProtfolioProject..CovidVaccinations cv 
        ON cd.location = cv.location AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL
   
)
SELECT *, (CONVERT(float, rolling_vacc_count) / CONVERT(float, population))*100 AS rolling_vac_percentage
FROM popvsvac
ORDER BY 2,3

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopVacc AS
SELECT cd.continent, cd.location, cd.date, population, cv.new_vaccinations,
        SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vacc_count
    FROM ProtfolioProject..CovidDeaths cd
    JOIN ProtfolioProject..CovidVaccinations cv 
        ON cd.location = cv.location AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL

CREATE VIEW HighestInfections AS
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)) * 100 AS infection_pop_percentage
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

CREATE VIEW HighestDeaths AS
SELECT location, MAX(total_deaths) AS highest_death_count
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location

CREATE VIEW InfectedPop AS
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infection_pop_percentage
FROM ProtfolioProject..CovidDeaths
WHERE continent IS NOT NULL