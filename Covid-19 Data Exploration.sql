USE PortfolioProject; 

SELECT *
FROM Coviddeaths
ORDER BY 3,4;

-- Next we will update the Date column in the relevant tables to the right format, as it currently is a string 
UPDATE coviddeaths SET date = str_to_date(date, "%d/%m/%Y");
UPDATE covidvaccinations SET date = str_to_date(date, "%d/%m/%Y)");

-- We also want to update some of the the blank strings to NULL values
UPDATE coviddeaths SET continent = NULL WHERE continent = '';
UPDATE coviddeaths SET new_cases_smoothed = NULL WHERE new_cases_smoothed = '';
UPDATE coviddeaths SET total_deaths = NULL WHERE total_deaths = '';
UPDATE coviddeaths SET new_deaths = NULL WHERE new_deaths = '';
UPDATE coviddeaths SET new_deaths_smoothed = NULL WHERE new_deaths_smoothed = '';
UPDATE coviddeaths SET total_cases_per_million = NULL WHERE total_cases_per_million = '';
UPDATE coviddeaths SET new_cases_per_million = NULL WHERE new_cases_per_million = '';
UPDATE coviddeaths SET new_cases_smoothed_per_million = NULL WHERE new_cases_smoothed_per_million = '';
UPDATE coviddeaths SET total_deaths_per_million = NULL WHERE total_deaths_per_million = '';
UPDATE coviddeaths SET new_deaths_per_million = NULL WHERE new_deaths_per_million = '';
UPDATE coviddeaths SET new_deaths_smoothed_per_million = NULL WHERE new_deaths_smoothed_per_million = '';
UPDATE coviddeaths SET reproduction_rate = NULL WHERE reproduction_rate = '';
UPDATE covidvaccinations SET new_vaccinations = NULL WHERE new_vaccinations = '';



SELECT 
AVG(population),
SUM(total_deaths)
FROM coviddeaths;

-- SELECT *
-- FROM covidvaccinations
-- ORDER BY 3,4;


-- Selecting the data we are going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Now we will look at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid-19 in Norway

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE location = 'Norway'
ORDER BY 1,2;

-- Looking at Total cases vs Population
-- Show what percentage of population got Covid under the relevant timeperiod in Norway

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PopulationContraction
FROM coviddeaths
WHERE location = 'Norway'
ORDER BY 1,2;


-- Looking at countries with Highest Infection Rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;

-- Showing Countries with the Highest Death Count per Population
-- Had a problem with the STRING for total_deaths. Therefore, I casted it as signed (or int for MsSQL)

SELECT location, MAX(CAST(total_deaths as signed)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc;

-- Showing the differences amongst continents with the Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths as signed)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount desc;

-- GLOBAL NUMBERS 

SELECT 
	date,
	SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Looking at Total Population vs Vaccinations

WITH PopVsVac (continent, location, date, population,  new_vaccinations, RollingCountofPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations AS SIGNED))
OVER (PARTITION BY dea.location order by dea.location, dea.date) AS RollingCountofPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac 
    ON dea.location = vac.location AND dea.date = vac.date
where dea.continent IS NOT NULL)
SELECT *, (RollingCountofPeopleVaccinated*1.0/population) * 100 AS PercentageofVaccinatedPopulation
FROM PopVsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TEMPORARY TABLE IF EXISTS percent_population_vaccinated;
CREATE TEMPORARY TABLE percent_population_vaccinated 
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population BIGINT, 
New_Vaccinations double,
RollingPeopleVaccinated BIGINT
);
INSERT INTO percent_population_vaccinated
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths AS dea
JOIN covidvaccinations AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.continent, dea.location);

-- Creating Views to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated1 AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths AS dea
JOIN covidvaccinations AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL);

SELECT * FROM PercentPopulationVaccinated;



