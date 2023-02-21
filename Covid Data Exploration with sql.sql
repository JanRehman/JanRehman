/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select TOP 1 * 
from PortfolioProject..CovidVaccinations
--Order by 3,4

-- 1. Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
--Where continent is not null 
order by 1,2


-- 2. Total Cases vs Total Deaths
-- Shows likelihood of dying if you get covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%norway%'
and continent is not null 
order by 1,2

-- 3. Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, Date, Population, total_cases,
	(total_cases/population)*100 as PercentPopulationInfected
	From PortfolioProject..CovidDeaths
	--Where location like '%states%'
	order by 1,2

-- 4.Countries with Highest Infection Rate compared to Population
-- Which countries have had the highest number of COVID-19 cases and deaths over time?

Select Location, Population, 
	MAX(total_cases) as HighestInfectionCount,  
	Max((total_cases/population))*100 as PercentPopulationInfected
	From PortfolioProject..CovidDeaths
	--Where location like '%states%'
	Group by Location, Population
	order by PercentPopulationInfected desc

-- Countries with highest death over time

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%norway%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- 5.LETS BREAK THINGS DOWN BY CONTINENT
-- How has the COVID-19 pandemic affected different regions of the world?
-- Showing continent with Highest Death count per Population

Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%norway%'
Where continent is null 
Group by location
order by TotalDeathCount desc


--7. Global numbers

Select SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
	where continent is not null 
	order by 1,2

-- 8. Looking at total population vs vaccinations
-- SUM(CONVERT(INT, vac.new_vaccinations))

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) 
as RollingPeopleVaccinated, 
--(RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3
-- I want to do this (RollingPeopleVaccinated/population)*100, but in my query 8, it wont go.
-- It is not possible to create a coloum and use the exact same colum to create a new colum in same query.
-- We can solve it by CTE method or TEMP table. I explore both of the options under.
-- 9. CTE METHOD

With PopvsVaC (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null)

Select *, (RollingPeopleVaccinated/population)*100
from PopvsVac


-- TEMP table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

--Some questions
--How has the vaccine rollout impacted the spread of COVID-19?
SELECT dea.location, dea.date, dea.total_cases, vac.people_vaccinated, vac.people_fully_vaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.location IN ('United States', 'Norway', 'Pakistan')
ORDER BY dea.location, dea.total_cases DESC

-- What factors are associated with higher rates of COVID-19 transmission and mortality?
SELECT TOP 100 location,population_density, 
	median_age, aged_65_older, 
	gdp_per_capita, diabetes_prevalence, 
	cardiovasc_death_rate, new_cases,
	cast(total_deaths as int) as TotalDeaths
from PortfolioProject..CovidDeaths
Order BY 1 desc,8 desc,9 desc
