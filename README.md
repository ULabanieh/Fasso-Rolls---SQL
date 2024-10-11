# 🌯 Project Overview
---
Fassos is an online food ordering company that specializes in rolls, meaning that a variety of rolls such chicken rolls, egg rolls and veggie rolls get delivered to your doorstep. In this project, we dive into metrics and insights about this company that involve Data Exploration, Data Cleaning and Data Analysis processes. The dataset includes customer orders, IDs, driver data, product types (different types of rolls) and sales data. The project is divided into 3 sections: 

- **Dataset Creation:** setup of the dataset and input of the data using the "CREATE TABLE" and "INSERT INTO" commands. The different tables included in the dataset are the following:

- **Roll and Order Metrics:** insights about the products and sales, such as what roll types are preferred and orders by hour of the day 

- **Driver and Customer Experience:** insights about delivery efficiency and driver performance

The dataset is comprised of 6 tables:
- **driver_order:** shows the order, which driver was assigned to it, pickup time, distance travelled and duration of the journey
- **driver:** list of driver IDs and their registration date
- **rolls:** the types of rolls available
- **ingredients:** the types of ingredients that can be included in the rolls
- **roll_recipes:** the list of ingredient IDs each roll is made of
- **customer_orders:** list of orders from customers with info such as which roll was ordered, if they want to exlcude an ingredient or add an extra ingredient and the order date.

# Dataset Creation
---
The dataset was created manually within SQL as it contains fictional data for the purpose of the project only. I create all the 6 tables and insert the relevant data into them using the `CREATE TABLE` and `INSERT INTO`commands. Also specified data types. Let's have a look at the query to create the main table we will be querying, customer_orders:

```SQL
drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);

INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');
```

Output dataset: 

