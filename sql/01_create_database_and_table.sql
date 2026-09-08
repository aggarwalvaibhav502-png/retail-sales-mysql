/*
===============================================================================
                    RETAIL SALES ANALYSIS PROJECT  (MySQL 8)
===============================================================================
 File        : 01_create_database_and_table.sql
 Description : Creates the database, the retail_sales table, and loads the CSV.
 Database    : MySQL 8.0 or higher (later scripts use window functions and
               CTEs, which do not exist in MySQL 5.7)
===============================================================================
*/

-- ============================================================================
-- Create and select the database
-- ============================================================================

CREATE DATABASE IF NOT EXISTS retail_sales_project;

USE retail_sales_project;


-- ============================================================================
-- Create the retail_sales table
-- ============================================================================

DROP TABLE IF EXISTS retail_sales;

CREATE TABLE retail_sales
(
    transactions_id   INT PRIMARY KEY,
    sale_date         DATE,
    sale_time         TIME,
    customer_id       INT,
    gender            VARCHAR(15),
    age               INT,
    category          VARCHAR(15),
    quantity          INT,
    price_per_unit    FLOAT,
    cogs              FLOAT,
    total_sale        FLOAT
);


-- ============================================================================
-- Load the CSV
-- ============================================================================
-- Three details in this file that will break a naive import:
--
--   1. Blank cells appear in numeric columns (age, quantity, price_per_unit,
--      cogs, total_sale). MySQL 8 runs in STRICT_TRANS_TABLES by default, so
--      loading '' into an INT raises error 1366. The columns are read into
--      user variables (@age and friends) and NULLIF turns '' into NULL.
--
--   2. The file uses Windows CRLF line endings, so LINES TERMINATED BY must
--      be '\r\n'. With '\n' the last column of every row keeps a trailing
--      carriage return.
--
--   3. The file starts with a UTF-8 BOM. IGNORE 1 LINES skips the header row
--      that carries it, so it causes no harm here.
--
-- Before running this, check where MySQL is allowed to read files from:
--      SHOW VARIABLES LIKE 'secure_file_priv';
-- Copy the CSV into that folder and use its full path below.
--
-- If you would rather not deal with file permissions, use MySQL Workbench:
-- right-click the retail_sales table -> Table Data Import Wizard. It handles
-- blanks and line endings for you. Then skip straight to script 02.
-- ============================================================================

/*
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/retail_sales_raw.csv'
INTO TABLE retail_sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(   transactions_id,
    @sale_date,
    @sale_time,
    customer_id,
    gender,
    @age,
    category,
    @quantity,
    @price_per_unit,
    @cogs,
    @total_sale
)
SET
    sale_date      = NULLIF(@sale_date, ''),
    sale_time      = NULLIF(@sale_time, ''),
    age            = NULLIF(@age, ''),
    quantity       = NULLIF(@quantity, ''),
    price_per_unit = NULLIF(@price_per_unit, ''),
    cogs           = NULLIF(@cogs, ''),
    total_sale     = NULLIF(@total_sale, '');
*/


-- ============================================================================
-- Verify the load
-- ============================================================================

SELECT COUNT(*) AS rows_loaded FROM retail_sales;   -- expect 2000

SELECT * FROM retail_sales LIMIT 10;
