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