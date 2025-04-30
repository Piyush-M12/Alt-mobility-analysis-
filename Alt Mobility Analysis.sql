use [altmobility ]

select * from orders
select * from payments

--- To keep in mind the distinct caategories of order status 
SELECT DISTINCT order_status FROM orders;

-- Total number of orders grouped by status
SELECT order_status, 
COUNT(*) AS net_total_orders
FROM orders
GROUP BY order_status;

--- Ratio of Fulfilled (Shipped + Completed) to Pending Orders Per Month
SELECT 
  FORMAT(order_date, 'yyyy-MM') AS order_month,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN order_status IN ('Shipped', 'delivered') THEN 1 ELSE 0 END) AS fulfilled_orders,
  SUM(CASE WHEN order_status = 'Pending' THEN 1 ELSE 0 END) AS pending_orders,
  CAST(SUM(CASE WHEN order_status IN ('Shipped', 'delivered') THEN 1 ELSE 0 END) * 1.0 / 
       NULLIF(SUM(CASE WHEN order_status = 'Pending' THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS fulfillment_to_pending_ratio
FROM orders
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY order_month;


---Monthly sales trend for delivered orders 
SELECT 
  FORMAT(order_date, 'yyyy-MM') AS order_month,
  SUM(order_amount) AS total_sales
FROM orders
WHERE order_status = 'delivered '
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY order_month;

---Monthly sales trend for shipped orders 
SELECT 
  FORMAT(order_date, 'yyyy-MM') AS order_month,
  SUM(order_amount) AS total_sales
FROM orders
WHERE order_status = 'shipped'
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY order_month;

---Monthly sales trend for pending orders 
SELECT 
  FORMAT(order_date, 'yyyy-MM') AS order_month,
  SUM(order_amount) AS total_sales
FROM orders
WHERE order_status = 'pending'
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY order_month;

---percentage of orders each month are still pending vs completed vs shipped ,  useful for identifying processing delays or conversion efficiency  for specific months 
SELECT 
  FORMAT(order_date, 'yyyy-MM') AS order_month,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders,
  SUM(CASE WHEN order_status = 'Shipped' THEN 1 ELSE 0 END) AS shipped_orders,
  SUM(CASE WHEN order_status = 'Pending' THEN 1 ELSE 0 END) AS pending_orders,
  CAST(SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_delivered,
  CAST(SUM(CASE WHEN order_status = 'Pending' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_pending
FROM orders
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY order_month;



--- 2nd task 

-- for repeat customers 
SELECT customer_id, COUNT(*) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- monthly count of unique customers 
SELECT 
  FORMAT(order_date, 'yyyy-MM') AS order_month,
  COUNT(DISTINCT customer_id) AS unique_customers
FROM orders
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY order_month;

--- basic revenue segment of customers using their order id 
SELECT 
  order_id,
  SUM(payment_amount) AS total_paid,
  CASE 
    WHEN SUM(payment_amount) < 1000 THEN 'Low Spender'
    WHEN SUM(payment_amount) BETWEEN 1000 AND 1200 THEN 'Medium Spender'
    ELSE 'High Spender'
  END AS segment
FROM payments
GROUP BY order_id
ORDER BY total_paid DESC;


-- cutstomer retention period 
SELECT 
  customer_id,
  MIN(order_date) AS first_order,
  MAX(order_date) AS last_order,
  DATEDIFF(DAY, MIN(order_date), MAX(order_date)) AS active_days,
  COUNT(*) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1
order by count(*) desc


--- payment status analysis 

select * from payments

-- total payements grouped by payment status with net total 
SELECT payment_status, COUNT(*) AS total_payments,
sum(payment_amount) as NET_TOTAL
FROM payments
GROUP BY payment_status;


--- payment status stas for each month 
SELECT 
  FORMAT(payment_date, 'yyyy-MM') AS payment_month,
  payment_status,
  COUNT(*) AS payment_count,
  sum(payment_amount) as NET_SUM
FROM payments
GROUP BY FORMAT(payment_date, 'yyyy-MM'), payment_status
ORDER BY payment_month;

--- high risk accounts for alt mobility where customer failed payemnt percentage is very high 
SELECT 
  o.customer_id,
  COUNT(*) AS total_payments,
  SUM(CASE WHEN p.payment_status = 'Failed' THEN 1 ELSE 0 END) AS failed_payments,
  CAST(SUM(CASE WHEN p.payment_status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS fail_rate_percent
FROM payments p
JOIN orders o ON p.order_id = o.order_id
GROUP BY o.customer_id
HAVING COUNT(*) > 2
ORDER BY fail_rate_percent DESC;


--- Completed to (Pending + Failed) Payment Status Ratio
SELECT 
  SUM(CASE WHEN payment_status = 'Completed' THEN 1 ELSE 0 END) AS completed_count,
  SUM(CASE WHEN payment_status IN ('Pending', 'Failed') THEN 1 ELSE 0 END) AS pending_failed_count,
  CAST(
    SUM(CASE WHEN payment_status = 'Completed' THEN 1 ELSE 0 END) * 1.0 /
    NULLIF(SUM(CASE WHEN payment_status IN ('Pending', 'Failed') THEN 1 ELSE 0 END), 0)
    AS DECIMAL(10,2)
  ) AS completed_to_pending_failed_ratio
FROM payments



--- order details report 
-- creating a table named orders_payments which is joined table of orders and payemnts 
CREATE VIEW orders_payments AS
SELECT 
  o.order_id,
  o.customer_id,
  o.order_date,
  o.order_amount,
  o.order_status,
  o.shipping_address,
  p.payment_id,
  p.payment_date,
  p.payment_amount,
  p.payment_status
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id;

select * from orders_payments
--- Total Orders, Total Revenue, and Payment Success Rate
SELECT
  COUNT(DISTINCT order_id) AS total_orders,
  SUM(order_amount) AS total_order_value,
  SUM(CASE WHEN payment_status = 'completed' THEN payment_amount ELSE 0 END) AS successful_payments,
  ROUND(100.0 * SUM(CASE WHEN payment_status = 'completed' THEN 1 ELSE 0 END) / COUNT(payment_id), 2) AS payment_success_rate
FROM orders_payments;

-- cumilative revenue by month for each customer 
SELECT 
  customer_id,
  FORMAT(order_date, 'yyyy-MM') AS month,
  SUM(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS cumulative_revenue
FROM orders_payments

-- filtering out high value customers whose orders are more
WITH customer_totals AS (
  SELECT 
    customer_id, 
    SUM(order_amount) AS total_spent,
    COUNT(DISTINCT order_id) AS total_orders
  FROM orders_payments
  GROUP BY customer_id
)
SELECT 
  customer_id,
  total_spent,
  total_orders
FROM customer_totals
WHERE total_spent > 2000
ORDER BY total_spent DESC;

--- monthly sales and orders 
SELECT 
  FORMAT(order_date, 'yyyy-MM') AS month,
  COUNT(order_id) AS total_orders,
  SUM(order_amount) AS total_sales
FROM orders_payments
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY month;

-- avg order value by month
SELECT 
  FORMAT(order_date, 'yyyy-MM') AS month,
  AVG(order_amount) AS avg_order_value
FROM orders_payments
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY month;

-- revenue either pending or failed accounted for failer orders 
SELECT 
  COUNT(order_id) AS failed_orders,
  SUM(order_amount) AS potential_lost_revenue
FROM orders_payments
WHERE payment_status IS NULL OR payment_status != 'completed' 

select * from orders_payments

--- payment delay by cutomers
SELECT 
  customer_id,
  AVG(DATEDIFF(DAY, order_date, payment_date)) AS avg_payment_delay
FROM orders_payments
WHERE payment_date IS NOT NULL
GROUP BY customer_id
ORDER BY avg_payment_delay DESC;

-- most frequesnt shipping locations used 
SELECT TOP 10 shipping_address, COUNT(*) AS total_orders
FROM orders_payments
GROUP BY shipping_address
ORDER BY total_orders DESC;


-- found error in table when payemnt date is done bfore order date this helps us to clean data as the data is fautly here 
SELECT 
  order_id,
  customer_id,
  order_date,
  payment_id,
  payment_date,
  payment_amount,
  shipping_address,
  order_status,
  payment_status
FROM orders_payments
WHERE payment_date < order_date
ORDER BY payment_date;



--- code for visualisation tool for retention period 
WITH CustomerOrders AS (
    SELECT 
        customer_id,
        CAST(order_date AS DATE) AS order_date,
        FORMAT(order_date, 'yyyy-MM') AS order_month
    FROM orders
),

Cohorts AS (
    SELECT 
        customer_id,
        MIN(FORMAT(order_date, 'yyyy-MM')) AS cohort_month,
        MIN(CAST(order_date AS DATE)) AS cohort_date
    FROM CustomerOrders
    GROUP BY customer_id
),

OrdersWithCohort AS (
    SELECT 
        o.customer_id,
        c.cohort_month,
        FORMAT(o.order_date, 'yyyy-MM') AS order_month,
        DATEDIFF(MONTH, c.cohort_date, o.order_date) AS months_since
    FROM CustomerOrders o
    JOIN Cohorts c ON o.customer_id = c.customer_id
)

SELECT 
    cohort_month,
    months_since,
    COUNT(DISTINCT customer_id) AS retained_customers
FROM OrdersWithCohort
GROUP BY cohort_month, months_since
ORDER BY cohort_month, months_since;
