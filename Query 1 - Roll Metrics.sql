-- Roll Metrics

-- How many rolls were ordered?

SELECT COUNT(roll_id) AS number_rolls
FROM customer_orders;

--  How many unique customer orders were made?

SELECT COUNT (DISTINCT customer_id) AS count_customer_orders
FROM customer_orders;

-- How many successful orders were delivered by each driver?
SELECT driver_id, COUNT(DISTINCT order_id) AS count_successful_orders
FROM driver_order
WHERE cancellation not in ('Cancellation', 'Customer Cancellation')
GROUP BY driver_id;


-- How many of each type of roll was delivered?
SELECT roll_id, COUNT(roll_id) AS number_delievered
FROM customer_orders
WHERE order_id in(
	SELECT order_id
	FROM (SELECT *,
		CASE WHEN cancellation in ('Cancellation', 'Customer Cancellation') 
			THEN 'c'
			ELSE 'nc'
		END AS order_cancel_details
	FROM driver_order) a
	WHERE order_cancel_details = 'nc')
GROUP BY roll_id;


-- How many Veg and Non Veg Rolls were ordered by each customer?
SELECT a.*, b.roll_name 
FROM(SELECT customer_id, roll_id, COUNT(roll_id) cnt
	FROM customer_orders
	GROUP BY customer_id, roll_id) a
INNER JOIN rolls b ON a.roll_id = b.roll_id;


-- What was the maximum number of rolls delivered in a single order?

SELECT *
FROM customer_orders

SELECT *
FROM driver_order

SELECT * 
FROM(
	SELECT *, RANK() OVER(ORDER BY cnt DESC) rnk
	FROM(
		SELECT order_id, COUNT(roll_id) cnt
		FROM(
			SELECT *
			FROM customer_orders 
			WHERE order_id in(
				SELECT order_id
				FROM (
					SELECT *, 
					CASE WHEN cancellation in ('Cancellation', 'Customer Cancellation') 
						THEN 'c'
						ELSE 'nc'
					END AS order_cancel_details
					FROM driver_order) a
				WHERE order_cancel_details = 'nc')) b
		GROUP BY order_id)c)d
WHERE rnk = 1;


-- For each customer, how many delivered rolls had at least 1 change and how many had no changes?

-- Data cleaning customer_orders
WITH temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) AS (
	SELECT order_id, customer_id, roll_id, 
		CASE WHEN not_include_items IS NULL OR not_include_items = ' ' 
			THEN '0'
			ELSE not_include_items
		END AS new_not_include_items,
		CASE WHEN extra_items_included IS NULL OR extra_items_included = ' ' OR extra_items_included = 'NaN'
			THEN '0'
			ELSE extra_items_included
		END AS new_extra_items_included,
		order_date
	FROM customer_orders)
	,

-- Data cleaning driver_orders
temp_driver_order (order_id,driver_id,pickup_time,distance,duration, new_cancellation) AS(
SELECT order_id, driver_id, pickup_time, distance, duration, 
	CASE WHEN cancellation in ('Cancellation', 'Customer Cancellation')
		THEN '0'
		ELSE 1
	END AS new_cancellation
FROM driver_order)


SELECT customer_id, chg_no_chg, COUNT(order_id) count_orders
FROM(
SELECT *, 
CASE WHEN not_include_items = '0' AND extra_items_included = '0'
	THEN 'no change'
	ELSE 'change'
END chg_no_chg
FROM temp_customer_orders
WHERE order_id IN(
	SELECT order_id
	FROM temp_driver_order
	WHERE new_cancellation !=0))a
GROUP BY customer_id, chg_no_chg;

-- How many rolls were delivered that had both exclusions and extras?
WITH temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) AS (
	SELECT order_id, customer_id, roll_id, 
		CASE WHEN not_include_items IS NULL OR not_include_items = ' ' 
			THEN '0'
			ELSE not_include_items
		END AS new_not_include_items,
		CASE WHEN extra_items_included IS NULL OR extra_items_included = ' ' OR extra_items_included = 'NaN'
			THEN '0'
			ELSE extra_items_included
		END AS new_extra_items_included,
		order_date
	FROM customer_orders)
	,

-- Data cleaning driver_orders
temp_driver_order (order_id,driver_id,pickup_time,distance,duration, new_cancellation) AS(
SELECT order_id, driver_id, pickup_time, distance, duration, 
	CASE WHEN cancellation in ('Cancellation', 'Customer Cancellation')
		THEN '0'
		ELSE 1
	END AS new_cancellation
FROM driver_order)



SELECT chg_no_chg, COUNT(chg_no_chg) 
FROM(
SELECT *, 
CASE WHEN not_include_items != '0' AND extra_items_included != '0'
	THEN 'both inc exc'
	ELSE 'none or only 1 change'
END chg_no_chg
FROM temp_customer_orders
WHERE order_id IN(
	SELECT order_id
	FROM temp_driver_order
	WHERE new_cancellation !=0))a
GROUP BY chg_no_chg;


-- What was the total number of rolls ordered for each hour of the day?

SELECT hours_bracket, COUNT(hours_bracket) count_rolls
FROM(SELECT *,CONCAT(CAST(DATEPART(hour, order_date)AS varchar),'-', CAST(DATEPART(hour, order_date) +1 AS varchar)) hours_bracket
FROM customer_orders)a
GROUP BY hours_bracket;

-- What was the number of orders for each day of the week?

SELECT dow, COUNT(DISTINCT order_id) count_orders
FROM(SELECT *, DATENAME(dw, order_date) dow
FROM customer_orders)a
GROUP BY dow;
