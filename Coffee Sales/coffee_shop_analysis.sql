/*
grouping transactions by store and product group to join to
unpivoted sales goals and calculate the actual vs goal
*/

WITH category_sales as (SELECT t.sales_outlet_id
	, p.product_group
	, SUM(t.quantity) as units
FROM transactions t
JOIN product p
ON t.product_id = p.product_id
GROUP BY 1,2)

SELECT c.sales_outlet_id 
	, c.product_group
	, c.units
	, t.goal
	,(c.units-t.goal) AS act_vs_goal
	, ROUND((c.units-t.goal)/t.goal::NUMERIC * 100,2) as act_vs_goal_perc
FROM category_sales c
INNER JOIN sales_targets_long t
ON c.sales_outlet_id || c.product_group = t.sales_outlet_id || t.category
ORDER BY 1,2

;

