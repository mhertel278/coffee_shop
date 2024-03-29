/* Exploratory Analysis and Data Cleaning
*/

--examine duplicate transaction_ids
-- examine rows where transaction_id is duped
with row_counter as (
SELECT * , COUNT(*) OVER (PARTITION BY transaction_id) as row_count
FROM transactions
ORDER BY 1,2,4)

SELECT * FROM row_counter
WHERE row_count > 1
;

--how many stores have sales
SELECT DISTINCT sales_outlet_id
FROM transactions

/*
High Level Analysis
*/
-- Question 1. What are the KPI values company wide?
SELECT COUNT(DISTINCT CONCAT(t.transaction_id, t.transaction_date, t.sales_outlet_id)) as total_transactions
	, SUM (t.line_item_amount) as dollars_sold_tot
	, SUM (t.quantity) as units_sold_total
	, ROUND(SUM (t.line_item_amount - (p.current_wholesale_price * t.quantity))::NUMERIC,2) as profit_dollars_total
FROM transactions t
JOIN product p
ON t.product_id = p.product_id
;
--Top line by store CORRECTED
SELECT t.sales_outlet_id 
	, COUNT(DISTINCT CONCAT(t.transaction_id, t.transaction_date, t.sales_outlet_id)) as total_transactions
	, SUM (t.line_item_amount) as dollars_sold_tot
	, SUM (t.quantity) as units_sold_total
	, ROUND(SUM (t.line_item_amount - (p.current_wholesale_price * t.quantity))::NUMERIC,2) as profit_dollars_total
FROM transactions t
JOIN product p
ON t.product_id = p.product_id
GROUP BY 1
ORDER BY 1
;

--Top Line by product category ranked CORRECTED
SELECT p.product_category
	, COUNT(DISTINCT CONCAT(t.transaction_id, t.transaction_date, t.sales_outlet_id)) as total_transactions
	, SUM (t.line_item_amount) as dollars_sold_tot
	, SUM (t.quantity) as units_sold_total
	, ROUND(SUM (t.line_item_amount - (p.current_wholesale_price * t.quantity))::NUMERIC,2) as profit_dollars_total
FROM transactions t
JOIN product p
ON t.product_id = p.product_id
GROUP BY 1
ORDER BY 3 DESC
;

-- Question 2. What is the week over week change in KPIs throughout the month?
WITH weekly as (
	SELECT EXTRACT ('week' FROM transaction_date) AS week
		, COUNT(DISTINCT CONCAT(transaction_id, transaction_date, sales_outlet_id)) as total_transactions
		, SUM (t.line_item_amount) as dollars_sold_tot
		, SUM (t.quantity) as units_sold_total
		, ROUND(SUM (t.line_item_amount - (p.current_wholesale_price * t.quantity))::NUMERIC,2) as profit_dollars_total
	FROM transactions t
	JOIN product p
	ON t.product_id = p.product_id
	GROUP BY 1
	ORDER BY 1
)

SELECT week
	, total_transactions
	, ROUND(((total_transactions - LAG (total_transactions) OVER())::NUMERIC / total_transactions*100),1) AS trans_p
	, dollars_sold_tot
	, ROUND(((dollars_sold_tot - LAG (dollars_sold_tot) OVER())::NUMERIC / dollars_sold_tot*100),1) AS sales_dollars_pct_wow
	, units_sold_total
	, ROUND(((units_sold_total - LAG (units_sold_total) OVER())::NUMERIC / units_sold_total*100),1) AS units_pct_wow
	, profit_dollars_total
	, ROUND(((profit_dollars_total - LAG (profit_dollars_total) OVER())::NUMERIC / profit_dollars_total*100),1) AS profit_pct_wow
FROM weekly
WHERE week != 18
;


/*
grouping transactions by store and product group to join to
unpivoted sales goals and calculate the actual vs goal
*/

WITH category_sales as (
	SELECT t.sales_outlet_id
		, p.product_group
		, SUM(t.quantity) as units
	FROM transactions t
	JOIN product p
	ON t.product_id = p.product_id
	GROUP BY 1,2
)
SELECT c.sales_outlet_id 
	, c.product_group
	, c.units
	, t.goal
	,(c.units-t.goal) AS act_vs_goal
	, ROUND((c.units-t.goal)/t.goal::NUMERIC * 100,2) as act_vs_goal_perc
FROM category_sales c
INNER JOIN sales_targets_long t
ON c.sales_outlet_id || c.product_group = t.sales_outlet_id || t.product_group
ORDER BY 1,2
;

-- Company wide actual vs target by group
WITH group_sales as (
	SELECT p.product_group
		, SUM(t.quantity) as units
	FROM transactions t
	JOIN product p
	ON t.product_id = p.product_id
	WHERE t.sales_outlet_id IN (3,5,8)
	GROUP BY 1
)
,
group_targets AS(
	SELECT product_group
		, SUM (goal) AS goal
	FROM sales_targets_long
	WHERE sales_outlet_id in (3,5,8)
	GROUP BY 1
)
SELECT gs.product_group
	, gs.units
	, gt.goal
	,(gs.units-gt.goal) AS act_vs_goal
	, ROUND((gs.units-gt.goal)/gt.goal::NUMERIC * 100,2) as act_vs_goal_perc
FROM group_sales gs
INNER JOIN group_targets gt
ON gs.product_group = gt.product_group
ORDER BY 1
;


/* 
Analyze pastry waste
*/

-- see if additional pastries get made throughout the day or if start num is total daily inv

SELECT *
FROM pastry_inventory
WHERE start_of_day != (quantity_sold + waste)
;

-- create cleaned inventory table with anomolies dropped
SELECT * 
INTO pastry_inv_clean
FROM pastry_inventory
WHERE start_of_day = quantity_sold + waste
;

-- find overall sell_through perc by product

SELECT i.product_id
	, p.product
	, ROUND(SUM(CAST(i.quantity_sold as  NUMERIC))
		/SUM(CAST(i.quantity_sold as NUMERIC) + CAST(i.waste as NUMERIC)) 
			* 100, 2) as sell_through_perc
FROM pastry_inv_clean i
JOIN product p
ON i.product_id = p.product_id
GROUP BY 1, 2
ORDER BY 3 ASC
;

-- find waste by store
SELECT sales_outlet_id
	, ROUND(SUM(CAST(quantity_sold as  NUMERIC))
		/SUM(CAST(quantity_sold as NUMERIC) + CAST(waste as NUMERIC))
			 * 100, 2) as sell_through_perc
FROM pastry_inv_clean

GROUP BY 1
ORDER BY 2 ASC
;
-- find promo dates
SELECT MIN(transaction_date) AS promo_start
	, MAX(transaction_date) AS prome_end
FROM transactions 
WHERE promo_item_yn = 'Y'
;

--

with promo_window as (SELECT *, 
	CASE WHEN transaction_date < '2019-04-15' THEN 'before_promo'
	ELSE 'during_promo' END as promo_status
FROM pastry_inv_clean)

SELECT pw.product_id
	, p.product
	, pw.promo_status
	, ROUND(SUM(CAST(pw.quantity_sold as  NUMERIC))
		/SUM(CAST(pw.quantity_sold as NUMERIC) + CAST(pw.waste as NUMERIC)) 
			* 100, 2) as sell_through_perc
FROM promo_window pw
JOIN product p
ON pw.product_id = p.product_id 
GROUP BY 1,2,3
ORDER BY 1,3
;


