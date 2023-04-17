-- PRIMARY TABLE ------------------------------------------------------------------------------------------------------
/*
 * Primárna tabuľka spája dáta o cenách potravín a priemerných mzdách z Českej republiky
 */

CREATE OR REPLACE TABLE t_Stano_Potrok_project_SQL_primary_final (
SELECT 
    cpib.code AS industry_code, -- Kód priemyselného odvetvia
    cpib.name AS industry, -- Názov priemyselného odvetvia
    cpay.value_type_code, -- Kód určujúci či sa jedná o položku priemerného počtu zamestnancov alebo priemerného platu - v tomto prípade je tabuľka naplnená iba hodnotou 5958 - priemerný plat
    cpay.value AS average_wages, -- Hodnota priemerného platu
    cpay.payroll_year, -- Rok, pre ktorý je daná hodnota meraná
    cpay.payroll_quarter, -- Kvartál daného roku
    cpc.code AS food_category_code, -- Kód kategórie potraviny
    cpc.name AS food_category, -- Kategória potraviny
    cp.value AS price, -- Cena pre danú kategóriu potravín
    cp.date_from AS food_price_measured_from, -- Začiatok merania ceny potraviny
    cp.date_to AS food_price_measured_to, -- Koniec merania ceny potraviny
    CASE
		WHEN (MONTH(cp.date_from) >= 1 AND MONTH(cp.date_from) <= 3 ) THEN 1           -- Táto podmienka priradzuje každému dátumu, v ktorom kvartály sa nachádza
		WHEN (MONTH(cp.date_from) >= 4 AND MONTH(cp.date_from) <= 6 ) THEN 2		   -- dôležité pre úlohu 2. kde je použiť prvé a posledné zrovnateľné odbobie merania platov a cien potravín 
		WHEN (MONTH(cp.date_from) >= 7 AND MONTH(cp.date_from) <= 9 ) THEN 3		   -- kedže platy nemajú určený dátum merania iba kvartál v danom roku bolo potrebné každému dátumu merania potravín
		WHEN (MONTH(cp.date_from) >= 10 AND MONTH(cp.date_from) <= 12 ) THEN 4         -- tento kvartál prideliť aby sa následne v úlohe 2. dal porovnávať kvartál a z neho určiť posledný dátum merania ceny danej potraviny
		ELSE 'missing value'														   -- tým sme dosiahli, že porovnám plat napr. v 4. kvartály s posledným dátumom merania, ktorý sa nachádza rovnako vo 4. kvartály toho istého roka
	END AS price_quarter
FROM czechia_price AS cp
JOIN czechia_price_category cpc -- pripojenie číselníka kategórií potravíny cez kód
    ON cp.category_code = cpc.code 
    AND cp.region_code IS NULL   
RIGHT JOIN czechia_payroll AS cpay  -- použitie RIGHT JOIN mi zabezpečí získanie aj tých údajov, ktoré sa nepodarilo prepojiť podľa roku, 
    ON cpay.payroll_year = YEAR(cp.date_from) -- pretože meranie platov prebiehalo v rokoch 2000-2021 pričom meranie cien potravín iba v rokoch 2006-2018
JOIN czechia_payroll_industry_branch cpib -- spojenie s číselníkov priemyselných odvetví podľa kódu
    ON cpay.industry_branch_code = cpib.code
JOIN czechia_payroll_unit cpu -- spojenie s číselníkom typov 
	ON cpay.unit_code = cpu.code 
JOIN czechia_payroll_value_type cpvt -- spojenie s číselníkom typov priemerný počt zamestnancov / priemerná mzda. Obmedzené iba na priemerné mzdy
	ON cpay.value_type_code = cpvt.code
	AND cpay.value_type_code = 5958
JOIN czechia_payroll_calculation cpc2  -- spojenie s číselníkom kalkulácií. Obmedzený iba na prepočítaný 
	ON cpc2.code = cpay.calculation_code 
	AND cpay.calculation_code = 200 );

-- SECONDARY TABLE -------------------------------------------------------------------------------------------------------------------------

/*
 * Sekundárna tabuľka predstavuje informácie o populácii a ekonomických informáciach ako HDP a gini o jednotlivých Európskych štátoch.
 */

