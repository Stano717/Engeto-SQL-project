-- OTÁZKA 5 ---------------------------------------------------------------------------------------------------------------------------

/*
 * Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, 
 * pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin 
 * či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
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
 * Pre vypracovanie otázky som daný select použil pre vytvorenie testovacej tabuľky, 
 * z ktorej som následne filtroval potrebné údaje a sledoval vývoj platov a cien voči HDP za daný rok. 
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
	(ROUND((tsppspf.price - tsppspf2.price ) / tsppspf2.price * 100, 2 ) - 
	ROUND((tsppspf.average_wages - tsppspf2.average_wages ) / tsppspf2.average_wages * 100, 2 )) AS prices_wages_difference,
	tsppsch.`year` AS GDP_year,
	tsppsch.prev_year AS GDP_prev_year,
	tsppsch.GDP,
	tsppsch.prev_year_GDP,
	tsppsch.GDP_growth 
FROM t_stano_potrok_project_sql_primary_final tsppspf 
JOIN t_stano_potrok_project_sql_primary_final tsppspf2 
	ON tsppspf.food_category_code = tsppspf2.food_category_code
		AND YEAR(tsppspf.food_price_measured_from) = YEAR(tsppspf2.food_price_measured_from)+1
		AND tsppspf.food_price_measured_from = (
			SELECT max(food_price_measured_from) 
				FROM t_stano_potrok_project_sql_primary_final tsppspf3 
				WHERE YEAR(food_price_measured_from) = YEAR(tsppspf.food_price_measured_from) 
				AND tsppspf3.payroll_quarter = 4)  
		AND tsppspf2.food_price_measured_from = (
			SELECT max(food_price_measured_from) 
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
GROUP BY food_category_code, food_category, YEAR, prev_year, price_in_actual_year, price_in_prev_year, price_growth, 
		industry_code, industry, payroll_year, payroll_prev_year, average_wages, average_wages_prev_year, 
		average_wages_growth, prices_wages_difference, GDP_year, GDP_prev_year, GDP, prev_year_GDP, GDP_growth);



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
GROUP BY food_category, `year`, prev_year, price_in_actual_year, price_in_prev_year,price_growth,
		GDP, prev_year_GDP, GDP_growth 
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
GROUP BY industry, payroll_year, payroll_prev_year, average_wages, average_wages_prev_year,
		average_wages_growth, GDP, prev_year_GDP, GDP_growth
ORDER BY payroll_year;
