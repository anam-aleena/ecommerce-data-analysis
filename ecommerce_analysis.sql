-- ============================================================
-- E-COMMERCE DATA ANALYSIS — PostgreSQL
-- Author: Aleena Anam
-- GitHub: github.com/anam-aleena
-- Description: Advanced SQL analysis on e-commerce data
--              covering customer behaviour, retention,
--              funnel analysis, and business KPIs
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE SETUP — Sample E-Commerce Schema
-- ============================================================

CREATE TABLE IF NOT EXISTS customers (
    customer_id     SERIAL PRIMARY KEY,
    customer_name   VARCHAR(100),
    email           VARCHAR(150),
    city            VARCHAR(100),
    signup_date     DATE,
    channel         VARCHAR(50)   -- organic, paid, referral, social
);

CREATE TABLE IF NOT EXISTS products (
    product_id      SERIAL PRIMARY KEY,
    product_name    VARCHAR(150),
    category        VARCHAR(100),
    price           NUMERIC(10,2),
    cost            NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id        SERIAL PRIMARY KEY,
    customer_id     INT REFERENCES customers(customer_id),
    order_date      DATE,
    status          VARCHAR(50),   -- completed, cancelled, refunded
    total_amount    NUMERIC(10,2),
    discount        NUMERIC(10,2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS order_items (
    item_id         SERIAL PRIMARY KEY,
    order_id        INT REFERENCES orders(order_id),
    product_id      INT REFERENCES products(product_id),
    quantity        INT,
    unit_price      NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS marketing_spend (
    spend_id        SERIAL PRIMARY KEY,
    channel         VARCHAR(50),
    spend_date      DATE,
    amount_spent    NUMERIC(10,2),
    impressions     INT,
    clicks          INT
);


-- ============================================================
-- SECTION 2: BASIC EXPLORATION
-- ============================================================

-- 2.1 Total orders and revenue by month
SELECT
    DATE_TRUNC('month', order_date)     AS month,
    COUNT(order_id)                     AS total_orders,
    SUM(total_amount)                   AS gross_revenue,
    SUM(discount)                       AS total_discounts,
    SUM(total_amount - discount)        AS net_revenue,
    ROUND(AVG(total_amount), 2)         AS avg_order_value
FROM orders
WHERE status = 'completed'
GROUP BY 1
ORDER BY 1;


-- 2.2 Top 10 products by revenue
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity)                            AS units_sold,
    SUM(oi.quantity * oi.unit_price)            AS total_revenue,
    ROUND(AVG(oi.unit_price), 2)                AS avg_selling_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id   = o.order_id
WHERE o.status = 'completed'
GROUP BY p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;


-- 2.3 Revenue by product category
SELECT
    p.category,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    SUM(oi.quantity * oi.unit_price)            AS total_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price) * 100.0
        / SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 2
    )                                           AS revenue_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id   = o.order_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY total_revenue DESC;


-- ============================================================
-- SECTION 3: CUSTOMER ANALYSIS
-- ============================================================

-- 3.1 Customer segmentation — new vs returning
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(order_id)     AS total_orders,
        MIN(order_date)     AS first_order,
        MAX(order_date)     AS last_order,
        SUM(total_amount)   AS lifetime_value
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time buyer'
        WHEN total_orders BETWEEN 2 AND 4 THEN 'Occasional buyer'
        WHEN total_orders >= 5 THEN 'Loyal customer'
    END                         AS customer_segment,
    COUNT(*)                    AS customer_count,
    ROUND(AVG(lifetime_value), 2) AS avg_ltv,
    ROUND(AVG(total_orders), 1)   AS avg_orders
FROM customer_order_counts
GROUP BY 1
ORDER BY avg_ltv DESC;


-- 3.2 Customer Lifetime Value (LTV) — top 20 customers
SELECT
    c.customer_name,
    c.city,
    c.channel,
    COUNT(o.order_id)                       AS total_orders,
    SUM(o.total_amount)                     AS lifetime_value,
    ROUND(AVG(o.total_amount), 2)           AS avg_order_value,
    MIN(o.order_date)                       AS first_purchase,
    MAX(o.order_date)                       AS last_purchase,
    MAX(o.order_date) - MIN(o.order_date)   AS customer_lifespan_days
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.customer_name, c.city, c.channel
ORDER BY lifetime_value DESC
LIMIT 20;