CREATE OR REPLACE TABLE t_Stano_Potrok_project_SQL_secondary_final (
SELECT 
	c.country, 
	c.capital_city,
	c.continent,
	c.population_density,
	e.year,
    round( e.GDP / 1000000, 2 ) as GDP_mil_dollars, 
    e.population
FROM countries c 
JOIN economies e 
    ON c.country = e.country
    AND c.continent = 'Europe');
   
---------------------------------------------------------------------------------------------------------------------------------------------    

-- Výskumné otázky   
   
-- OTÁZKA 1 ------------------------------------------------------------------------------------

/*
 * Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 */

SELECT 
	industry_code,
	industry,
	value_type_code,
	average_wages,
	payroll_year 
FROM t_stano_potrok_project_sql_primary_final tsppspf
WHERE value_type_code = 5958
GROUP BY industry_code, payroll_year;

------------------------------------------------------------------------------------------------

-- OTÁZKA 2 -------------------------------------------------------------------------------------

/*
 * Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
 */

-- Prvé obdobie chleba
SELECT 
	average_wages, -- Priemerné mzdy
	industry_code, -- Kód priemyselného odvetvia
	industry, -- Priemyselné odvetvie
	food_category, -- Kategória potraviny
	food_category_code, -- Kód kategórie potraviny
	price AS food_price, 
	DATE_FORMAT(food_price_measured_from , '%e. %M %Y') AS measured_from, 
	DATE_FORMAT(food_price_measured_to , '%e. %M %Y') AS measured_to, 
	payroll_year, 
	payroll_quarter, -- Kvartál meranej priemernej mzdy, nakoľko zisťujem prvé porovnateľné obdobie bude sa jednať o 1. kvartál
	price_quarter, -- Kvartál meranie ceny potraviny
	ROUND(average_wages/price,2) AS affordable_amount_of_food -- Výpočet, koľko je možné kúpiť kg chleba za priemernú mzdu v danom odvetví, zaokrúhlenie na 2 desatiny
FROM t_stano_potrok_project_sql_primary_final tsppspf 
WHERE food_category_code = '111301' AND price_quarter = ( -- Podmienka ohraničujúca, že hľadám iba chleba
		SELECT price_quarter 								-- Vnorený SELECT, ktorý mi usporiada všetky merania chleba od najmenšieho a vyberie iba prvý záznam. Tak získam úplne prvé meranie v prvom roku
			FROM t_stano_potrok_project_sql_primary_final tsppspf2 
			WHERE food_category_code = '111301'
			ORDER BY food_price_measured_from ASC
			LIMIT 1)  AND 
			food_price_measured_from = 
			(SELECT min(food_price_measured_from) -- Vnorený SELECT, ktorý vyberiem minimálny dátum v prvom kvartály roku
			FROM t_stano_potrok_project_sql_primary_final tsppspf3
			WHERE food_category_code = '111301')
GROUP BY industry_code  -- Zlúčené podľa odvetví
ORDER BY industry_code ASC; -- Usporiadané podľa odvetví

-- Prvé obdobie mlieko
SELECT 
	average_wages, -- Priemerné mzdy
	industry_code, -- Kód priemyselného odvetvia
	industry, -- Priemyselné odvetvie
	food_category, -- Kategória potraviny
	food_category_code, -- Kód kategórie potraviny
	price AS food_price, -- Cena potraviny - v tomto prípade cena za liter mlieka
	DATE_FORMAT(food_price_measured_from, '%e. %M %Y') AS food_price_measured_from, -- Formátovanie na dátum + nájdenie počiatočného a koncového dátumu prvého merania v 1. kvartály roku 2006
    DATE_FORMAT(food_price_measured_to, '%e. %M %Y') AS food_price_measured_to,    
	payroll_year, 
	payroll_quarter, -- Kvartál meranej priemernej mzdy, nakoľko zisťujem prvé porovnateľné obdobie bude sa jednať o 1. kvartál
	price_quarter, -- Kvartál meranie ceny potraviny
	ROUND(average_wages/price,2) AS affordable_amount_of_food -- Výpočet, koľko je možné kúpiť litrov mlieka za priemernú mzdu v danom odvetví, zaokrúhlenie na 2 desatiny
