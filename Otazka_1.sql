-- OTÁZKA 1 ------------------------------------------------------------------------------------

/*
 * Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
 */

SELECT 
	industry_code,
	industry,
	average_wages,
	payroll_year, 
	payroll_quarter
FROM t_stano_potrok_project_sql_primary_final tsppspf
GROUP BY industry_code, industry, average_wages, payroll_year, payroll_quarter
ORDER BY industry_code, payroll_year, payroll_quarter; 