-- 3.3 Monthly new customer acquisition by channel
SELECT
    DATE_TRUNC('month', signup_date)    AS month,
    channel,
    COUNT(customer_id)                  AS new_customers
FROM customers
GROUP BY 1, 2
ORDER BY 1, 3 DESC;


-- ============================================================
-- SECTION 4: RETENTION & CHURN ANALYSIS
-- ============================================================

-- 4.1 Month-over-month customer retention
-- Which customers who purchased in month N also purchased in month N+1?
WITH monthly_customers AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date) AS purchase_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY 1, 2
),
retention_base AS (
    SELECT
        curr.purchase_month                             AS cohort_month,
        COUNT(DISTINCT curr.customer_id)                AS active_customers,
        COUNT(DISTINCT next.customer_id)                AS retained_customers
    FROM monthly_customers curr
    LEFT JOIN monthly_customers next
        ON curr.customer_id    = next.customer_id
        AND next.purchase_month = curr.purchase_month + INTERVAL '1 month'
    GROUP BY 1
)
SELECT
    cohort_month,
    active_customers,
    retained_customers,
    ROUND(retained_customers * 100.0 / NULLIF(active_customers, 0), 2) AS retention_rate_pct,
    active_customers - retained_customers                               AS churned_customers,
    ROUND((active_customers - retained_customers) * 100.0
          / NULLIF(active_customers, 0), 2)                            AS churn_rate_pct
FROM retention_base
ORDER BY cohort_month;


-- 4.2 Cohort retention heatmap data
-- Classic cohort analysis: retention by months since first purchase
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        fp.cohort_month,
        DATE_TRUNC('month', o.order_date)   AS activity_month,
        COUNT(DISTINCT o.customer_id)        AS active_customers
    FROM orders o
    JOIN first_purchase fp ON o.customer_id = fp.customer_id
    WHERE o.status = 'completed'
    GROUP BY 1, 2
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_customers
    FROM first_purchase
    GROUP BY 1
)
SELECT
    ca.cohort_month,
    EXTRACT(YEAR FROM AGE(ca.activity_month, ca.cohort_month)) * 12
        + EXTRACT(MONTH FROM AGE(ca.activity_month, ca.cohort_month)) AS months_since_first,
    cs.cohort_customers,
    ca.active_customers,
    ROUND(ca.active_customers * 100.0 / cs.cohort_customers, 2)       AS retention_pct
FROM cohort_activity ca
JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
ORDER BY 1, 2;


-- ============================================================
-- SECTION 5: FUNNEL & CONVERSION ANALYSIS
-- ============================================================

-- 5.1 Order funnel — completion vs cancellation vs refund
SELECT
    status,
    COUNT(order_id)                                         AS order_count,
    ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER (), 2) AS pct_of_total,
    SUM(total_amount)                                       AS total_value
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- 5.2 Average Order Value (AOV) trend — window function
SELECT
    DATE_TRUNC('month', order_date)             AS month,
    ROUND(AVG(total_amount), 2)                 AS monthly_aov,
    ROUND(AVG(AVG(total_amount)) OVER (
        ORDER BY DATE_TRUNC('month', order_date)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                        AS rolling_3m_aov
FROM orders
WHERE status = 'completed'
GROUP BY 1
ORDER BY 1;


-- 5.3 Repeat purchase rate
WITH purchase_counts AS (
    SELECT
        customer_id,
        COUNT(order_id) AS num_orders
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT
    COUNT(*)                                                AS total_customers,
    COUNT(CASE WHEN num_orders > 1 THEN 1 END)            AS repeat_customers,
    ROUND(COUNT(CASE WHEN num_orders > 1 THEN 1 END)
          * 100.0 / COUNT(*), 2)                          AS repeat_purchase_rate_pct
FROM purchase_counts;


-- ============================================================
-- SECTION 6: MARKETING & CAC ANALYSIS
-- ============================================================

-- 6.1 Customer Acquisition Cost (CAC) by channel
WITH channel_customers AS (
    SELECT channel, COUNT(customer_id) AS customers_acquired
    FROM customers
    GROUP BY channel
),
channel_spend AS (
    SELECT channel, SUM(amount_spent) AS total_spend
    FROM marketing_spend
    GROUP BY channel
)
SELECT
    cc.channel,
    cc.customers_acquired,
    ROUND(cs.total_spend, 2)                                AS total_marketing_spend,
    ROUND(cs.total_spend / NULLIF(cc.customers_acquired, 0), 2) AS cac
FROM channel_customers cc
JOIN channel_spend cs ON cc.channel = cs.channel
ORDER BY cac;


-- 6.2 Return on Ad Spend (ROAS) by channel
WITH channel_revenue AS (
    SELECT
        c.channel,
        SUM(o.total_amount) AS total_revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
    GROUP BY c.channel
),
channel_spend AS (
    SELECT channel, SUM(amount_spent) AS total_spend
    FROM marketing_spend
    GROUP BY channel
)
SELECT
    cr.channel,
    ROUND(cr.total_revenue, 2)                              AS revenue,
    ROUND(cs.total_spend, 2)                                AS ad_spend,
    ROUND(cr.total_revenue / NULLIF(cs.total_spend, 0), 2) AS roas
FROM channel_revenue cr
JOIN channel_spend cs ON cr.channel = cs.channel
ORDER BY roas DESC;


-- ============================================================
-- SECTION 7: ADVANCED WINDOW FUNCTIONS
-- ============================================================

-- 7.1 Customer purchase ranking within each city
SELECT
    c.city,
    c.customer_name,
    SUM(o.total_amount)                         AS total_spent,
    RANK() OVER (
        PARTITION BY c.city
        ORDER BY SUM(o.total_amount) DESC
    )                                           AS city_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.city, c.customer_id, c.customer_name
ORDER BY c.city, city_rank;


-- 7.2 Running total revenue with month-over-month growth
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date)     AS month,
        SUM(total_amount)                   AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY 1
)
SELECT
    month,
    ROUND(revenue, 2)                       AS monthly_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY month), 2)  AS cumulative_revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2)  AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        * 100.0 / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2
    )                                       AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;


