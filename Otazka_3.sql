-- OTÁZKA 3 -------------------------------------------------------------------------------------

/*
 * Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 */

SELECT
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
GROUP BY food_category, YEAR, prev_year, price_in_actual_year, price_in_prev_year, price_growth;
