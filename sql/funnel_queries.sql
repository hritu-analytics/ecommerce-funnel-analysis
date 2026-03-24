-- =====================================================================
-- E-Commerce Funnel Analysis — SQL Queries
-- =====================================================================
-- These queries were written to explore the Olist dataset and identify
-- where the order funnel breaks down. I used SQLite locally to run these 
-- before moving to Python for the visualisations.
--
-- Note: If you're loading the CSV files into a database, you'll need 
-- three tables: orders, order_items, order_payments
-- =====================================================================


-- Q1: Overall order status distribution
-- First thing I checked — how healthy is the funnel overall?

SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1) AS pct
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- Q2: Completion rate by payment method
-- This is the query that changed my entire hypothesis.
-- I expected the problem to be checkout UX. Instead, it was payment-specific.

SELECT 
    p.payment_type,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) AS canceled,
    ROUND(
        SUM(CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS completion_rate,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY p.payment_type
ORDER BY completion_rate;


-- Q3: Revenue lost to failed boleto orders
-- Quantifying the actual business impact — not just percentages

SELECT 
    COUNT(*) AS failed_boleto_orders,
    ROUND(SUM(p.payment_value), 2) AS total_lost_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_lost_order_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE p.payment_type = 'boleto'
  AND o.order_status IN ('canceled', 'unavailable', 'processing');


-- Q4: State-level breakdown — credit card vs boleto gap
-- Wanted to see if the boleto problem was uniform or geographic

SELECT 
    o.customer_state,
    p.payment_type,
    COUNT(*) AS total_orders,
    ROUND(
        SUM(CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS completion_rate
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE p.payment_type IN ('credit_card', 'boleto')
  AND o.customer_state IN ('SP', 'RJ', 'MG', 'RS', 'PR', 'SC', 'BA', 'DF')
GROUP BY o.customer_state, p.payment_type
ORDER BY o.customer_state, p.payment_type;


-- Q5: Monthly trend — is the boleto problem getting worse or better?

SELECT 
    SUBSTR(o.order_purchase_timestamp, 1, 7) AS order_month,
    SUM(CASE WHEN p.payment_type = 'boleto' THEN 1 ELSE 0 END) AS boleto_orders,
    SUM(CASE WHEN p.payment_type = 'boleto' AND o.order_status != 'delivered' THEN 1 ELSE 0 END) AS boleto_failures,
    ROUND(
        SUM(CASE WHEN p.payment_type = 'boleto' AND o.order_status != 'delivered' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN p.payment_type = 'boleto' THEN 1 ELSE 0 END), 0), 1
    ) AS boleto_fail_rate
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY order_month
HAVING boleto_orders > 20
ORDER BY order_month;


-- Q6: Product categories most affected by cancellation
-- Are certain types of products more likely to be abandoned?

SELECT 
    i.product_category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) AS cancellations,
    ROUND(
        SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) * 100.0 
        / COUNT(DISTINCT o.order_id), 1
    ) AS cancel_rate
FROM orders o
JOIN order_items i ON o.order_id = i.order_id
GROUP BY i.product_category
HAVING total_orders >= 50
ORDER BY cancel_rate DESC
LIMIT 10;


-- Q7: Delivery performance vs review scores
-- Even for completed orders — are we damaging the brand with late deliveries?

SELECT 
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(CAST(o.review_score AS FLOAT)), 2) AS avg_review,
    SUM(CASE WHEN o.review_score IN ('1', '2') THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND(
        SUM(CASE WHEN o.review_score IN ('1', '2') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS pct_negative
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.review_score != ''
GROUP BY delivery_status;


-- Q8: Credit card installment analysis
-- Do more installments correlate with higher completion?
-- (Hypothesis: customers who commit to installments are more invested)

SELECT 
    p.payment_installments,
    COUNT(*) AS total_orders,
    ROUND(
        SUM(CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS completion_rate,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE p.payment_type = 'credit_card'
GROUP BY p.payment_installments
ORDER BY p.payment_installments;