FROM t_stano_potrok_project_sql_primary_final tsppspf 
WHERE food_category_code = '114201' AND price_quarter = ( -- Podmienka ohraničujúca, že hľadám iba mlieko
		SELECT price_quarter 							  -- Vnorený SELECT, ktorý mi usporiada všetky merania mlieka od najmenšieho a vyberie iba prvý záznam. Tak získam úplne prvé meranie v prvom roku
			FROM t_stano_potrok_project_sql_primary_final tsppspf2 
			WHERE food_category_code = '114201'
			ORDER BY food_price_measured_from ASC
			LIMIT 1) AND 
			food_price_measured_from = 
			(SELECT min(food_price_measured_from) -- Vnorený SELECT, ktorý vyberiem minimálny dátum v prvom kvartály roku
			FROM t_stano_potrok_project_sql_primary_final tsppspf3
			WHERE food_category_code = '114201') 
GROUP BY industry_code  -- Zlúčené podľa odvetví
ORDER BY industry_code ASC; -- Usporiadané podľa odvetví


-- Posledné obdobie chleba
SELECT 
	average_wages,
	industry_code, 
	industry, 
	food_category, 
	food_category_code, 
	price AS food_price, 
	DATE_FORMAT(food_price_measured_from, '%e. %M %Y') AS food_price_measured_from, 
    DATE_FORMAT(food_price_measured_to, '%e. %M %Y') AS food_price_measured_to, 
	payroll_year, 
	payroll_quarter, 
	price_quarter,
	ROUND(average_wages/price,2) AS affordable_amount_of_food
