/*
===============================================================================
                    RETAIL SALES ANALYSIS PROJECT  (MySQL 8)
===============================================================================
 File        : 03_data_exploration.sql
 Description : Exploratory analysis to understand the shape and volume of the
               cleaned dataset before answering business questions.
===============================================================================
*/

USE retail_sales_project;


-- EDA 1 : Total number of transactions
SELECT COUNT(*) AS total_sales
FROM retail_sales;


-- EDA 2 : Number of unique customers
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM retail_sales;


-- EDA 3 : Number of product categories
SELECT COUNT(DISTINCT category) AS total_categories
FROM retail_sales;


-- EDA 4 : List the categories
SELECT DISTINCT category
FROM retail_sales
ORDER BY category;


-- EDA 5 : Period covered by the dataset
SELECT
    MIN(sale_date) AS first_sale_date,
    MAX(sale_date) AS last_sale_date,
    DATEDIFF(MAX(sale_date), MIN(sale_date)) AS days_covered
FROM retail_sales;


-- EDA 6 : Transactions by gender
SELECT
    gender,
    COUNT(*) AS total_transactions
FROM retail_sales
GROUP BY gender
ORDER BY total_transactions DESC;


-- EDA 7 : Transactions by category
SELECT
    category,
    COUNT(*) AS total_transactions
FROM retail_sales
GROUP BY category
ORDER BY total_transactions DESC;


-- EDA 8 : Age profile of customers
SELECT
    MIN(age)            AS minimum_age,
    MAX(age)            AS maximum_age,
    ROUND(AVG(age), 2)  AS average_age,
    SUM(age IS NULL)    AS customers_with_unknown_age
FROM retail_sales;
-- AVG and MIN/MAX ignore NULLs automatically; the last column makes the
-- excluded rows visible rather than silent.


-- EDA 9 : Revenue overview
SELECT
    ROUND(SUM(total_sale), 2) AS total_revenue,
    ROUND(AVG(total_sale), 2) AS average_sale,
    MIN(total_sale)           AS minimum_sale,
    MAX(total_sale)           AS maximum_sale
FROM retail_sales;


-- EDA 10 : Gross profit and margin by category
-- The dataset carries cogs, so margin is available. The original project never
-- used it, which leaves the most business-relevant number on the table.
SELECT
    category,
    ROUND(SUM(total_sale), 2)                                   AS revenue,
    ROUND(SUM(cogs * quantity), 2)                              AS cost,
    ROUND(SUM(total_sale) - SUM(cogs * quantity), 2)            AS gross_profit,
    ROUND(100 * (SUM(total_sale) - SUM(cogs * quantity))
              / SUM(total_sale), 2)                             AS margin_pct
FROM retail_sales
GROUP BY category
ORDER BY gross_profit DESC;
