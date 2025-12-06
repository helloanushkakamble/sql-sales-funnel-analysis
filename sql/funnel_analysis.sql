USE SalesFunnelDB;
CREATE TABLE salesfunnel_customers (
    user_id INT PRIMARY KEY,
    gender VARCHAR(10),
    city VARCHAR(50),
    signup_date DATE
);

CREATE TABLE salesfunnel_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);
CREATE TABLE funnel_events (
    event_id INT PRIMARY KEY,
    event_type VARCHAR(50),
    user_id INT,
    product_id INT,
    event_timestamp DATETIME,
    FOREIGN KEY (user_id) REFERENCES customers(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
SELECT TABLE_NAME 
FROM SalesFunnelDB.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT COUNT(*) AS cnt FROM customers;
SELECT COUNT(*) AS cnt FROM products;
SELECT COUNT(*) AS cnt FROM funnel_events;

SELECT COUNT(*) as Customers FROM new_customers;
SELECT COUNT(*) as Products FROM new_products;
SELECT COUNT(*) as Funnel_Events FROM new_funnel_events;

SELECT event_type,
       COUNT(DISTINCT user_id) AS unique_users
FROM new_funnel_events
GROUP BY event_type
ORDER BY unique_users DESC;

USE SalesFunnelDB;

WITH stage_counts AS (
    SELECT event_type,
           COUNT(DISTINCT user_id) AS users
    FROM dbo.new_funnel_events    -- explicit schema
    GROUP BY event_type
)
, funnel AS (
    SELECT 
      COALESCE((SELECT users FROM stage_counts WHERE event_type='view'), 0) AS views,
      COALESCE((SELECT users FROM stage_counts WHERE event_type='add_to_cart'), 0) AS add_to_cart,
      COALESCE((SELECT users FROM stage_counts WHERE event_type='checkout'), 0) AS checkout_users,
      COALESCE((SELECT users FROM stage_counts WHERE event_type='payment'), 0) AS payment_users,
      COALESCE((SELECT users FROM stage_counts WHERE event_type='order_placed'), 0) AS orders
)
SELECT
  views,
  add_to_cart,
  checkout_users,
  payment_users,
  orders,
  -- conversion rates
  CASE WHEN views = 0 THEN 0 ELSE ROUND( (CAST(add_to_cart AS DECIMAL(10,4)) / views) * 100, 2) END AS pct_view_to_cart,
  CASE WHEN add_to_cart = 0 THEN 0 ELSE ROUND( (CAST(checkout_users AS DECIMAL(10,4)) / add_to_cart) * 100, 2) END AS pct_cart_to_checkout,
  CASE WHEN checkout_users = 0 THEN 0 ELSE ROUND( (CAST(payment_users AS DECIMAL(10,4)) / checkout_users) * 100, 2) END AS pct_checkout_to_payment,
  CASE WHEN payment_users = 0 THEN 0 ELSE ROUND( (CAST(orders AS DECIMAL(10,4)) / payment_users) * 100, 2) END AS pct_payment_to_order,
  CASE WHEN views = 0 THEN 0 ELSE ROUND( (CAST(orders AS DECIMAL(10,4)) / views) * 100, 2) END AS pct_view_to_order
FROM funnel;

USE SalesFunnelDB;

WITH steps AS (
  SELECT user_id, event_type, MIN(event_timestamp) AS ts
  FROM dbo.new_funnel_events
  GROUP BY user_id, event_type
),
combined AS (
  SELECT 
    v.user_id,
    DATEDIFF(MINUTE, v.ts, a.ts) AS view_to_cart_min,
    DATEDIFF(MINUTE, a.ts, c.ts) AS cart_to_checkout_min,
    DATEDIFF(MINUTE, c.ts, p.ts) AS checkout_to_payment_min,
    DATEDIFF(MINUTE, p.ts, o.ts) AS payment_to_order_min
  FROM steps v
  LEFT JOIN steps a ON v.user_id = a.user_id AND a.event_type = 'add_to_cart'
  LEFT JOIN steps c ON v.user_id = c.user_id AND c.event_type = 'checkout'
  LEFT JOIN steps p ON v.user_id = p.user_id AND p.event_type = 'payment'
  LEFT JOIN steps o ON v.user_id = o.user_id AND o.event_type = 'order_placed'
  WHERE v.event_type = 'view'
),
aggs AS (
  SELECT
    COUNT(*) AS user_sessions,
    AVG(CAST(view_to_cart_min AS FLOAT))         AS avg_view_to_cart_min,
    AVG(CAST(cart_to_checkout_min AS FLOAT))    AS avg_cart_to_checkout_min,
    AVG(CAST(checkout_to_payment_min AS FLOAT)) AS avg_checkout_to_payment_min,
    AVG(CAST(payment_to_order_min AS FLOAT))    AS avg_payment_to_order_min
  FROM combined
),
med AS (
  SELECT
    (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY view_to_cart_min) OVER () FROM combined)       AS median_view_to_cart_min,
    (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cart_to_checkout_min) OVER () FROM combined)    AS median_cart_to_checkout_min,
    (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY checkout_to_payment_min) OVER () FROM combined) AS median_checkout_to_payment_min,
    (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY payment_to_order_min) OVER () FROM combined)    AS median_payment_to_order_min
)
SELECT
  ROUND(a.user_sessions,0) AS user_sessions,
  ROUND(a.avg_view_to_cart_min,2)         AS avg_view_to_cart_min,
  m.median_view_to_cart_min               AS median_view_to_cart_min,
  ROUND(a.avg_cart_to_checkout_min,2)     AS avg_cart_to_checkout_min,
  m.median_cart_to_checkout_min           AS median_cart_to_checkout_min,
  ROUND(a.avg_checkout_to_payment_min,2)  AS avg_checkout_to_payment_min,
  m.median_checkout_to_payment_min        AS median_checkout_to_payment_min,
  ROUND(a.avg_payment_to_order_min,2)     AS avg_payment_to_order_min,
  m.median_payment_to_order_min           AS median_payment_to_order_min
