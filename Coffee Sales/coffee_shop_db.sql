CREATE TABLE transactions (
	transaction_id INT,
	transaction_date DATE,
	transaction_time TIME,
	sales_outlet_id INT,
	staff_id INT,
	customer_id INT,
	instore_yn CHAR(1),
	"order" INT,
	line_item_id INT,
	product_id INT,
	quantity INT,
	line_item_amount NUMERIC,
	unit_price NUMERIC,
	promo_item_yn CHAR(1)
)
;

CREATE TABLE customer (
	customer_id INT,
	home_store INT,
	customer_first_name VARCHAR(40),
	customer_email VARCHAR(40),
	customer_since DATE,
	loyalty_card_number CHAR(12),
	birthdate DATE,
	gender CHAR(1),
	birth_year INT
)
;

CREATE TABLE dates (
	transaction_date DATE,
	date_id INT,
	week_id INT,
	week_desc CHAR(7),
	month_id SMALLINT,
	month_name CHAR(5),
	quarter_id SMALLINT,
	quarter_name CHAR(2),
	year_id INT)
;

CREATE TABLE generations (
	birth_year	INT,
	generation	VARCHAR(20)
)
;

CREATE TABLE sales_outlet (
	sales_outlet_id INT PRIMARY KEY,
	sales_outlet_type VARCHAR (30),
	store_square_feet INT,
	store_address VARCHAR(30),
	store_city VARCHAR(30),
	store_state_province CHAR(2),
	store_telephone CHAR(12),
	store_postal_code CHAR(5),
	store_longitude FLOAT,
	store_latitude FLOAT,
	manager INT,
	neighborhood VARCHAR(30)
)
;

CREATE TABLE pastry_inventory (
	sales_outlet_id INT,
	transaction_date DATE,
	product_id INT,
	start_of_day INT,
	quantity_sold INT,
	waste INT,
	waste_perc CHAR(3)
)
;

CREATE TABLE sales_targets (
	sales_outlet_id INT,
	year_month CHAR(6),
	beans_goal INT,
	beverage_goal INT,
	food_goal INT,
	merchandise_goal INT,
	total_goal INT
)
;

CREATE TABLE product (
	product_id INT PRIMARY KEY,
	product_group VARCHAR(30),
	product_category VARCHAR(30),
	product_type VARCHAR(30),
	product VARCHAR(50),
	product_description VARCHAR(100),
	unit_of_measure VARCHAR(10),
	current_wholesale_price FLOAT,
	current_retail_price FLOAT,
	tax_exempt_yn CHAR(1),
	promo_yn CHAR(1),
	new_product_yn CHAR(1))
;

CREATE TABLE staff (
	staff_id INT PRIMARY KEY,
	first_name VARCHAR(20),
	last_name VARCHAR(20),
	"position" VARCHAR(20),
	start_date DATE,
	"location" VARCHAR(4)
)
;

--unpivot targets table to allow joining to sales table later 
-- code adapted from StackOverflow
-- https://stackoverflow.com/questions/64268037/unpivot-table-in-postgresql on 1/26/2023
SELECT st.sales_outlet_id
	, u.product_group
	, u.goal
INTO sales_targets_long
FROM sales_targets st
	CROSS JOIN LATERAL (
		VALUES ('Whole Bean/Teas',beans_goal)
			,('Beverages',beverage_goal)
			,('Food',food_goal)
			,('Merchandise',merchandise_goal)
	) as u(product_group,goal)
ORDER BY 1;

--change staff table column names

ALTER TABLE staff
RENAME COLUMN "location" TO sales_outlet_id;

/* update staff table sales_outlet_id to the store where each employee sells the most from
as this store is likely their new home store
*/
--find each staffer's store of most transactions to become the new home store
WITH trans_by_store AS (
	SELECT t.staff_id

	, CAST(t.sales_outlet_id AS VARCHAR(4)) as transaction_store--converting to string as that is the d type in staff table
	, s.sales_outlet_id as home_store
	, COUNT(DISTINCT CONCAT(t.transaction_id, t.transaction_date, t.sales_outlet_id)) as total_transactions
FROM transactions t
JOIN staff s
ON t.staff_id = s.staff_id
GROUP BY 1,2,3
ORDER BY 1 ASC)
, 
-- find store each staffer sells the most from
ranks as(
	SELECT *
		, RANK() OVER (PARTITION BY staff_id ORDER BY total_transactions DESC)
	FROM trans_by_store)
,
--take top ranked store for each staffer as their new store 
--only include staffers where top store is different than home store to update table later
updaters AS (
	SELECT staff_id
	, transaction_store
	, home_store
FROM ranks
WHERE RANK = 1 AND transaction_store != home_store)
--update table
UPDATE staff s
	SET sales_outlet_id =
		(SELECT transaction_store
			FROM updaters u
			WHERE u.staff_id = s.staff_id)
WHERE staff_id IN (SELECT staff_id FROM updaters)
;

/*
Update product table, remove 'Sm','Rg','Lg' from drink product names to allow group by of coffee/tea type
convert units in unit-of-measure column
*/

-- ensure update condition works 
SELECT product
	, REPLACE(REPLACE(REPLACE(REPLACE(product, ' Sm',''),' Rg',''), ' Lg',''), ' - Organic','')
FROM product
WHERE product LIKE '% Sm' 
	OR product LIKE '% Rg'
	OR product LIKE '% Lg'
	OR product LIKE '% - Organic'
;

-- 