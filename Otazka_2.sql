-- OTÁZKA 2 -------------------------------------------------------------------------------------

/*
 * Kolik je možné si koupit litrů mléka a kilogramů chleba za první a 
 * poslední srovnatelné období v dostupných datech cen a mezd?
 */

-- Prvé obdobie chleba
SELECT
	average_wages,
	industry_code,
	industry,
	food_category,
	price AS food_price,
	ROUND(average_wages/price,2) AS affordable_amount_of_food
FROM t_stano_potrok_project_sql_primary_final tsppspf 
WHERE food_category_code = '111301' 
	AND price_quarter = (
		SELECT price_quarter 							
			FROM t_stano_potrok_project_sql_primary_final tsppspf2 
			WHERE food_category_code = '111301'
			ORDER BY food_price_measured_from ASC
			LIMIT 1)  
	AND food_price_measured_from = (
		SELECT min(food_price_measured_from)
			FROM t_stano_potrok_project_sql_primary_final tsppspf3
			WHERE food_category_code = '111301')
	AND payroll_quarter = 1
GROUP BY industry_code, industry, average_wages, food_category, food_price, affordable_amount_of_food
ORDER BY industry_code ASC;

-- Prvé obdobie mlieko
SELECT 
	average_wages,
	industry_code,
	industry,
	food_category,
	price AS food_price,
	ROUND(average_wages/price,2) AS affordable_amount_of_food
FROM t_stano_potrok_project_sql_primary_final tsppspf 
WHERE food_category_code = '114201' 
	AND price_quarter = (
		SELECT price_quarter
			FROM t_stano_potrok_project_sql_primary_final tsppspf2 
			WHERE food_category_code = '114201'
			ORDER BY food_price_measured_from ASC
			LIMIT 1) 
	AND food_price_measured_from = (
		SELECT min(food_price_measured_from)
			FROM t_stano_potrok_project_sql_primary_final tsppspf3
			WHERE food_category_code = '114201')
	AND payroll_quarter = 1
GROUP BY industry_code, industry, average_wages, food_category, food_price, affordable_amount_of_food
ORDER BY industry_code ASC;


-- Posledné obdobie chleba
SELECT 
	average_wages,
	industry_code, 
	industry, 
	food_category,  
	price AS food_price, 
	ROUND(average_wages/price,2) AS affordable_amount_of_food
FROM t_stano_potrok_project_sql_primary_final tsppspf 
WHERE food_category_code = '111301' 
	AND payroll_quarter  = (
		SELECT price_quarter 
			FROM t_stano_potrok_project_sql_primary_final tsppspf2 
			WHERE food_category_code = '111301'
			ORDER BY food_price_measured_from DESC
			LIMIT 1)
	AND food_price_measured_from = (
		SELECT MAX(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3
			WHERE food_category_code = '111301')
	AND payroll_quarter = 4
GROUP BY industry_code, industry, average_wages, food_category, food_price, affordable_amount_of_food  
ORDER BY industry_code ASC;

-- Posledné obdobie mlieko
SELECT 
	average_wages,
	industry_code, 
	industry, 
	food_category, 
	price AS food_price, 
	ROUND(average_wages/price,2) AS affordable_amount_of_food
FROM t_stano_potrok_project_sql_primary_final tsppspf 
WHERE food_category_code = '114201' 
	AND payroll_quarter = (
		SELECT price_quarter 
			FROM t_stano_potrok_project_sql_primary_final tsppspf2 
			WHERE food_category_code = '114201'
			ORDER BY food_price_measured_from DESC
			LIMIT 1)
	AND food_price_measured_from = (
		SELECT MAX(food_price_measured_from) 
			FROM t_stano_potrok_project_sql_primary_final tsppspf3
			WHERE food_category_code = '114201')
	AND payroll_quarter = 4
GROUP BY industry_code, industry, average_wages, food_category, food_price, affordable_amount_of_food  
ORDER BY industry_code ASC;

