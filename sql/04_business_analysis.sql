/*
===============================================================================
                    RETAIL SALES ANALYSIS PROJECT  (MySQL 8)
===============================================================================
 File        : 04_business_analysis.sql
 Description : Business questions answered with SQL. Covers sales performance,
               customer behaviour, category performance, revenue trends and
               time-of-day analysis.
 Requires    : MySQL 8.0+ (CTEs and window functions)
===============================================================================
*/

USE retail_sales_project;


-- ============================================================================
-- Q1 : All sales made on 5 November 2022
-- Objective: retrieve transactions for a specific trading day.
-- ============================================================================

SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';


-- ============================================================================
-- Q2 : Clothing transactions with quantity >= 4 during November 2022
-- Objective: isolate high-volume Clothing purchases in a given month.
-- ============================================================================

SELECT *
FROM retail_sales
WHERE category = 'Clothing'
  AND DATE_FORMAT(sale_date, '%Y-%m') = '2022-11'
  AND quantity >= 4;

-- Note: DATE_FORMAT on the column prevents index use. On a large table prefer
-- a range predicate, which is sargable:
--
-- WHERE category = 'Clothing'
--   AND sale_date >= '2022-11-01'
--   AND sale_date <  '2022-12-01'
--   AND quantity >= 4;


-- ============================================================================
-- Q3 : Total revenue and order count per category
-- Objective: identify the highest revenue-generating category.
-- ============================================================================

SELECT
    category,
    ROUND(SUM(total_sale), 2) AS total_revenue,
    COUNT(*)                  AS total_orders
FROM retail_sales
GROUP BY category
ORDER BY total_revenue DESC;


-- ============================================================================
-- Q4 : Average age of customers buying Beauty products
-- Objective: profile the Beauty category audience.
-- ============================================================================

SELECT
    ROUND(AVG(age), 2) AS average_customer_age,
    COUNT(age)         AS customers_counted
FROM retail_sales
WHERE category = 'Beauty'
  AND age IS NOT NULL;


-- ============================================================================
-- Q5 : Transactions above 1000
-- Objective: surface high-value orders.
-- ============================================================================

SELECT *
FROM retail_sales
WHERE total_sale > 1000
ORDER BY total_sale DESC;


-- ============================================================================
-- Q6 : Transactions by gender within each category
-- Objective: compare purchasing patterns across gender and category.
-- ============================================================================

SELECT
    category,
    gender,
    COUNT(*) AS total_transactions
FROM retail_sales
GROUP BY category, gender
ORDER BY category, total_transactions DESC;


-- ============================================================================
-- Q7 : Best-selling month in each year, by average sale value
-- Objective: find the peak month per year for seasonality planning.
-- Technique: RANK() over a partition, filtered in an outer query.
-- ============================================================================

SELECT
    sales_year,
    sales_month,
    average_sale
FROM
(
    SELECT
        YEAR(sale_date)             AS sales_year,
        MONTH(sale_date)            AS sales_month,
        ROUND(AVG(total_sale), 2)   AS average_sale,
        RANK() OVER (
            PARTITION BY YEAR(sale_date)
            ORDER BY AVG(total_sale) DESC
        )                           AS sales_rank
    FROM retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
) AS ranked_sales
WHERE sales_rank = 1
ORDER BY sales_year;

-- Why the window function sits outside the aggregate: RANK() is evaluated
-- after GROUP BY, so it can order by AVG(total_sale) directly. It cannot be
-- filtered in the same SELECT, which is why the subquery wrapper is needed.
-- RANK() is used rather than ROW_NUMBER() so a genuine tie returns both months.


-- ============================================================================
-- Q8 : Top 5 customers by revenue
-- Objective: identify the most valuable customers.
-- ============================================================================

SELECT
    customer_id,
    ROUND(SUM(total_sale), 2) AS total_revenue,
    COUNT(*)                  AS total_orders
FROM retail_sales
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 5;