-- 7.3 Product sales rank using DENSE_RANK
SELECT
    p.category,
    p.product_name,
    SUM(oi.quantity * oi.unit_price)            AS revenue,
    DENSE_RANK() OVER (
        PARTITION BY p.category
        ORDER BY SUM(oi.quantity * oi.unit_price) DESC
    )                                           AS rank_in_category
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id   = o.order_id
WHERE o.status = 'completed'
GROUP BY p.category, p.product_id, p.product_name
ORDER BY p.category, rank_in_category;


-- ============================================================
-- SECTION 8: COMMON TABLE EXPRESSIONS (CTEs)
-- ============================================================

-- 8.1 Multi-step CTE: identify high-value at-risk customers
-- (High LTV but haven't purchased in 60+ days)
WITH customer_ltv AS (
    SELECT
        customer_id,
        SUM(total_amount)       AS lifetime_value,
        COUNT(order_id)         AS total_orders,
        MAX(order_date)         AS last_purchase_date
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),
high_value AS (
    SELECT *
    FROM customer_ltv
    WHERE lifetime_value > (SELECT PERCENTILE_CONT(0.75)
                             WITHIN GROUP (ORDER BY lifetime_value)
                             FROM customer_ltv)
),
at_risk AS (
    SELECT *
    FROM high_value
    WHERE last_purchase_date < CURRENT_DATE - INTERVAL '60 days'
)
SELECT
    c.customer_name,
    c.email,
    c.channel,
    ar.lifetime_value,
    ar.total_orders,
    ar.last_purchase_date,
    CURRENT_DATE - ar.last_purchase_date       AS days_since_purchase
FROM at_risk ar
JOIN customers c ON ar.customer_id = c.customer_id
ORDER BY ar.lifetime_value DESC;


-- 8.2 CTE: contribution margin by product
WITH product_margins AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.price,
        p.cost,
        p.price - p.cost            AS unit_margin,
        ROUND((p.price - p.cost)
              * 100.0 / p.price, 2) AS margin_pct
    FROM products p
),
product_sales AS (
    SELECT
        oi.product_id,
        SUM(oi.quantity)                        AS units_sold,
        SUM(oi.quantity * oi.unit_price)        AS total_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY oi.product_id
)
SELECT
    pm.product_name,
    pm.category,
    pm.margin_pct,
    ps.units_sold,
    ps.total_revenue,
    ROUND(pm.unit_margin * ps.units_sold, 2)    AS total_contribution_margin
FROM product_margins pm
JOIN product_sales ps ON pm.product_id = ps.product_id
ORDER BY total_contribution_margin DESC;


-- ============================================================
-- END OF ANALYSIS
-- Queries written by: Aleena Anam
-- Contact: anamaleena0@gmail.com
-- GitHub: github.com/anam-aleena
-- ============================================================
