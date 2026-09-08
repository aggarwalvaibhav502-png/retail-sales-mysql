/*
===============================================================================
                    RETAIL SALES ANALYSIS PROJECT  (MySQL 8)
===============================================================================
 File        : 02_data_cleaning.sql
 Description : Profiles missing values, removes unusable records, and
               validates the cleaned dataset.
===============================================================================
*/

USE retail_sales_project;


-- ============================================================================
-- STEP 1 : Record count before cleaning
-- ============================================================================

SELECT COUNT(*) AS total_records FROM retail_sales;   -- expect 2000


-- ============================================================================
-- STEP 2 : Normalise empty strings to NULL
-- ============================================================================
-- Only needed if you imported through the Workbench wizard, which can write
-- '' into text columns instead of NULL. Harmless to run either way.
-- If you hit error 1175, run: SET SQL_SAFE_UPDATES = 0;

UPDATE retail_sales SET gender   = NULL WHERE TRIM(gender)   = '';
UPDATE retail_sales SET category = NULL WHERE TRIM(category) = '';


-- ============================================================================
-- STEP 3 : Count missing values per column
-- ============================================================================
-- Profiling column by column, rather than a bare SELECT *, tells you which
-- fields are actually damaged and therefore what the right fix is.

SELECT
    SUM(transactions_id IS NULL) AS null_transactions_id,
    SUM(sale_date       IS NULL) AS null_sale_date,
    SUM(sale_time       IS NULL) AS null_sale_time,
    SUM(customer_id     IS NULL) AS null_customer_id,
    SUM(gender          IS NULL) AS null_gender,
    SUM(age             IS NULL) AS null_age,
    SUM(category        IS NULL) AS null_category,
    SUM(quantity        IS NULL) AS null_quantity,
    SUM(price_per_unit  IS NULL) AS null_price_per_unit,
    SUM(cogs            IS NULL) AS null_cogs,
    SUM(total_sale      IS NULL) AS null_total_sale
FROM retail_sales;

-- Result: age = 10, quantity = 3, price_per_unit = 3, cogs = 3, total_sale = 3.
-- 13 affected rows, and they fall into two distinct groups.


-- ============================================================================
-- STEP 4 : Inspect the two groups separately
-- ============================================================================

-- Group A: the sale itself is missing. Nothing to analyse in these rows.
SELECT * FROM retail_sales
WHERE quantity IS NULL OR price_per_unit IS NULL
   OR cogs IS NULL OR total_sale IS NULL;          -- 3 rows

-- Group B: a valid, complete sale where only customer age is unknown.
SELECT * FROM retail_sales
WHERE age IS NULL
  AND total_sale IS NOT NULL;                      -- 10 rows


-- ============================================================================
-- STEP 5 : Remove only the unusable records
-- ============================================================================
-- Decision: drop Group A, keep Group B.
--
-- Group A has no revenue, quantity or cost, so it cannot contribute to any
-- analysis in this project. Group B still carries date, customer, category
-- and revenue, all of which are valid. Deleting those 10 rows would discard
-- real sales to fix a demographic field that only two queries use. Instead,
-- the age-based queries filter age IS NOT NULL, so the missing values are
-- excluded where they matter and retained where they do not.

DELETE FROM retail_sales
WHERE quantity IS NULL
   OR price_per_unit IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL;

-- Alternative, if you prefer complete-case analysis: also run
--     DELETE FROM retail_sales WHERE age IS NULL;
-- which leaves 1,987 rows. Be ready to justify losing the revenue.


-- ============================================================================
-- STEP 6 : Validate
-- ============================================================================

SELECT COUNT(*) AS cleaned_records FROM retail_sales;   -- expect 1997

SELECT COUNT(*) AS rows_missing_sale_data
FROM retail_sales
WHERE quantity IS NULL OR price_per_unit IS NULL
   OR cogs IS NULL OR total_sale IS NULL;               -- expect 0


-- ============================================================================
-- STEP 7 : Reconcile the arithmetic
-- ============================================================================
-- total_sale should equal quantity * price_per_unit. Checking a derived
-- column against its inputs is a basic data-quality control and a good thing
-- to be able to point to.

SELECT COUNT(*) AS rows_that_do_not_reconcile
FROM retail_sales
WHERE ABS(total_sale - (quantity * price_per_unit)) > 0.01;


-- ============================================================================
-- STEP 8 : Range checks
-- ============================================================================

SELECT
    MIN(age) AS min_age, MAX(age) AS max_age,
    MIN(quantity) AS min_qty, MAX(quantity) AS max_qty,
    MIN(total_sale) AS min_sale, MAX(total_sale) AS max_sale
FROM retail_sales;

SELECT COUNT(*) AS duplicate_transaction_ids
FROM (
    SELECT transactions_id
    FROM retail_sales
    GROUP BY transactions_id
    HAVING COUNT(*) > 1
) AS d;
