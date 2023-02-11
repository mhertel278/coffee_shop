--find number of staff by position at each store
SELECT sales_outlet_id
	, "position"
	, COUNT(*)
FROM staff
WHERE sales_outlet_id IN ('3','5','8')
GROUP BY 1,2
ORDER BY 1 ASC, 2 DESC

;

--Find staffers with most transactions
SELECT t.staff_id
	, s.first_name
	, s.last_name
	, s.start_date
	, t.sales_outlet_id
	, COUNT(DISTINCT CONCAT(t.transaction_id, t.transaction_date, t.sales_outlet_id)) as total_transactions
FROM transactions t
JOIN staff s
ON t.staff_id = s.staff_id
GROUP BY 1,2,3,4,5
ORDER BY 6 DESC
LIMIT 5
;

--FIND staffers with most $ sold

SELECT t.staff_id
	, s.first_name
	, s.last_name
	, s.start_date
	, s.position
	, t.sales_outlet_id
	, SUM(t.line_item_amount) as total_sales_dollars
FROM transactions t
JOIN staff s
ON t.staff_id = s.staff_id
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC
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