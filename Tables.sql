-- PRIMARY TABLE ------------------------------------------------------------------------------------------------------
/*
 * Primárna tabuľka spája dáta o cenách potravín a priemerných mzdách z Českej republiky
 */

CREATE OR REPLACE TABLE t_Stano_Potrok_project_SQL_primary_final (
SELECT 
	cpib.code AS industry_code,
	cpib.name AS industry,
	cpay.value_type_code,
	cpay.value AS average_wages,
	cpay.payroll_year,
	cpay.payroll_quarter,
	cpc.code AS food_category_code,
	cpc.name AS food_category,
	cp.value AS price,
	cp.date_from AS food_price_measured_from,
	cp.date_to AS food_price_measured_to,
	CASE
		WHEN (MONTH(cp.date_from) >= 1 AND MONTH(cp.date_from) <= 3 ) THEN 1
		WHEN (MONTH(cp.date_from) >= 4 AND MONTH(cp.date_from) <= 6 ) THEN 2
		WHEN (MONTH(cp.date_from) >= 7 AND MONTH(cp.date_from) <= 9 ) THEN 3
		WHEN (MONTH(cp.date_from) >= 10 AND MONTH(cp.date_from) <= 12 ) THEN 4
		ELSE 'missing value'
	END AS price_quarter
FROM czechia_price AS cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code 
	AND cp.region_code IS NULL   
RIGHT JOIN czechia_payroll AS cpay 
	ON cpay.payroll_year = YEAR(cp.date_from)
JOIN czechia_payroll_industry_branch cpib
	ON cpay.industry_branch_code = cpib.code
JOIN czechia_payroll_unit cpu 
	ON cpay.unit_code = cpu.code 
JOIN czechia_payroll_value_type cpvt
	ON cpay.value_type_code = cpvt.code
	AND cpay.value_type_code = 5958
JOIN czechia_payroll_calculation cpc2 
	ON cpc2.code = cpay.calculation_code 
	AND cpay.calculation_code = 200 );

-- SECONDARY TABLE ---------------------------------------------------------------

/*
 * Sekundárna tabuľka predstavuje informácie o populácii a ekonomických 
 * informáciach ako HDP a gini o jednotlivých Európskych štátoch.
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
   

