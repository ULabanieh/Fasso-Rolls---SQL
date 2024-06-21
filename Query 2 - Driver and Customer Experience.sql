-- Driver and customer experience 

-- Update incorrect time records in the table. Change year to 2021
SELECT *
FROM driver_order

UPDATE driver_order
SET pickup_time = '2021-01-08 21:30:45.000'
WHERE order_id = 7

UPDATE driver_order
SET pickup_time = '2021-01-10 00:15:02.000'
WHERE order_id = 8

UPDATE driver_order
SET pickup_time = '2021-01-11 18:50:20.000'
WHERE order_id = 10


-- What was the average time in minutes it took for each driver to arrive at the Fasso's HQ to pickup the order?

SELECT driver_id, SUM(diff)/COUNT(order_id) avg_time
FROM(SELECT *
FROM(SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY diff) rnk
FROM(SELECT a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date, b.driver_id, b.pickup_time, b.distance, b.duration, b.cancellation, DATEDIFF(minute, a.order_date, b.pickup_time) diff
FROM customer_orders a
INNER JOIN driver_order b ON a.order_id = b.order_id
WHERE b.pickup_time IS NOT NULL) a) b
WHERE rnk = 1)c
GROUP BY driver_id;

-- Is there any relationship between the number of rolls and how long the order takes to prepare?

SELECT order_id, COUNT(roll_id) cnt, SUM(diff)/COUNT(roll_id) time
FROM(SELECT a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date, b.driver_id, b.pickup_time, b.distance, b.duration, b.cancellation, DATEDIFF(minute, a.order_date, b.pickup_time) diff
FROM customer_orders a
INNER JOIN driver_order b ON a.order_id = b.order_id
WHERE b.pickup_time IS NOT NULL)a
GROUP BY order_id;

-- What was the average distance travelled for each customer?

SELECT customer_id, SUM(distance)/COUNT(order_id) avg_distance
FROM(SELECT *
FROM(SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY diff) rnk
FROM(SELECT a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date, b.driver_id, b.pickup_time, 
CAST(TRIM(REPLACE(LOWER(b.distance),'km', '')) AS decimal(4,2)) distance, 
b.duration, 
b.cancellation, DATEDIFF(minute, a.order_date, b.pickup_time) diff
FROM customer_orders a
INNER JOIN driver_order b ON a.order_id = b.order_id
WHERE b.pickup_time IS NOT NULL) a) b
WHERE rnk = 1)c
GROUP BY customer_id;

-- Due to distance and duration datapoints in the driver_orders table containing dirty data, include strings such as 'km' or 'mins', some data cleaning is needed before proceeding with this query

-- What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) - MIN (duration) diff
FROM(
SELECT CAST(CASE WHEN duration LIKE '%min%'
	THEN LEFT (duration, CHARINDEX('m', duration)-1)
	ELSE duration
END AS INTEGER) AS duration
FROM driver_order
WHERE duration IS NOT NULL) a

-- What was the average speed for each driver for each delivery and do you notice any trend for these values?
-- speed = distance/time

SELECT order_id, COUNT(roll_id)
FROM customer_orders
GROUP BY order_id;

SELECT a.order_id, a.driver_id, a.distance/a.duration speed, b.cnt
FROM(SELECT order_id, driver_id, CAST(CASE WHEN duration LIKE '%min%'
	THEN LEFT (duration, CHARINDEX('m', duration)-1)
	ELSE duration
END AS INTEGER) AS duration,
CAST(TRIM(REPLACE(LOWER(distance),'km', '')) AS decimal(4,2)) distance
FROM driver_order
WHERE distance IS NOT NULL)a
INNER JOIN (SELECT order_id, COUNT(roll_id) cnt
FROM customer_orders
GROUP BY order_id) b ON a.order_id = b.order_id;


-- What is the successful delivery percentage for each driver?
-- sdp = total orders successfully delivered/total orders taken

SELECT driver_id, s*1.0/t cancelled_pctg
FROM
(SELECT driver_id, SUM(cancel_pctg) s, COUNT(driver_id) t
FROM(SELECT driver_id,
CASE WHEN LOWER(cancellation) LIKE '%cancel%'
	THEN 0
	ELSE 1
END AS cancel_pctg
FROM driver_order)a
GROUP BY driver_id)b;
