-- Viewing the whole data to get an overview of what it looks like
SELECT *
FROM
covid_deaths;

-- Selecting a few columns to further get a look at the data and ordering first by location and then by date to arrange the data consecutively
-- The date was converted to datetime format as it came in a text format
SELECT location, str_to_date(date, "%m/%d/%Y") AS Date, total_cases, new_cases, total_deaths, population
FROM 
covid_deaths
WHERE continent <> ""   -- Some of the continents were transferred to the location for some reason leaving the continent column empty, this is to make sure those empty columns are not selected
ORDER BY location,date;

-- Looking at the total cases vs the total deaths (Death Percentage) 
-- This shows the likelihood of death if covid was contacted in a country
SELECT Location, str_to_date(date, "%m/%d/%Y") AS Date, Total_cases, Total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM 
covid_deaths
WHERE Location ="Nigeria"
AND continent <> ""
ORDER BY 1,2;

-- Looking at the total cases vs the population
-- Shows what percentage of the population has covid in a particular country (The Percentage of people infected)
SELECT Location, str_to_date(date, "%m/%d/%Y") AS Date, Population,Total_cases, (total_cases/population)*100 AS PercentInfected
FROM 
covid_deaths
WHERE Location ="Nigeria"
ORDER BY 1,2;


-- Looking at countries with highest infection rate compared to population
SELECT Location, Population, MAX(total_cases*1) as HighestInfectionCount, max((total_cases*1/population))*100 as PercentPopulationinfected
FROM 
covid_deaths
WHERE continent <> ""
GROUP BY Location, Population
ORDER BY 4 desc;

-- Showing the countries with the highest death counts per population
SELECT Location,  MAX(total_deaths*1) as TotalDeathCount, MAX(total_deaths/Population)*100 as PopulationDeathPercentage
FROM 
covid_deaths 
WHERE continent <> ""
GROUP BY Location
ORDER BY 3 desc;

-- Showing the continents with the highest death counts 
SELECT continent,  MAX(total_deaths*1) as TotalDeathCount
FROM 
covid_deaths 
WHERE continent <> ""
GROUP BY continent
ORDER BY 2 desc;


-- GLOBAL NUMBERS
-- Showing the death percentage for each day during the covid
SELECT  str_to_date(date, "%m/%d/%Y") as Date,
 sum(new_cases) as Total_cases, 
 sum(new_deaths) as Total_deaths, 
 sum(new_deaths)/ sum(new_cases)*100 as DeathPercentage
FROM 
covid_deaths
WHERE continent <> ""
GROUP BY Date
ORDER BY 1,2;

-- Showing the total cases, total cases and death percentage for the world
SELECT sum(new_cases) as total_cases, 
 sum(new_deaths) as total_deaths, 
 sum(new_deaths)/ sum(new_cases)*100 as DeathPercentage
FROM 
covid_deaths
WHERE continent <> ""
ORDER BY 1,2;


-- Looking at total Population vs Vaccination
-- Rolling the number of vaccinations on consecutively
SELECT dea.Continent, dea.Location, str_to_date(dea.date, "%m/%d/%Y") AS Date, dea.Population, vac.New_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinnated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location= vac.location AND dea.date=vac.date
WHERE dea.continent <> ""
ORDER BY 2,3;

-- Using CTE in order to carry out further operations using the RollingPeopleVaccinated Column
WITH PercentPopulationVaccinated (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(SELECT dea.continent, dea.location, str_to_date(dea.date, "%m/%d/%Y"), dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinnated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location= vac.location AND dea.date=vac.date
WHERE dea.continent <> ""
ORDER BY 2,3)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS VaccinationPerecentage
FROM PercentPopulationVaccinated;



-- Using TEMP TABLE in order to carry out further operations using the RollingPeopleVaccinated Column
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated(
Continent VARCHAR (100),
Location varchar(100),
Date datetime,
Population varchar(20),
New_vaccinations varchar(20),
RollingPeopleVaccinated varchar(20)
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, str_to_date(dea.date, "%m/%d/%Y"), dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location= vac.location AND dea.date=vac.date
WHERE dea.continent <> ""
ORDER BY 2,3;

SELECT *, (RollingPeopleVaccinated/Population)*100 AS VaccinationPercentage
FROM PercentPopulationVaccinated;


#Creating view to store data for visualizations
CREATE VIEW PercentPopulationVaccinated AS 
(SELECT dea.continent, dea.location, str_to_date(dea.date, "%m/%d/%Y"), dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinnated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location= vac.location AND dea.date=vac.date
WHERE dea.continent <> ""
order by 2,3); 