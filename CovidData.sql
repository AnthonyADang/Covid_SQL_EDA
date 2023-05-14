/*
Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


-------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	* 
FROM 
	PortfolioProjects..CovidDeaths
WHERE 
	continent IS NOT NULL
ORDER BY 
	date, population


-------------------------------------------------------------------------------------------------------------------------------------------
-- Selecting initial Data for queries

SELECT	
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM 
	PortfolioProjects..CovidDeaths
WHERE 
	continent IS NOT NULL
ORDER BY 
	location, date


-------------------------------------------------------------------------------------------------------------------------------------------
-- Total Cases vs Total Deaths 
-- Shows probability of mortality for individuals infected with Covid in each country over time.

SELECT	
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(cast(total_deaths as numeric)/cast(total_cases as numeric))*100 as death_percentage
FROM 
	PortfolioProjects..CovidDeaths
WHERE 
	continent IS NOT NULL
ORDER BY 
	location, date


-------------------------------------------------------------------------------------------------------------------------------------------
-- Total Cases vs Population 
-- Shows percentage of population infected with Covid in each country over time.

SELECT	
	location, 
	date, 
	total_cases, 
	population, 
	(cast(total_cases as numeric)/population)*100 as percent_population_infected
FROM 
	PortfolioProjects..CovidDeaths
--WHERE
--	location like '%states%'
ORDER BY
	location, date


-------------------------------------------------------------------------------------------------------------------------------------------
-- Countries with highest infection rate compared to population

SELECT
	location, 
	population, 
	MAX(total_cases) as HighestInfectionCount, 
	MAX((total_cases/population))*100 as percent_population_infected
From 
	PortfolioProjects..CovidDeaths
--WHERE 
--	location like '%states%'
GROUP BY
	location, population
ORDER BY 
	percent_population_infected desc


-------------------------------------------------------------------------------------------------------------------------------------------
-- Countries with highest death count per population

SELECT
	location,
	MAX(cast(total_deaths as int)) as total_death_count
FROM 
	PortfolioProjects..CovidDeaths
--Where 
--	location like '%states%'
Where 
	continent IS NOT NULL
GROUP BY
	location
ORDER BY 
	total_death_count desc


-------------------------------------------------------------------------------------------------------------------------------------------
-- Showing continents with the highest death count per population

SELECT
	continent, 
	MAX(cast(total_deaths as int)) as total_death_count
FROM 
	PortfolioProjects..CovidDeaths
WHERE 
	continent IS NOT NULL
GROUP BY 
	continent
ORDER BY
	total_death_count desc


-------------------------------------------------------------------------------------------------------------------------------------------
-- Showing global Covid total cases, total deaths, and death percentages

SELECT
	SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM
	PortfolioProjects..CovidDeaths
WHERE
	continent IS NOT NULL
ORDER BY
	total_cases, total_deaths


-------------------------------------------------------------------------------------------------------------------------------------------
-- Total Population vs Vaccinations
-- Showing percentage of population that have received at least one Covid vaccine

SELECT 
	death.continent,
	death.location ,
	death.date,
	death.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (
		PARTITION BY death.location 
		ORDER BY death.date ROWS UNBOUNDED PRECEDING /* rows unbounded preceding added because order by */ 
	) as rolling_people_vaccinated					 /* range window is larger than default value */
FROM 
	PortfolioProjects..CovidDeaths death
JOIN 
	PortfolioProjects..CovidVaccinations vac
		ON death.location = vac.location 
		AND death.date = vac.date
WHERE 
	death.continent IS NOT NULL
ORDER BY 
	death.location, death.date


-------------------------------------------------------------------------------------------------------------------------------------------
-- Usage of CTE to perform calculation on PARTITION BY in previous query
-- Disclaimer, rolling_people_vaccinated percentages go above 100%, this is because new_vaccinations includes
-- persons who have already gotten the Covid vaccination previously. The datasheet already includes a total_people_vaccinated column but
-- I did this as an exercise to learn how to join data and use CTE's.

WITH 
	population_vs_vaccination (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
	as
	(
		Select
			death.continent,
			death.location,
			death.date,
			death.population,
			vac.new_vaccinations,
			SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (
				PARTITION BY death.location 
				ORDER BY death.location, death.date ROWS UNBOUNDED PRECEDING
			) as rolling_people_vaccinated
		FROM 
			PortfolioProjects..CovidDeaths death
		JOIN 
			PortfolioProjects..CovidVaccinations vac
				ON death.location = vac.location 
				AND death.date = vac.date
		WHERE 
			death.continent IS NOT NULL
	)
SELECT 
	*,
	(rolling_people_vaccinated/population)*100 as percent_vaccinated
FROM
	population_vs_vaccination


-------------------------------------------------------------------------------------------------------------------------------------------
-- Using temp tables to perform calculations on PARTITION BY in previous query

DROP TABLE if EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	Rolling_People_Vaccinated numeric
)

INSERT INTO #percent_population_vaccinated
SELECT 
	death.continent, 
	death.location, 
	death.date, 
	death.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (
		PARTITION BY death.location 
		ORDER BY death.location, death.date ROWS UNBOUNDED PRECEDING
	) as rolling_people_vaccinated
--	, (rolling_people_vaccinated/population)*100
FROM 
	PortfolioProjects..CovidDeaths death
Join 
	PortfolioProjects..CovidVaccinations vac
		ON death.location = vac.location
		AND death.date = vac.date
--WHERE death.continent is not null 
--ORDER BY location,date

SELECT 
	*, 
	(rolling_people_vaccinated/population)*100 as Percentage_Rolling_Vaccinated
FROM #percent_population_vaccinated


-------------------------------------------------------------------------------------------------------------------------------------------
-- Creating view to store data for visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT 
	death.continent, 
	death.location, 
	death.date, 
	death.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (
		PARTITION BY death.location 
		ORDER BY death.location, death.date ROWS UNBOUNDED PRECEDING
	) as rolling_people_vaccinated
--	, (rolling_people_vaccinated/population)*100
FROM 
	PortfolioProjects..CovidDeaths death
Join 
	PortfolioProjects..CovidVaccinations vac
		ON death.location = vac.location
		AND death.date = vac.date
WHERE 
	death.continent IS NOT NULL