FROM t_stano_potrok_project_sql_primary_final tsppspf 
WHERE food_category_code = '111301' AND payroll_quarter  = (
		SELECT price_quarter 
			FROM t_stano_potrok_project_sql_primary_final tsppspf2 
			WHERE food_category_code = '111301'
			ORDER BY food_price_measured_from DESC
			LIMIT 1)
			AND 
			food_price_measured_from = 
			(SELECT MAX(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3
			WHERE food_category_code = '111301')
GROUP BY industry_code 
ORDER BY industry_code ASC;

-- Posledné obdobie mlieko
SELECT 
	average_wages,
	industry_code, 
	industry, 
	food_category, 
	food_category_code, 
	price AS food_price, 
	DATE_FORMAT(MAX(food_price_measured_from), '%e. %M %Y') AS food_price_measured_from, 
    DATE_FORMAT(MAX(food_price_measured_to), '%e. %M %Y') AS food_price_measured_to, 
	max(payroll_year), 
	max(payroll_quarter) , 
	price_quarter,
	ROUND(average_wages/price,2) AS affordable_amount_of_food
FROM t_stano_potrok_project_sql_primary_final tsppspf 
WHERE food_category_code = '114201' AND payroll_quarter = (
		SELECT price_quarter 
			FROM t_stano_potrok_project_sql_primary_final tsppspf2 
			WHERE food_category_code = '114201'
			ORDER BY food_price_measured_from DESC
			LIMIT 1)
			AND 
			food_price_measured_from = 
			(SELECT MAX(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3
			WHERE food_category_code = '114201')
GROUP BY industry_code 
ORDER BY industry_code ASC;

------------------------------------------------------------------------------------------------

-- OTÁZKA 3 -------------------------------------------------------------------------------------

/*
 * Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 */

SELECT 
	tsppspf.food_category_code,
	tsppspf.food_category,
	YEAR(tsppspf.food_price_measured_from) AS year,
	YEAR(tsppspf2.food_price_measured_from) AS prev_year,
	tsppspf.price AS price_in_actual_year,
	tsppspf2.price AS price_in_prev_year,
	ROUND((tsppspf.price - tsppspf2.price ) / tsppspf2.price * 100, 2 ) AS price_growth
FROM t_stano_potrok_project_sql_primary_final tsppspf 
JOIN t_stano_potrok_project_sql_primary_final tsppspf2 
	ON tsppspf.food_category_code = tsppspf2.food_category_code
		AND YEAR(tsppspf.food_price_measured_from) = YEAR(tsppspf2.food_price_measured_from)+1
		AND tsppspf.food_price_measured_from = 
			(SELECT max(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3 
				WHERE YEAR(food_price_measured_from) = YEAR(tsppspf.food_price_measured_from) 
				AND tsppspf3.payroll_quarter = 4)  
		AND tsppspf2.food_price_measured_from = 
			(SELECT max(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3 
				WHERE YEAR(food_price_measured_from) = YEAR(tsppspf2.food_price_measured_from) 
				AND tsppspf3.payroll_quarter = 4)  
		AND YEAR(tsppspf.food_price_measured_from) < 2019
GROUP BY food_category_code ,YEAR(tsppspf.food_price_measured_from), YEAR(tsppspf2.food_price_measured_from);


-- OTÁZKA 4 -------------------------------------------------------------------------------------------------------------------------------

/*
 * Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 */

SELECT 
	tsppspf.food_category_code,
	tsppspf.food_category,
	YEAR(tsppspf.food_price_measured_from) AS year,
	YEAR(tsppspf2.food_price_measured_from) AS prev_year,
	tsppspf.price AS price_in_actual_year,
	tsppspf2.price AS price_in_prev_year,
	ROUND((tsppspf.price - tsppspf2.price ) / tsppspf2.price * 100, 2 ) AS price_growth,
	tsppspf.industry_code,
	tsppspf.industry,
	tsppspf.payroll_year AS payroll_year,
	tsppspf2.payroll_year AS payroll_prev_year,
	tsppspf.average_wages AS average_wages,
	tsppspf2.average_wages AS average_wages_prev_year,
	ROUND((tsppspf.average_wages - tsppspf2.average_wages ) / tsppspf2.average_wages * 100, 2 ) AS average_wages_growth,
	(ROUND((tsppspf.price - tsppspf2.price ) / tsppspf2.price * 100, 2 ) - ROUND((tsppspf.average_wages - tsppspf2.average_wages ) / tsppspf2.average_wages * 100, 2 )) AS prices_wages_difference
FROM t_stano_potrok_project_sql_primary_final tsppspf 
JOIN t_stano_potrok_project_sql_primary_final tsppspf2 
	ON tsppspf.food_category_code = tsppspf2.food_category_code
		AND YEAR(tsppspf.food_price_measured_from) = YEAR(tsppspf2.food_price_measured_from)+1
		AND tsppspf.food_price_measured_from = 
			(SELECT max(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3 
				WHERE YEAR(food_price_measured_from) = YEAR(tsppspf.food_price_measured_from) 
				AND tsppspf3.payroll_quarter = 4)  
		AND tsppspf2.food_price_measured_from = 
			(SELECT max(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3 
				WHERE YEAR(food_price_measured_from) = YEAR(tsppspf2.food_price_measured_from) 
				AND tsppspf3.payroll_quarter = 4)  
		AND YEAR(tsppspf.food_price_measured_from) < 2019
		AND tsppspf.payroll_quarter = 4
		AND tsppspf2.payroll_quarter = 4
		AND tsppspf.payroll_year = YEAR(tsppspf.food_price_measured_from)
		AND tsppspf2.payroll_year = YEAR(tsppspf2.food_price_measured_from)
		AND tsppspf.industry_code = tsppspf2.industry_code
GROUP BY food_category_code ,YEAR(tsppspf.food_price_measured_from), YEAR(tsppspf2.food_price_measured_from), industry_code, tsppspf.payroll_year, tsppspf2.payroll_year
ORDER BY prices_wages_difference DESC;


-- OTÁZKA 5 ---------------------------------------------------------------------------------------------------------------------------

/*
 * Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
 */


/*
 * Vytvorenie pomocnej tabuľky pre zobrazenie medziroceho narastu HDP pre Českú republiku
 */
CREATE OR REPLACE TABLE t_Stano_Potrok_project_SQL_CR_HDP (
SELECT 
e.country, 
e.year, 
e2.year as prev_year,
e.GDP AS GDP,
e2.GDP AS prev_year_GDP,
round( ( e.GDP - e2.GDP ) / e2.GDP * 100, 2 ) as GDP_growth
FROM economies e 
JOIN economies e2 
    ON e.country = e2.country 
    AND e.year = e2.year + 1
	AND e.country = 'Czech republic');

/*
 * Select, ktorý nám umožní zobraziť prepojenie dát o cenách potravín, platov a HDP.
 * Pre vypracovanie otázky som daný select použil pre vytvorenie testovacej tabuľky, z ktorej som následne filtroval potrebné údaje a sledoval vývoj platov a cien voči HDP za daný rok. 
 */
CREATE OR REPLACE TABLE t_Stano_Potrok_project_SQL_ULOHA_5 (
SELECT 
	tsppspf.food_category_code,
	tsppspf.food_category,
	YEAR(tsppspf.food_price_measured_from) AS year,
	YEAR(tsppspf2.food_price_measured_from) AS prev_year,
	tsppspf.price AS price_in_actual_year,
	tsppspf2.price AS price_in_prev_year,
	ROUND((tsppspf.price - tsppspf2.price ) / tsppspf2.price * 100, 2 ) AS price_growth,
	tsppspf.industry_code,
	tsppspf.industry,
	tsppspf.payroll_year AS payroll_year,
	tsppspf2.payroll_year AS payroll_prev_year,
	tsppspf.average_wages AS average_wages,
	tsppspf2.average_wages AS average_wages_prev_year,
	ROUND((tsppspf.average_wages - tsppspf2.average_wages ) / tsppspf2.average_wages * 100, 2 ) AS average_wages_growth,
	(ROUND((tsppspf.price - tsppspf2.price ) / tsppspf2.price * 100, 2 ) - ROUND((tsppspf.average_wages - tsppspf2.average_wages ) / tsppspf2.average_wages * 100, 2 )) AS prices_wages_difference,
	tsppsch.`year` AS GDP_year,
	tsppsch.prev_year AS GDP_prev_year,
	tsppsch.GDP,
	tsppsch.prev_year_GDP,
	tsppsch.GDP_growth 
FROM t_stano_potrok_project_sql_primary_final tsppspf 
JOIN t_stano_potrok_project_sql_primary_final tsppspf2 
	ON tsppspf.food_category_code = tsppspf2.food_category_code
		AND YEAR(tsppspf.food_price_measured_from) = YEAR(tsppspf2.food_price_measured_from)+1
		AND tsppspf.food_price_measured_from = 
			(SELECT max(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3 
				WHERE YEAR(food_price_measured_from) = YEAR(tsppspf.food_price_measured_from) 
				AND tsppspf3.payroll_quarter = 4)  
		AND tsppspf2.food_price_measured_from = 
			(SELECT max(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3 
				WHERE YEAR(food_price_measured_from) = YEAR(tsppspf2.food_price_measured_from) 
				AND tsppspf3.payroll_quarter = 4)  
		AND YEAR(tsppspf.food_price_measured_from) < 2019
		AND tsppspf.payroll_quarter = 4
		AND tsppspf2.payroll_quarter = 4
		AND tsppspf.payroll_year = YEAR(tsppspf.food_price_measured_from)
		AND tsppspf2.payroll_year = YEAR(tsppspf2.food_price_measured_from)
		AND tsppspf.industry_code = tsppspf2.industry_code
JOIN t_stano_potrok_project_sql_cr_hdp tsppsch 
	ON tsppspf.payroll_year = tsppsch.`year`
	AND tsppspf2.payroll_year = tsppsch.prev_year
GROUP BY food_category_code ,YEAR(tsppspf.food_price_measured_from), YEAR(tsppspf2.food_price_measured_from), industry_code, tsppspf.payroll_year, tsppspf2.payroll_year);



-- SELECT pre zobrazenie prehľadu cien
SELECT 
	food_category,
	`year`,
	prev_year,
	price_in_actual_year, 
	price_in_prev_year, 
	price_growth,
	GDP, 
	prev_year_GDP , 
	GDP_growth
FROM t_stano_potrok_project_sql_uloha_5 tsppsu
GROUP BY food_category, `year`
ORDER BY `year`;

-- SELECT pre zozbazenie prehľadu platov

SELECT 
	industry ,
	payroll_year,
	payroll_prev_year,
	average_wages,
	average_wages_prev_year,
	average_wages_growth,
	GDP, 
	prev_year_GDP , 
	GDP_growth
FROM t_stano_potrok_project_sql_uloha_5 tsppsu
GROUP BY industry, payroll_year
ORDER BY payroll_year;
