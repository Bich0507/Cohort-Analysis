/* Build a cohort chart for all customer of Electricity billing in 2017 */

-- Tinh so KH quay tro lai (retention rate) cua nhung KH trong thang 1

WITH table_first AS (
SELECT customer_id, order_id, transaction_date,
    MIN (MONTH (transaction_date) ) OVER (PARTITION BY customer_id) AS first_month
FROM payment_history_17 AS his_17
JOIN product as pro 
    ON his_17.product_id = pro.product_number 
WHERE message_id = 1 --don hang thanh cong
    AND sub_category = 'Electricity'
), 
table_month AS (
SELECT *,
    MONTH (transaction_date) - first_month AS month_n
FROM table_first
),
table_retained AS (
SELECT first_month, month_n,
    COUNT (DISTINCT customer_id) AS retained_customers
FROM table_month 
WHERE first_month = 1
GROUP BY first_month, month_n
)
SELECT *,
    MAX (retained_customers) OVER () AS orginal_customers,
    CAST (retained_customers AS DECIMAL) / MAX (retained_customers) OVER () AS rate
FROM table_retained;

-- Tinh so KH quay tro lai (retention rate) trong ca nam 2017

WITH table_first AS (
SELECT customer_id, order_id, transaction_date,
    MIN (MONTH (transaction_date) ) OVER (PARTITION BY customer_id) AS first_month
FROM payment_history_17 AS his_17
JOIN product as pro 
    ON his_17.product_id = pro.product_number 
WHERE message_id = 1 --don hang thanh cong
    AND sub_category = 'Electricity'
), 
table_month AS (
SELECT *,
    MONTH (transaction_date) - first_month AS month_n
FROM table_first
),
table_retained AS (
SELECT first_month, month_n,
    COUNT (DISTINCT customer_id) AS retained_customers
FROM table_month 
GROUP BY first_month, month_n
)
SELECT *,
    MAX (retained_customers) OVER (PARTITION BY first_month) AS orginal_customers,
    FIRST_VALUE(retained_customers) OVER (PARTITION BY first_month ORDER BY month_n) AS orginal_customers_2,
    CAST (retained_customers AS DECIMAL) / MAX (retained_customers) OVER (PARTITION BY first_month) AS rate
FROM table_retained
ORDER BY first_month, month_n;

--PIVOT TABLE
WITH table_first AS (
SELECT customer_id, order_id, transaction_date,
    MIN (MONTH (transaction_date) ) OVER (PARTITION BY customer_id) AS first_month
FROM payment_history_17 AS his_17
JOIN product as pro 
    ON his_17.product_id = pro.product_number 
WHERE message_id = 1 --don hang thanh cong
    AND sub_category = 'Electricity'
), 
table_month AS (
SELECT *,
    MONTH (transaction_date) - first_month AS month_n
FROM table_first
),
table_retained AS (
SELECT first_month, month_n,
    COUNT (DISTINCT customer_id) AS retained_customers
FROM table_month 
GROUP BY first_month, month_n
),
table_retention AS (
SELECT *,
    MAX (retained_customers) OVER (PARTITION BY first_month) AS original_customers,
    CAST (retained_customers AS DECIMAL) / MAX (retained_customers) OVER (PARTITION BY first_month) AS rate
FROM table_retained
)
SELECT first_month, original_customers,
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "11"
FROM (
    SELECT first_month, month_n, original_customers, CAST (rate AS DECIMAL (10, 2) ) as rate
    FROM table_retention
) AS source_table
PIVOT (
    SUM (rate) --lay gia tri tuong ung, co the dung AVG, MIN, MAX
    FOR month_n IN ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "11")
) AS pivot_logic
ORDER BY first_month

