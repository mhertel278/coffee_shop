--find number of staff by position at each store
SELECT sales_outlet_id
	, "position"
	, COUNT(*)
FROM staff
WHERE sales_outlet_id IN ('3','5','8')
GROUP BY 1,2
ORDER BY 1 ASC, 2 DESC

;

--Find employee with the company the longest
SELECT s.staff_id
	, s.first_name
	, s.last_name
	, s.position
	, s.start_date
	, s.sales_outlet_id
FROM staff s
WHERE start_date = (SELECT MIN(start_date) 
					FROM staff 
					WHERE sales_outlet_id IN ('3','5','8'))--exclude office,warehouse,and stores with not sales data)
;

--Find employee who is newest
SELECT s.staff_id
	, s.first_name
	, s.last_name
	, s.position
	, s.start_date
	, s.sales_outlet_id
FROM staff s
WHERE start_date = (SELECT MAX(start_date) 
					FROM staff 
					WHERE sales_outlet_id IN ('3','5','8'))--exclude office,warehouse,and stores with not sales data)
;

--Does store with most experienced staff have most $
--get store sales
WITH sales AS(
	SELECT sales_outlet_id::varchar(4)
		, SUM(line_item_amount) as sales_dollars
	FROM transactions
	GROUP BY 1
	)
,
--get stores avg experience
experience AS (
	SELECT 	sales_outlet_id
		, ROUND(AVG('2019-04-30'-start_date)) AS avg_exp_days
	FROM staff
	GROUP BY 1
)
SELECT s.sales_outlet_id
	, s.sales_dollars
	, e.avg_exp_days
FROM sales s
JOIN experience e
ON s.sales_outlet_id = e.sales_outlet_id
ORDER BY 2 DESC
;
--Find staffers with most transactions
SELECT s.staff_id
	, s.first_name
	, s.last_name
	, s.position
	, s.start_date
	, COUNT(DISTINCT(CONCAT(t.transaction_id,t.transaction_date,t.sales_outlet_id))) as trans_count
FROM staff s
JOIN transactions t
ON s.staff_id = t.staff_id
GROUP BY 1,2,3,4,5
ORDER BY 6 DESC
LIMIT 10
;

--FIND staffers with most $ sold

SELECT s.staff_id
	, s.first_name
	, s.last_name
	, s.position
	, s.start_date
	, SUM(t.line_item_amount) as total_sales_dollars
FROM staff s
JOIN transactions t
ON s.staff_id = t.staff_id
GROUP BY 1,2,3,4,5
ORDER BY 6 DESC
LIMIT 10
;

/*
find rank by $_per of newest employee
*/
-- get dollars per transaction for each staff
WITH staff_dpt AS(
	SELECT s.staff_id
		, s.first_name
		, s.last_name
		, s.position
		, s.start_date
		, ROUND(SUM(t.line_item_amount) / COUNT(DISTINCT(CONCAT(t.transaction_id,t.transaction_date,t.sales_outlet_id))),2) as dollars_per_trans
	FROM staff s
	JOIN transactions t
	ON s.staff_id = t.staff_id
	GROUP BY 1,2,3,4,5
	)
,
-- rank staff
ranked AS(
	SELECT *
	, RANK() OVER(ORDER BY dollars_per_trans DESC)
	FROM staff_dpt
	)
, 
-- get start date of newest employeet
newest AS (
	SELECT MAX(start_date) 
			 FROM staff 
			 WHERE sales_outlet_id IN ('3','5','8')
)

SELECT * 
FROM ranked
WHERE start_date = (SELECT * FROM newest)
;

/*
find rank by $_per of newest employee
*/
-- get sales per staff
WITH staff_sales AS(
	SELECT s.staff_id
		, s.first_name
		, s.last_name
		, s.position
		, s.start_date
		, SUM(t.line_item_amount) as total_sales_dollars
	FROM staff s
	JOIN transactions t
	ON s.staff_id = t.staff_id
	GROUP BY 1,2,3,4,5
	)
,
-- rank staff
ranked AS(
	SELECT *
	, RANK() OVER(ORDER BY total_sales_dollars DESC)
	FROM staff_sales
	)
, 
-- get start date of newest employeet
newest AS (
	SELECT MAX(start_date) 
			 FROM staff 
			 WHERE sales_outlet_id IN ('3','5','8')
)

SELECT * 
FROM ranked
WHERE start_date = (SELECT * FROM newest)
;


-- find staffers with highest $ per trans (best at upselling?)
SELECT s.staff_id
	, s.first_name
	, s.last_name
	, s.position
	, s.start_date
	, ROUND(SUM(t.line_item_amount) / COUNT(DISTINCT(CONCAT(t.transaction_id,t.transaction_date,t.sales_outlet_id))),2) as dollars_per_trans
FROM staff s
JOIN transactions t
ON s.staff_id = t.staff_id
GROUP BY 1,2,3,4,5
ORDER BY 6 DESC
LIMIT 10
;

--Find staffer with most transactions, including transaction store and home store for comparison
SELECT t.staff_id
	, s.first_name
	, s.last_name
	, s.start_date
	, s.position
	, t.sales_outlet_id as transaction_store
	, s.sales_outlet_id as home_store
	, COUNT(DISTINCT CONCAT(t.transaction_id, t.transaction_date, t.sales_outlet_id)) as total_transactions
FROM transactions t
JOIN staff s
ON t.staff_id = s.staff_id
GROUP BY 1,2,3,4,5,6,7
ORDER BY 1
-- LIMIT 10
;

