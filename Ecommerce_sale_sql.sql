USE BANK;

-- TOTAL ORDERS
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders;

-- TOTAL CUSTOMERS
SELECT COUNT(DISTINCT customer_id) AS total_customer
FROM customers;

-- TOTAL REVENUE
SELECT ROUND(SUM(pay.amount_paid - pay.transaction_fee),2) AS total_revenue
FROM payments pay;

-- TOTAL PROFIT
SELECT SUM(
(pay.amount_paid - pay.transaction_fee)
- (p.cost * oi.quantity)
) 
AS total_profit
FROM payments pay
JOIN orders o
ON pay.order_id = o.order_id
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id;

 -- GENDER BY REVENUE
SELECT c.gender,
ROUND(SUM(o.total_amount),2) AS revenue
FROM customers c
JOIN orders o
ON o.customer_id = o.customer_id
GROUP BY c.gender;

-- MONTHLY REVENUE TREND
SELECT
    DATE_FORMAT(o.order_date, '%Y-%M') AS month,
    SUM(pay.amount_paid - pay.transaction_fee) AS revenue
FROM orders o
JOIN payments pay
ON o.order_id = pay.order_id
GROUP BY month
ORDER BY month;

-- MONTHLY PROFIT TREND
SELECT 
     DATE_FORMAT(o.order_date, '%Y-%m') AS month,
     ROUND(SUM(
	(pay.amount_paid - pay.transaction_fee) 
	- (oi.quantity * p.cost)
	),2)AS monthly_profit
FROM orders o
JOIN order_items oi
 ON o.order_id = oi.order_id
JOIN products p
 ON oi.product_id = p.product_id
JOIN payments pay 
ON o.order_id = pay.order_id
GROUP BY month
ORDER BY month;

-- CATEGORY-WISE REVENUE & PROFIT
SELECT 
     ROUND(SUM(oi.final_price),2)AS revenue,
     ROUND(SUM(
(pay.amount_paid - pay.transaction_fee)
- (p.cost * oi.quantity)
),2) AS profit
FROM order_items oi
JOIN orders o
ON oi.order_id = o.order_id
JOIN products p
ON oi.product_id = p.product_id
JOIN payments pay
ON o.order_id = pay.order_id
GROUP BY p.category
ORDER BY profit DESC;

-- TOP 10 LOSS-MAKING PRODUCTS
SELECT
    p.product_name,
    SUM(
        (pay.amount_paid - pay.transaction_fee)
        - (oi.quantity * p.cost)
    ) AS loss
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN payments pay ON o.order_id = pay.order_id
GROUP BY p.product_name
HAVING loss < 0
ORDER BY loss ASC
LIMIT 10;

-- ORDER STATUS IMPACT
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(pay.amount_paid - pay.transaction_fee),2)AS revenue_impact
FROM orders o
JOIN payments pay ON o.order_id = pay.order_id
GROUP BY o.order_status;

-- CUSTOMER LIFETIME VALUE
SELECT
    c.customer_id,
    ROUND(SUM(pay.amount_paid - pay.transaction_fee),2) AS customer_lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments pay ON o.order_id = pay.order_id
GROUP BY c.customer_id
ORDER BY customer_lifetime_value DESC;

-- PRODUCT PERFORMANCE CATEGORY
SELECT
    p.product_name,
    ROUND(SUM(oi.final_price),2) AS revenue,
    CASE
        WHEN SUM(oi.final_price) >= 100000 THEN 'Best Seller'
        WHEN SUM(oi.final_price) BETWEEN 50000 AND 99999 THEN 'Average Seller'
        ELSE 'Low Performer'
    END AS product_performance
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name;

-- PAYMENT SUCCESS ANALYSIS
SELECT
    pay.payment_mode,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN pay.payment_status = 'Success' THEN 1
            ELSE 0
        END
    ) AS successful_payments
FROM payments pay
GROUP BY pay.payment_mode;

-- MONTHLY SALES TREND LABELING
SELECT
    month,
    revenue,
    CASE
        WHEN revenue > LAG(revenue) OVER (ORDER BY month) THEN 'Growth'
        WHEN revenue < LAG(revenue) OVER (ORDER BY month) THEN 'Decline'
        ELSE 'No Change'
    END AS trend_status
FROM (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        ROUND(SUM(pay.amount_paid - pay.transaction_fee),2) AS revenue
    FROM orders o
    JOIN payments pay ON o.order_id = pay.order_id
    GROUP BY month
) t;

-- TOP 3 MOST PURCHASED ITEMS
WITH product_sales AS (
    SELECT
        p.product_name,
        SUM(oi.quantity) AS total_quantity
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_name
)
SELECT
    product_name,
    total_quantity
FROM product_sales
ORDER BY total_quantity DESC
LIMIT 3;