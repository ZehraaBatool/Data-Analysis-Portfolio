/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- 1. Covid Deaths table
SELECT * 
FROM CovidDeaths
ORDER BY 3,4 

-- 2. Total Cases Vs Total Deaths (Mortality Rate)
SELECT location, date, total_cases, total_deaths,  
CASE 
	WHEN total_cases = 0 THEN NULL 
	ELSE (total_deaths) / NULLIF( total_cases , 0) * 100 
END AS mortality_rate
FROM CovidDeaths
ORDER By location,date

-- 3. Total cases Vs Population
SELECT location, date, total_cases,population,  
(total_cases / population) * 100 AS cases_to_population
FROM CovidDeaths
ORDER By location, date

-- 4. Countries with highest infection rate
SELECT location, population,date, MAX(total_cases) AS HighestInfection, MAX((total_cases / population)) * 100
AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population,date
ORDER BY PercentPopulationInfected DESC

-- 5. Countries with highest death count per population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent <> ''
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 6. Continents with highest death count per population
SELECT location,SUM(new_deaths) AS Total_death_count
FROM CovidDeaths
WHERE continent = ''
AND location in ('Europe','Asia','Oceania','South America','North America','Africa')
GROUP BY location
ORDER BY Total_death_count DESC

-- 7. Global Numbers
-- Total Cases Vs Total Deaths in the world
SELECT SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_deaths,
CASE 
	WHEN SUM(new_cases) = 0 THEN NULL
	ELSE SUM(new_deaths)/SUM(new_cases) * 100
END AS mortality_rate
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- 8. Covid Vaccination Table
SELECT * 
FROM CovidVaccinations
ORDER BY 3,4

-- 9. Joining Covid Vaccination and Covid Death Table
SELECT *
FROM CovidVaccinations join CovidDeaths ON
CovidVaccinations.location = CovidDeaths.location AND
CovidVaccinations.date = CovidDeaths.date

-- 10. Total Population VS Vaccination
------ 1. Creating CTE
With PopulationVsVaccination(Continent,Location,Date,Population,New_Vaccination,Rolling_vaccination)
as(
SELECT Dea.continent, Dea.location, dea.date, dea.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS float)) OVER (Partition by Dea.location order by Dea.location, Dea.date) AS Rolling_vaccination
FROM CovidVaccinations Vac join CovidDeaths Dea ON
Vac.location = Dea.location AND
Vac.date = Dea.date
WHERE Dea.continent<>'' 
)
SELECT *,(Rolling_vaccination/Population)*100 As Percentage_Vaccinated
FROM PopulationVsVaccination

------2. Creating Temp Table
DROP TABLE IF exists #PopulationVsVaccination
CREATE TABLE #PopulationVsVaccination
(Continent nvarchar(255)
,Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination float,
Rolling_vaccination float)

INSERT INTO #PopulationVsVaccination
SELECT Dea.continent, Dea.location, dea.date, dea.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS float)) OVER (Partition by Dea.location order by Dea.location, Dea.date) AS Rolling_vaccination
FROM CovidVaccinations Vac join CovidDeaths Dea ON
Vac.location = Dea.location AND
Vac.date = Dea.date
WHERE Dea.continent<>'' 

SELECT *, (Rolling_vaccination/Population)*100 As Percentage_Vaccinated
FROM #PopulationVsVaccination
ORDER BY 2,3

-- 11. Creating view for data visualization
CREATE VIEW PopulationVsVaccination AS
SELECT Dea.continent, Dea.location, dea.date, dea.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS float)) OVER (Partition by Dea.location order by Dea.location, Dea.date) AS Rolling_vaccination
FROM CovidVaccinations Vac join CovidDeaths Dea ON
Vac.location = Dea.location AND
Vac.date = Dea.date
WHERE Dea.continent<>'' 


-- 12. View for total Cases Vs Total Deaths in the world 
CREATE VIEW TotalCasesVSDeath AS
SELECT SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_deaths,
CASE 
	WHEN SUM(new_cases) = 0 THEN NULL
	ELSE SUM(new_deaths)/SUM(new_cases) * 100
END AS mortality_rate
FROM CovidDeaths
WHERE continent is not null
