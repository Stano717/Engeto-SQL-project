-- OTÁZKA 4 -------------------------------------------------------------------------------------------------------------------------------

/*
 * Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 */

SELECT
	tsppspf.food_category,
	YEAR(tsppspf.food_price_measured_from) AS year,
	YEAR(tsppspf2.food_price_measured_from) AS prev_year,
	ROUND((tsppspf.price - tsppspf2.price ) / tsppspf2.price * 100, 2 ) AS price_growth,
	tsppspf.industry,
	ROUND((tsppspf.average_wages - tsppspf2.average_wages ) / tsppspf2.average_wages * 100, 2 ) AS average_wages_growth,
	(ROUND((tsppspf.price - tsppspf2.price ) / tsppspf2.price * 100, 2 ) - 
	ROUND((tsppspf.average_wages - tsppspf2.average_wages ) / tsppspf2.average_wages * 100, 2 )) AS prices_wages_difference
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
GROUP BY food_category, YEAR, prev_year, price_growth, industry, average_wages_growth, prices_wages_difference 
ORDER BY prices_wages_difference DESC;

