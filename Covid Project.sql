--to view tables
select*
from [Covid Project]..deaths
--order as desired
order by 3,4
select*
from [Covid Project]..vaccinations
order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from [Covid Project]..deaths
order by 1,2

--finding DeathRate
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from [Covid Project]..deaths
--to find a particular country
where location like 'ind%'
order by 1,2

--finding CaseRate
select location, date, total_cases,population, (total_cases/population)*100 as CaseRate
from [Covid Project]..deaths
--where location like 'india'
order by 1,2

--finding max CaseRate
select location, max((total_cases/population))*100 as CaseRate, population
from [Covid Project]..deaths
group by location, population
order by 2 desc

--finding max DeathRate
select location, max((total_deaths/population))*100 as DeathRate, population
from [Covid Project]..deaths
group by location, population
order by 2 desc

--finding max DeathCount
--casting total_deaths as int
select location, max(cast(total_deaths as int))as DeathCount
from [Covid Project]..deaths
--eliminating world & continental segregations (nulls)
where continent is not null
group by location
order by 2 desc

--continentwise breakdown
select continent, sum(cast(total_deaths as int))as DeathCount
from [Covid Project]..deaths
where continent is not null
group by continent
order by 2 desc

--global breakdown
select sum(total_cases)as CaseCount, sum(cast(total_deaths as int))as DeathCount, (sum(cast(total_deaths as int))/(sum(total_cases))*100) as DeathRate
from [Covid Project]..deaths
where continent is not null


--viewing total population vs vaccinations
--by joining deaths & vaccinations table
select dea.continent, dea.location, dea.population, dea.date, vax.new_vaccinations
from [Covid Project]..deaths dea						--alias dea for death
join [Covid Project]..vaccinations vax					--alias vax for vaccination
	on dea.location=vax.location
	and dea.date=vax.date
where dea.continent is not null
	and dea.location like 'india'
order by 2,4

--looking at cumulative vaccinations
select dea.continent, dea.location, dea.population, dea.date, vax.new_vaccinations,
	--converting vax.new_vaccinations as bigint
	sum(convert(bigint, vax.new_vaccinations))
	over (partition by dea.location
		order by dea.date) as CumulativeVaccinations
from [Covid Project]..deaths dea
join [Covid Project]..vaccinations vax
	on dea.location=vax.location
	and dea.date=vax.date
where dea.continent is not null
	--and dea.location like 'india'
order by 2,4

--looking at cumulative vaccinations along w/ VaxRate
--using cte
with CumulativeVaxTable(Continent, Location, Population, Date, NewVaccinations, CumulativeVaccinations)
as
(
select dea.continent, dea.location, dea.population, dea.date, vax.new_vaccinations,
	sum(convert(bigint, vax.new_vaccinations))
	over (partition by dea.location
		order by dea.date) as CumulativeVaccinations
from [Covid Project]..deaths dea
join [Covid Project]..vaccinations vax
	on dea.location=vax.location
	and dea.date=vax.date
where dea.continent is not null
)
select*,(CumulativeVaccinations/Population)*100 as VaxRate
from CumulativeVaxTable
--where Location like 'india'

--using temp table (stored in master database)
--drop table if exists, incase alterations to the table need be made
drop table if exists CumulativeVaccinationTable
create table CumulativeVaccinationTable(
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
NewVaccinations numeric,
CumulativeVaccinations numeric
)
insert into CumulativeVaccinationTable
select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	sum(convert(bigint, vax.new_vaccinations))
	over (partition by dea.location
		order by dea.date) as CumulativeVaccinations
from [Covid Project]..deaths dea
join [Covid Project]..vaccinations vax
	on dea.location=vax.location
	and dea.date=vax.date
where dea.continent is not null

select*,(CumulativeVaccinations/Population)*100 as VaxRate
from CumulativeVaccinationTable

--creating view
create view CumVaxRate as
select*,(CumulativeVaccinations/Population)*100 as VaxRate
from CumulativeVaccinationTable

--viewing view
select*
from CumVaxRate
