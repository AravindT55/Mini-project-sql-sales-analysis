
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100),
    phone VARCHAR(20)
);

INSERT INTO customers (customer_id, name, city, phone) VALUES
(1, 'Aravind', 'chennai', '9876543210'),
(2, 'priya', 'Delhi', NULL),
(3, 'Rahul', 'Mumbai', '9123456789'),
(4, 'priya', 'delhi', NULL),   -- Duplicate row
(5, 'John', 'CHENNAI', '9876543210');


CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    amount INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO orders (order_id, customer_id, amount, order_date) VALUES
(101, 1, 5000, '2024-01-10'),
(102, 2, NULL,  '2024-01-12'),
(103, 3, 7000, '2024-02-01'),
(104, 4, 5000, '2024-01-12'),  -- Duplicate linked customer
(105, 5, 3000, '2024-02-15');

select *from orders;

-- STEP 1 — Data Cleaning (customers table)
--  1.1 Standardize city names

SELECT
   customer_id,
   name,
   UPPER(TRIM(city)) AS city_clean
FROM customers;


-- 1.2 Fix name format (Proper Case)
SELECT
    customer_id,
    CONCAT(
       UPPER(SUBSTRING(name,1,1)),
       LOWER(SUBSTRING(name,2))
    ) AS formatted_name
FROM customers;


-- 1.3 Replace NULL phone numbers
SELECT 
   customer_id,
   COALESCE(phone, 'Unknown') AS phone_clean
FROM customers;


-- 1.4 Find duplicate customers
SELECT name, city, COUNT(*)
FROM customers
GROUP BY name, city
HAVING COUNT(*) > 1;


-- 1.5 Remove duplicates using ROW_NUMBER()
WITH cte AS (
   SELECT *,
      ROW_NUMBER() OVER (
         PARTITION BY name, city, phone
         ORDER BY customer_id
      ) AS rn
   FROM customers
)
DELETE FROM cte WHERE rn > 1;


-- STEP 2 — Data Cleaning (orders table)
-- 2.1 Replace NULL amount with 0
SELECT 
   order_id,
   customer_id,
   COALESCE(amount, 0) AS amount_clean
FROM orders;

-- 2.2 Standardize date format

-- (MySQL auto-stores in YYYY-MM-DD, so no need to convert.)


-- 2.3 Identify invalid foreign key rows
-- Check orders with customers that don’t exist:

SELECT *
FROM orders o
LEFT JOIN customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- STEP 3 — Analysis Queries (What analysts do)
-- 3.1 Total spending per customer
SELECT 
    c.customer_id,
    c.name,
    SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;

-- 3.2 Top 2 highest spending customers
SELECT 
    c.name,
    SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 2;

-- 3.3 Monthly revenue
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(amount) AS total_revenue
FROM orders
GROUP BY month
ORDER BY month;

-- 3.4 Number of orders per city
SELECT 
    UPPER(c.city) AS city,
    COUNT(o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY UPPER(c.city);

-- 3.5 Average spending per customer
SELECT 
    c.name,
    AVG(o.amount) AS avg_spending
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name;

