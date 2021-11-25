-- Looking at total deaths vs population
SELECT location, date_recorded, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY location, date_recorded;

-- Looking at Total Cases vs Total Deaths
SELECT location, date_recorded, total_cases, total_deaths, (total_deaths::FLOAT/total_cases::FLOAT) * 100 AS death_rate
FROM covid_deaths
WHERE location ILIKE '%states%';

-- Looking at total cases vs population
-- Shows what percentage of the population has contracted covid-19
SELECT location, date_recorded, total_cases, population, (total_cases::FLOAT/population::FLOAT) * 100 AS infection_rate
FROM covid_deaths
WHERE location ILIKE '%nigeria%';

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases::FLOAT/population::FLOAT)) * 100 AS infection_rate
FROM covid_deaths
GROUP BY location, population
ORDER BY MAX((total_cases::FLOAT/population::FLOAT)) * 100 DESC;

-- Countries with the highest death counts
SELECT location, MAX(total_deaths) AS highest_deaths_number
FROM covid_deaths
GROUP BY location
HAVING MAX(total_deaths) != 0 AND MAX(total_deaths) < 800000
ORDER BY MAX(total_deaths) DESC;

-- Continents with the highest death counts
SELECT continent, MAX(total_deaths) AS highest_deaths_number
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY MAX(total_deaths) DESC;

-- Looking at daily global numbers
SELECT date_recorded, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, SUM(new_deaths::FLOAT)/SUM(new_cases::FLOAT) * 100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date_recorded
ORDER BY date_recorded;

-- Looking at total global numbers
SELECT SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, SUM(new_deaths::FLOAT)/SUM(new_cases::FLOAT) * 100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL;

-- Total population vs vaccinations
SELECT deaths.continent, deaths.location, deaths.date_recorded, deaths.population, vaccinations.new_vaccinations,
SUM(vaccinations.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date_recorded)
AS rolling_vaccinated
FROM covid_vaccinations vaccinations
INNER JOIN covid_deaths deaths
ON vaccinations.location = deaths.location AND vaccinations.date_recorded = deaths.date_recorded
WHERE deaths.continent IS NOT NULL
ORDER BY deaths.location, deaths.date_recorded;

-- Using a CTE to show the rolling sum of new vaccinations for all locations
WITH population_vs_vaccination (continent, location, date_recorded, population, new_vaccinations, rolling_vaccinated)
AS
(
SELECT deaths.continent, deaths.location, deaths.date_recorded, deaths.population, vaccinations.new_vaccinations,
SUM(vaccinations.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date_recorded)
AS rolling_vaccinated
FROM covid_vaccinations vaccinations
INNER JOIN covid_deaths deaths
ON vaccinations.location = deaths.location AND vaccinations.date_recorded = deaths.date_recorded
WHERE deaths.continent IS NOT NULL
	)
SELECT *, (rolling_vaccinated::FLOAT/population::FLOAT) * 100
FROM population_vs_vaccination;

-- Create a view to store the rolling sum of new vaccinations for later use
CREATE OR REPLACE VIEW percent_population_vaccinated AS
SELECT deaths.continent, deaths.location, deaths.date_recorded, deaths.population, vaccinations.new_vaccinations,
SUM(vaccinations.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date_recorded)
AS rolling_vaccinated
FROM covid_vaccinations vaccinations
INNER JOIN covid_deaths deaths
ON vaccinations.location = deaths.location AND vaccinations.date_recorded = deaths.date_recorded
WHERE deaths.continent IS NOT NULL;

-- Ranking locations based on the maximum number of deaths
SELECT location, MAX(total_cases) AS max_cases,  MAX(total_deaths) AS max_deaths,
RANK() OVER (ORDER BY MAX(total_deaths) DESC) AS max_deaths_rank
FROM covid_deaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location
HAVING MAX(total_deaths) < 800000
ORDER BY MAX(total_cases) DESC;

-- Calculating the 7 day running average for new cases
SELECT location, date_recorded, new_cases, 
AVG(new_cases) OVER (PARTITION BY location ORDER BY date_recorded ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
AS running_average
FROM covid_deaths;

-- Top 10 countries with the highest death rates
WITH cases_vs_deaths AS
(
SELECT location, MAX(total_cases) AS max_cases,  MAX(total_deaths) AS max_deaths
FROM covid_deaths
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location
HAVING MAX(total_deaths) < 800000
) 
SELECT location, (max_deaths::FLOAT/max_cases::FLOAT) * 100 AS death_rate
FROM cases_vs_deaths
ORDER BY death_rate DESC
LIMIT 10;