-- ============================================================================
-- Q9 : Unique customers per category
-- Objective: measure customer reach across categories.
-- ============================================================================

SELECT
    category,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM retail_sales
GROUP BY category
ORDER BY unique_customers DESC;


-- ============================================================================
-- Q10 : Orders by time-of-day shift
-- Objective: understand when customers buy, for staffing decisions.
-- Technique: CTE plus CASE bucketing.
-- ============================================================================

WITH hourly_sales AS
(
    SELECT
        transactions_id,
        total_sale,
        CASE
            WHEN HOUR(sale_time) < 12                  THEN 'Morning'
            WHEN HOUR(sale_time) BETWEEN 12 AND 17     THEN 'Afternoon'
            ELSE                                            'Evening'
        END AS sales_shift
    FROM retail_sales
)
SELECT
    sales_shift,
    COUNT(*)                  AS total_orders,
    ROUND(SUM(total_sale), 2) AS shift_revenue
FROM hourly_sales
GROUP BY sales_shift
ORDER BY total_orders DESC;


-- ============================================================================
-- Q11 : Highest revenue day
-- ============================================================================

SELECT
    sale_date,
    ROUND(SUM(total_sale), 2) AS total_revenue
FROM retail_sales
GROUP BY sale_date
ORDER BY total_revenue DESC
LIMIT 1;


-- ============================================================================
-- Q12 : Average order value
-- ============================================================================

SELECT ROUND(AVG(total_sale), 2) AS average_order_value
FROM retail_sales;


-- ============================================================================
-- Q13 : Revenue by gender
-- ============================================================================

SELECT
    gender,
    ROUND(SUM(total_sale), 2) AS total_revenue,
    COUNT(*)                  AS total_orders
FROM retail_sales
GROUP BY gender
ORDER BY total_revenue DESC;


-- ============================================================================
-- Q14 : Top 5 revenue dates
-- ============================================================================

SELECT
    sale_date,
    ROUND(SUM(total_sale), 2) AS total_revenue
FROM retail_sales
GROUP BY sale_date
ORDER BY total_revenue DESC
LIMIT 5;


-- ============================================================================
-- Q15 : Month-on-month revenue growth
-- Objective: show the trend, not just the level.
-- Technique: LAG() to reach the previous month's value on the same row.
-- ============================================================================

WITH monthly_revenue AS
(
    SELECT
        DATE_FORMAT(sale_date, '%Y-%m')  AS sales_month,
        ROUND(SUM(total_sale), 2)        AS revenue
    FROM retail_sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
)
SELECT
    sales_month,
    revenue,
    LAG(revenue) OVER (ORDER BY sales_month) AS previous_month_revenue,
    ROUND(
        100 * (revenue - LAG(revenue) OVER (ORDER BY sales_month))
            / LAG(revenue) OVER (ORDER BY sales_month),
        2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY sales_month;


-- ============================================================================
-- Q16 : Customer segmentation by spend
-- Objective: split the customer base into value tiers.
-- Technique: NTILE() to divide customers into quartiles by revenue.
-- ============================================================================

WITH customer_spend AS
(
    SELECT
        customer_id,
        SUM(total_sale) AS lifetime_value,
        COUNT(*)        AS orders
    FROM retail_sales
    GROUP BY customer_id
)
SELECT
    CASE quartile
        WHEN 1 THEN 'Top 25%'
        WHEN 2 THEN 'Upper middle'
        WHEN 3 THEN 'Lower middle'
        WHEN 4 THEN 'Bottom 25%'
    END                                 AS segment,
    COUNT(*)                            AS customers,
    ROUND(AVG(lifetime_value), 2)       AS avg_lifetime_value,
    ROUND(AVG(orders), 2)               AS avg_orders
FROM
(
    SELECT
        customer_id,
        lifetime_value,
        orders,
        NTILE(4) OVER (ORDER BY lifetime_value DESC) AS quartile
    FROM customer_spend
) AS segmented
GROUP BY quartile
ORDER BY quartile;