FROM aggs a CROSS JOIN med m;

USE SalesFunnelDB;

WITH stage_counts AS (
    SELECT 
        c.city,
        e.event_type,
        COUNT(DISTINCT e.user_id) AS users
    FROM dbo.new_funnel_events e
    JOIN dbo.new_customers c 
        ON e.user_id = c.user_id
    GROUP BY c.city, e.event_type
),
pivoted AS (
    SELECT 
        city,
        COALESCE([view], 0) AS views,
        COALESCE([add_to_cart], 0) AS add_to_cart,
        COALESCE([checkout], 0) AS checkout_users,
        COALESCE([payment], 0) AS payment_users,
        COALESCE([order_placed], 0) AS orders
    FROM stage_counts
    PIVOT (
        SUM(users)
        FOR event_type IN ([view], [add_to_cart], [checkout], [payment], [order_placed])
    ) AS pvt
)
SELECT 
    city,
    views,
    add_to_cart,
    checkout_users,
    payment_users,
    orders,
    ROUND((add_to_cart*1.0/views)*100, 2) AS pct_view_to_cart,
    ROUND((checkout_users*1.0/add_to_cart)*100, 2) AS pct_cart_to_checkout,
    ROUND((payment_users*1.0/checkout_users)*100, 2) AS pct_checkout_to_payment,
    ROUND((orders*1.0/payment_users)*100, 2) AS pct_payment_to_order,
    ROUND((orders*1.0/views)*100, 2) AS pct_view_to_order
FROM pivoted
ORDER BY pct_view_to_order DESC;

USE SalesFunnelDB;

WITH stage_counts AS (
    SELECT 
        p.product_id,
        p.product_name,
        e.event_type,
        COUNT(DISTINCT e.user_id) AS users
    FROM dbo.new_funnel_events e
    JOIN dbo.new_products p 
        ON e.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, e.event_type
),
pivoted AS (
    SELECT 
        product_id,
        product_name,
        COALESCE([view], 0) AS views,
        COALESCE([add_to_cart], 0) AS add_to_cart,
        COALESCE([checkout], 0) AS checkout_users,
        COALESCE([payment], 0) AS payment_users,
        COALESCE([order_placed], 0) AS orders
    FROM stage_counts
    PIVOT (
        SUM(users)
        FOR event_type IN ([view], [add_to_cart], [checkout], [payment], [order_placed])
    ) AS p
)
SELECT 
    product_id,
    product_name,
    views,
    add_to_cart,
    orders,
    ROUND((orders*1.0/views)*100, 2) AS pct_view_to_order
FROM pivoted
ORDER BY pct_view_to_order DESC;

USE SalesFunnelDB;

WITH stage_counts AS (
    SELECT 
        p.category,
        e.event_type,
        COUNT(DISTINCT e.user_id) AS users
    FROM dbo.new_funnel_events e
    JOIN dbo.new_products p
        ON e.product_id = p.product_id
    GROUP BY p.category, e.event_type
),
pivoted AS (
    SELECT 
        category,
        COALESCE([view], 0) AS views,
        COALESCE([add_to_cart], 0) AS add_to_cart,
        COALESCE([checkout], 0) AS checkout_users,
        COALESCE([payment], 0) AS payment_users,
        COALESCE([order_placed], 0) AS orders
    FROM stage_counts
    PIVOT (
        SUM(users)
        FOR event_type IN ([view], [add_to_cart], [checkout], [payment], [order_placed])
    ) AS p
)
SELECT 
    category,
    views,
    add_to_cart,
    orders,
    ROUND((add_to_cart*1.0/views)*100, 2) AS pct_view_to_cart,
    ROUND((orders*1.0/views)*100, 2) AS pct_view_to_order
FROM pivoted
ORDER BY pct_view_to_order DESC;

Add SQL funnel analysis script
