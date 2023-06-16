SELECT *
FROM PortfolioProject..CovidDeath$
WHERE continent IS NOT NULL
ORDER BY 3,4



-- Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeath$
ORDER BY 1,2

-- Error would pop out since total_deaths and total_case are not float type
EXEC sp_help CovidDeath$
ALTER TABLE CovidDeath$
ALTER COLUMN total_deaths FLOAT
ALTER TABLE CovidDeath$
ALTER COLUMN total_cases FLOAT


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeath$
WHERE location like '%states%' 
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Show what percentage of population got Covid
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeath$
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeath$
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Show Countries with Highest Death Count per Population
SELECT Location, MAX(Total_deaths) AS TotalDeathCount 
FROM PortfolioProject..CovidDeath$
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Looking at Total Population vs Vaccinations (Use CTE)

WITH PopvsVac (Continent, Location, Date, Population, Vaccinations, RollingPeopleVaccinated) AS
(
SELECT Death.continent, Death.location, Death.date, Death.population, Vaccine.new_vaccinations,
		SUM(CAST (Vaccine.new_vaccinations AS BIGINT)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS
		RollingPeopleVaccinated
FROM PortfolioProject..CovidDeath$ AS Death
JOIN PortfolioProject..CovidVaccination$ AS Vaccine
ON Death.location = Vaccine.location
AND Death.date = Vaccine.date
WHERE Death.continent IS NOT NULL AND Vaccine.new_vaccinations IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated / Population)*100 AS PercentagePeopleVaccinated
FROM PopvsVac;

-- Creating View to store data for later visualizations
CREATE VIEW PercentagePeopleVaccinated AS
SELECT Death.continent, Death.location, Death.date, Death.population, Vaccine.new_vaccinations,
		SUM(CAST (Vaccine.new_vaccinations AS BIGINT)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS
		RollingPeopleVaccinated
FROM PortfolioProject..CovidDeath$ AS Death
JOIN PortfolioProject..CovidVaccination$ AS Vaccine
ON Death.location = Vaccine.location
AND Death.date = Vaccine.date
WHERE Death.continent IS NOT NULL AND Vaccine.new_vaccinations IS NOT NULL

SELECT *
FROM PercentagePeopleVaccinated