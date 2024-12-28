USE DWH_DB;

-- List all customers with their city and state:
SELECT customer_id, first_name, last_name, city, state
FROM [dbo].[DimCustomer];


-- Count how many customers are in each state:
SELECT state, COUNT(*) AS customer_count
FROM [dbo].[DimCustomer]
GROUP BY state
ORDER BY customer_count DESC;

--Find customers who have placed orders:
SELECT c.customer_id, c.first_name, c.last_name, o.order_id, o.order_date
FROM [dbo].[DimCustomer] c
INNER JOIN [dbo].[Dimorders] o ON c.customer_id = o.customer_id;


--Retrieve customers who haven't placed any orders:
SELECT c.customer_id, c.first_name, c.last_name
FROM [dbo].[DimCustomer] c
LEFT JOIN [dbo].[Dimorders] o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


--Get the top 5 customers by the number of orders placed:
SELECT TOP 5 c.customer_id, c.first_name, c.last_name, COUNT(o.order_id) AS total_orders
FROM [dbo].[DimCustomer] c
JOIN Dimorders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_orders DESC

-- Show customers along with the total amount spent (assuming product price can be calculated):
SELECT c.customer_id, c.first_name, c.last_name, SUM(p.list_price) AS total_spent
FROM [dbo].[DimCustomer] c
JOIN [dbo].[Dimorders] o ON c.customer_id = o.customer_id
JOIN [dbo].[DimProduct] p ON o.order_id = p.product_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;
/*
******************************************************************************************
*/
-- Find the most expensive product in each category using window functions:
SELECT category_id, product_name, list_price,
       RANK() OVER (PARTITION BY category_id ORDER BY list_price DESC) AS rank_in_category
FROM [dbo].[DimProduct];

--Rank stores based on the number of orders placed (using DENSE_RANK):
SELECT store_id, COUNT(order_id) AS total_orders,
       DENSE_RANK() OVER (ORDER BY COUNT(order_id) DESC) AS store_rank
FROM [dbo].[Dimorders]
GROUP BY store_id;

-- Find the average price of products for each brand:
SELECT b.brand_name, AVG(p.list_price) AS avg_price
FROM DimProduct p
JOIN DimBrand b ON p.brand_id = b.brand_id
GROUP BY b.brand_name;

-- List staff members along with their manager's name (self-join):
SELECT s1.staff_id, s1.first_name + ' ' + s1.last_name AS staff_name, 
       s2.first_name + ' ' + s2.last_name AS manager_name
FROM DimStaff s1
LEFT JOIN DimStaff s2 ON s1.manager_id = s2.staff_id;

-- Calculate the total stock per store and rank stores based on quantity:
SELECT store_id, SUM(quantity) AS total_stock,
       RANK() OVER (ORDER BY SUM(quantity) DESC) AS stock_rank
FROM Dimstocks
GROUP BY store_id;

--Show the cumulative number of orders over time using window functions:
SELECT order_id, order_date, 
       COUNT(order_id) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_orders
FROM Dimorders;

-- Find the percentage of total quantity for each product in stock using PERCENT_RANK:
SELECT product_id, quantity, 
       PERCENT_RANK() OVER (ORDER BY quantity DESC) AS quantity_percent_rank
FROM Dimstocks;
/* Analysis on staff table and their KPIs */
-- Sales Performance (Total Sales per Staff)
SELECT s.staff_id, s.first_name, s.last_name, COUNT(o.order_id) AS total_orders
FROM DimStaff s
JOIN Dimorders o ON s.staff_id = o.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY total_orders DESC;

-- Calculate The Total Sales Amount for each staff member including prices:
SELECT s.staff_id, s.first_name, s.last_name, SUM(p.list_price) AS total_sales
FROM DimStaff s
JOIN [Dimorders] o ON s.staff_id = o.staff_id
JOIN DimProduct p ON o.order_id = p.product_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY total_sales DESC;

-- Average Time to Complete an Order:
SELECT s.staff_id, s.first_name, s.last_name, 
       AVG(DATEDIFF(DAY, o.order_date, o.shipped_date)) AS avg_fulfillment_days
FROM DimStaff s
JOIN Dimorders o ON s.staff_id = o.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY avg_fulfillment_days ASC;

-- Staff Productivity Ranking:
SELECT s.staff_id, s.first_name, s.last_name, 
       COUNT(o.order_id) AS total_orders,
       RANK() OVER (ORDER BY COUNT(o.order_id) DESC) AS productivity_rank
FROM DimStaff s
JOIN Dimorders o ON s.staff_id = o.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name;


-- Order Handling Efficiency (Orders Per Month)
SELECT s.staff_id, s.first_name, s.last_name, 
       YEAR(o.order_date) AS year, MONTH(o.order_date) AS month, 
       COUNT(o.order_id) AS orders_per_month
FROM DimStaff s
JOIN [Dimorders] o ON s.staff_id = o.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name, YEAR(o.order_date), MONTH(o.order_date)
ORDER BY year DESC, month DESC;

-- Top Staff Members by Revenue
SELECT s.staff_id, s.first_name, s.last_name,
       SUM(p.list_price * p.list_price_percentage / 100) AS total_revenue
FROM DimStaff s
JOIN [Dimorders] o ON s.staff_id = o.staff_id
JOIN DimProduct p ON o.order_id = p.product_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY total_revenue DESC;

-- Average Time Between Orders (Staff Responsiveness)
WITH staff_orders AS (
   SELECT s.staff_id, s.first_name, s.last_name, 
          o.order_date, 
          LAG(o.order_date) OVER (PARTITION BY s.staff_id ORDER BY o.order_date) AS previous_order_date
   FROM DimStaff s
   JOIN [Dimorders] o ON s.staff_id = o.staff_id
)
SELECT staff_id, first_name, last_name, 
       AVG(DATEDIFF(DAY, previous_order_date, order_date)) AS avg_days_between_orders
FROM staff_orders
WHERE previous_order_date IS NOT NULL
GROUP BY staff_id, first_name, last_name;

