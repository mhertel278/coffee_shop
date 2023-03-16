-- find how many transactions are from loyalty vs non-loyalty members
SELECT COUNT(DISTINCT CONCAT(transaction_date,transaction_time,sales_outlet_id)) as trans_count
	, 'non-loyalty' as customer_type
FROM transactions
WHERE customer_id NOT IN (SELECT customer_id from customer)
UNION 
SELECT COUNT(DISTINCT CONCAT(transaction_date,transaction_time,sales_outlet_id)) as trans_count
	, 'loyalty' as customer_type
FROM transactions
WHERE customer_id IN (SELECT customer_id from customer)

-- how many new loyalty customers this month
SELECT COUNT(*) 
FROM CUSTOMER
WHERE customer_since > '2019-04-01'

-- money spent by gender
SELECT c.gender
	, SUM(t.line_item_amount) as dollars_spent	
FROM customer c
INNER JOIN transactions t
ON c.customer_id = t.customer_id
GROUP BY 1

--money spent per transaction by gender
SELECT c.gender
	, ROUND(SUM(t.line_item_amount)/ COUNT(DISTINCT CONCAT(t.transaction_id,t.transaction_date,t.sales_outlet_id)),2) as dollars_per_trans
FROM customer c
INNER JOIN transactions t
ON c.customer_id = t.customer_id
GROUP BY 1

--money spent per transaction by loyalty vs non-loyalty

--money per transaction by age group

--money spent by age group

--frequency of visit by loyalty 