![1446-02-03 09_24_39-Dataset Creation sql - DESKTOP-UI79E1N_MSSQLSERVER01 FassosRolls (DESKTOP-UI79E1](https://github.com/user-attachments/assets/303706bd-471b-4524-ada9-730497a2492c)


# Roll and Order Metrics
---
Here we will start looking at interesting metrics about rolls and orders. We will go from simple queries to more advanced ones. I will showcase here the most important queries. To view all the queries in full detail, download the project files and explore them at will. 

#### How many rolls were ordered?
---

```SQL
SELECT COUNT(roll_id) AS number_rolls
FROM customer_orders;
```

Output:

![1446-02-03 09_29_11-Query 1 - Roll Metrics sql - DESKTOP-UI79E1N_MSSQLSERVER01 FassosRolls (DESKTOP-](https://github.com/user-attachments/assets/3a940556-d773-4541-8a76-3f9850420931)



#### How many unique customer orders were made?
---

```SQL
SELECT COUNT (DISTINCT customer_id) AS count_customer_orders
FROM customer_orders;
```

Output: 

![1446-02-03 09_31_07-Query 1 - Roll Metrics sql - DESKTOP-UI79E1N_MSSQLSERVER01 FassosRolls (DESKTOP-](https://github.com/user-attachments/assets/010466ef-46b6-43b2-9d25-08cd4a4c8e9b)


#### How many successful orders were delivered by each driver?
---

```SQL
SELECT driver_id, COUNT(DISTINCT order_id) AS count_successful_orders
FROM driver_order
WHERE cancellation not in ('Cancellation', 'Customer Cancellation')
GROUP BY driver_id;
```

Output: 

![1446-02-03 09_34_46-Query 1 - Roll and Order Metrics sql - DESKTOP-UI79E1N_MSSQLSERVER01 FassosRolls](https://github.com/user-attachments/assets/e0cdd017-7d73-4150-a46e-945605b740df)




#### How many of each type of roll was delivered?
---
```SQL
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
```

Output:

![1446-02-03 09_36_54-Query 1 - Roll and Order Metrics sql - DESKTOP-UI79E1N_MSSQLSERVER01 FassosRolls](https://github.com/user-attachments/assets/500a357b-5e6e-4b55-a711-4d3d789ec82f)



#### For each customer, how many delivered rolls had at least 1 change and how many had no changes? (with temp table and CTE)
---

```SQL
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
temp_driver_order (order_id, driver_id, pickup_time, distance, duration, new_cancellation) AS(
SELECT order_id, driver_id, pickup_time, distance, duration, 
	CASE WHEN cancellation in ('Cancellation', 'Customer Cancellation')
		THEN '0'
		ELSE 1
	END AS new_cancellation
FROM driver_order)

-- For each customer, how many delivered rolls had at least 1 change and how many had no changes?
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
ORDER BY customer_id
```

Output: 

![1446-02-03 09_45_43-Query 1 - Roll and Order Metrics sql - DESKTOP-UI79E1N_MSSQLSERVER01 FassosRolls](https://github.com/user-attachments/assets/aefea80e-ac44-4dce-aa61-16edc76ce61a)



#### What was the number of orders for each day of the week?
---
```SQL
SELECT dow, COUNT(DISTINCT order_id) count_orders
FROM(SELECT *, DATENAME(dw, order_date) dow
FROM customer_orders)a
GROUP BY dow;
```


Output:

![1446-02-03 15_22_57-Query 1 - Roll and Order Metrics sql - DESKTOP-UI79E1N_MSSQLSERVER01 FassosRolls](https://github.com/user-attachments/assets/298cab29-1914-4d82-91f7-109895ba27d3)


#### What was the total number of rolls ordered for each hour of the day?
---
```SQL
SELECT hours_bracket, COUNT(hours_bracket) count_rolls
FROM(SELECT *,CONCAT(CAST(DATEPART(hour, order_date)AS varchar),'-', CAST(DATEPART(hour, order_date) +1 AS varchar)) hours_bracket
FROM customer_orders)a
GROUP BY hours_bracket;
```

Output: 

![1446-02-03 15_24_22-Query 1 - Roll and Order Metrics sql - DESKTOP-UI79E1N_MSSQLSERVER01 FassosRolls](https://github.com/user-attachments/assets/88279f75-9e08-4dac-b6f9-32bf8c2c13ac)


# Driver and Customer Experience
---
Insights on driver performance and delivery efficiency as factors that impact the customer experience. I will showcase here the most important queries. To view all the queries in full detail, download the project files and explore them at will. 

#### Data Cleaning - Update incorrect time records in the table. Change year to 2021
---
```SQL
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
```

Output:

![1446-02-03 15_29_13-Query 2 - Driver and Customer Experience sql - DESKTOP-UI79E1N_MSSQLSERVER01 Fas](https://github.com/user-attachments/assets/8def3197-0f0a-4eb9-b6b9-02c12da226ca)


#### What was the average time in minutes it took for each driver to arrive at the Fasso's HQ to pickup the order?
---
```SQL
SELECT driver_id, SUM(diff)/COUNT(order_id) avg_time
FROM(SELECT *
FROM(SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY diff) rnk
FROM(SELECT a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date, b.driver_id, b.pickup_time, b.distance, b.duration, b.cancellation, DATEDIFF(minute, a.order_date, b.pickup_time) diff
FROM customer_orders a
INNER JOIN driver_order b ON a.order_id = b.order_id
WHERE b.pickup_time IS NOT NULL) a) b
WHERE rnk = 1)c
GROUP BY driver_id;
```

Output: 

![1446-02-03 15_30_27-Query 2 - Driver and Customer Experience sql - DESKTOP-UI79E1N_MSSQLSERVER01 Fas](https://github.com/user-attachments/assets/f44af73d-18ff-4e9a-8403-645eef5c1051)


#### What was the average distance travelled for each customer?
---

```SQL
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
```

Output: 

![1446-02-03 15_31_17-Query 2 - Driver and Customer Experience sql - DESKTOP-UI79E1N_MSSQLSERVER01 Fas](https://github.com/user-attachments/assets/f88303a0-59ba-4408-977a-a6056fa5e6d2)


#### What was the average speed for each driver for each delivery?
---

```SQL
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
```

Output:

![1446-02-03 15_32_45-Query 2 - Driver and Customer Experience sql - DESKTOP-UI79E1N_MSSQLSERVER01 Fas](https://github.com/user-attachments/assets/9e90a2b6-f932-4430-b35c-40376ba8725a)


#### What is the successful delivery percentage for each driver?
---

```SQL
-- sdp = total orders successfully delivered/total orders taken

SELECT driver_id, s*1.0/t sdp
FROM
(SELECT driver_id, SUM(cancel_pctg) s, COUNT(driver_id) t
FROM(SELECT driver_id,
CASE WHEN LOWER(cancellation) LIKE '%cancel%'
	THEN 0
	ELSE 1
END AS cancel_pctg
FROM driver_order)a
GROUP BY driver_id)b;
```

Output:

![1446-02-03 15_36_56-Query 2 - Driver and Customer Experience sql - DESKTOP-UI79E1N_MSSQLSERVER01 Fas](https://github.com/user-attachments/assets/18179d96-2119-49c2-9475-3236fd77fd7a)

