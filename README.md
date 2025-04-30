# SQL Queries for Alt Mobility Data Analysis

This document provides a detailed explanation of how various SQL concepts were used in the Alt Mobility data analysis project. The analysis involves extracting key insights from the orders and payments data.

I have named the customer_orders table as orders and copy of payemnts table as payment for user time efficiency while writing big queries.
## 1. Selecting Data from Tables
In many queries, I have used the SELECT statement to retrieve data from the `orders` and `payments` tables. For example:

SELECT * FROM orders;
```
This retrieves all columns from the `orders` table to explore the data structure.

## 2. Filtering Unique Values with DISTINCT
To get a list of unique order statuses, I used the DISTINCT keyword:

SELECT DISTINCT order_status FROM orders;
```
This helps identify all the different statuses an order can have, which is useful for categorizing the orders.

## 3. Grouping Data with GROUP BY
In many queries, I grouped the data to calculate aggregate values. For example:

SELECT order_status, COUNT(*) AS net_total_orders FROM orders GROUP BY order_status;

Here, I grouped the orders by `order_status` to calculate the total number of orders in each status category. Grouping helps in analyzing how orders are distributed across different statuses.

## 4. Using Aggregate Functions
Aggregate functions like COUNT() and SUM() were frequently used to calculate totals. For example:

SELECT FORMAT(order_date, 'yyyy-MM') AS order_month, SUM(order_amount) AS total_sales FROM orders WHERE order_status = 'delivered' GROUP BY FORMAT(order_date, 'yyyy-MM');
```
This query uses SUM() to calculate the total sales for delivered orders, grouped by month. Aggregate functions are used to summarize data, which helps in understanding trends.

## 5. Conditional Aggregation with CASE WHEN
I used CASE WHEN statements to categorize data based on certain conditions. For example:

SELECT 
  order_id,
  SUM(payment_amount) AS total_paid,
  CASE 
    WHEN SUM(payment_amount) < 1000 THEN 'Low Spender'
    WHEN SUM(payment_amount) BETWEEN 1000 AND 1200 THEN 'Medium Spender'
    ELSE 'High Spender'
  END AS segment
FROM payments
GROUP BY order_id;
```
This query categorizes customers into spending segments based on their total payment amount. The CASE WHEN construct allows conditional logic within the query, which is useful for classification.

## 6. Filtering Grouped Data with HAVING
I used the HAVING clause to filter groups based on conditions applied after aggregation. For example:

SELECT customer_id, COUNT(*) AS total_orders FROM orders GROUP BY customer_id HAVING COUNT(*) > 1;
```
Here, HAVING filters customers who have made more than one order. HAVING is essential when filtering data that has been aggregated by GROUP BY.

## 7. Joining Tables
To combine data from multiple tables, I used JOIN. For example:

SELECT 
  o.order_id,
  o.customer_id,
  o.order_date,
  o.order_amount,
  p.payment_id,
  p.payment_date,
  p.payment_amount
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id;
```
This query uses a LEFT JOIN to combine order and payment data, ensuring that even orders without associated payments are included.

## 8. Handling NULL Values with NULLIF
I used the NULLIF function to avoid errors when dividing by zero. For example:

CAST(SUM(CASE WHEN order_status IN ('Shipped', 'delivered') THEN 1 ELSE 0 END) * 1.0 / NULLIF(SUM(CASE WHEN order_status = 'Pending' THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS fulfillment_to_pending_ratio
```
In this case, NULLIF ensures that the denominator is not zero, preventing division by zero errors.

## 9. Using WITH Clauses for Subqueries (CTEs)
I utilized WITH clauses (Common Table Expressions, or CTEs) to break down complex queries into manageable pieces. For example:

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
```
The CTE `customer_totals` aggregates customer spending and orders, which is then used to filter out high-value customers.

## 10. Formatting Dates
I often used the FORMAT() function to group or display data by date. For example:

SELECT FORMAT(order_date, 'yyyy-MM') AS order_month, SUM(order_amount) AS total_sales FROM orders WHERE order_status = 'delivered' GROUP BY FORMAT(order_date, 'yyyy-MM');
```
This formats the `order_date` to group data by month.

## 11. Window Functions for Cumulative Calculations
I used window functions to calculate cumulative values. For example:

SELECT 
  customer_id,
  FORMAT(order_date, 'yyyy-MM') AS month,
  SUM(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS cumulative_revenue
FROM orders_payments;
```
This query calculates the cumulative revenue for each customer, partitioned by customer_id.

## 12. Creating Views
I created a view to simplify complex joins and repeated queries:

CREATE VIEW orders_payments AS
SELECT 
  o.order_id,
  o.customer_id,
  o.order_date,
  o.order_amount,
  o.order_status,
  p.payment_id,
  p.payment_date,
  p.payment_amount,
  p.payment_status
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id;
```
The `orders_payments` view combines the `orders` and `payments` tables.

## 13. Handling Payment Status Analysis
To analyze payment statuses and calculate payment success rates, I used conditional aggregation. For example:
```sql
SELECT 
  SUM(CASE WHEN payment_status = 'Completed' THEN 1 ELSE 0 END) AS completed_count,
  SUM(CASE WHEN payment_status IN ('Pending', 'Failed') THEN 1 ELSE 0 END) AS pending_failed_count
FROM payments;
```
This calculates the number of completed and pending/failed payments.

## 14. Data Quality Checks
To ensure data quality, I have  used queries like the following to detect anomalies:

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
```
This query identifies cases where the payment date occurs before the order date.

---

### Conclusion
The queries in this project utilize various SQL techniques to extract insights, perform data validation, and analyze trends from Alt Mobility's orders and payments data.
