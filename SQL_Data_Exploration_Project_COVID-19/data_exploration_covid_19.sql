/*
Covid 19 Data Exploration from : https://ourworldindata.org/covid-deaths 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

select *
from PortfolioProjectDA..CovidDeaths$
where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

select Location, date, total_cases_per_million, new_cases, total_deaths, population
from PortfolioProjectDA..CovidDeaths$
where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select Location, date, total_cases_per_million,total_deaths, (total_deaths/total_cases_per_million)*100 as DeathPercentage
from PortfolioProjectDA..CovidDeaths$
where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select Location, date, Population, total_cases_per_million,  (total_cases_per_million/population)*100 as PercentPopulationInfected
from PortfolioProjectDA..CovidDeaths$
--where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

select Location, Population, MAX(total_cases_per_million) as HighestInfectionCount,  Max((total_cases_per_million/population))*100 as PercentPopulationInfected
from PortfolioProjectDA..CovidDeaths$
--where location like '%states%'
group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProjectDA..CovidDeaths$
--where location like '%states%'
where continent is not null 
group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProjectDA..CovidDeaths$
--where location like '%states%'
where continent is not null 
group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
from PortfolioProjectDA..CovidDeaths$
--where location like '%states%'
where continent is not null 
--group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProjectDA..CovidDeaths$ dea
Join PortfolioProjectDA..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProjectDA..CovidDeaths$ dea
Join PortfolioProjectDA..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

IF EXISTS (SELECT name from sys.tables where name = '#PercentPopulationVaccinated')
	DROP TABLE  #PercentPopulationVaccinated;

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProjectDA..CovidDeaths$ dea
Join PortfolioProjectDA..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated




-- Creating View to store data for later visualizations ( eg Tableau,Power BI, etc)

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProjectDA..CovidDeaths$ dea
Join PortfolioProjectDA..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 