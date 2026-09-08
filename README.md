# Retail Sales Analysis — MySQL

End-to-end SQL analysis of a retail transactions dataset: schema design, data cleaning, exploratory analysis, and business questions answered in SQL.

**Database:** MySQL 8.0+ (window functions and CTEs are used, so 5.7 will not work)
**Dataset:** 2,000 retail transactions, 11 columns, CSV (1,997 after cleaning)
**Tools:** MySQL Workbench

---

## Project structure

```
retail-sales-mysql
│
├── README.md
├── data
│   └── retail_sales_raw.csv
└── sql
    ├── 01_create_database_and_table.sql
    ├── 02_data_cleaning.sql
    ├── 03_data_exploration.sql
    └── 04_business_analysis.sql
```

---

## Schema

| Column | Type |
|---|---|
| transactions_id | INT (PK) |
| sale_date | DATE |
| sale_time | TIME |
| customer_id | INT |
| gender | VARCHAR(15) |
| age | INT |
| category | VARCHAR(15) |
| quantity | INT |
| price_per_unit | FLOAT |
| cogs | FLOAT |
| total_sale | FLOAT |

---

## Workflow

1. **Schema creation** — database and table defined with an explicit primary key.
2. **Data cleaning** — missing values profiled per column, which showed two distinct groups: 3 rows with no sale data at all, and 10 complete sales missing only customer age. The first group was dropped; the second was kept and excluded from age-based queries. Arithmetic reconciled (`total_sale` vs `quantity × price_per_unit`), ranges and duplicate keys checked.
3. **Exploration** — record counts, unique customers, category list, date range, age profile, revenue overview, and gross margin by category.
4. **Business analysis** — 16 questions covering category revenue, customer value, seasonality, time-of-day patterns and month-on-month growth.

---

## SQL techniques used

- DDL and DML (`CREATE`, `DROP`, `UPDATE`, `DELETE`)
- Aggregation with `GROUP BY` and `HAVING`
- `CASE` expressions for bucketing
- Common Table Expressions (`WITH`)
- Window functions: `RANK()`, `LAG()`, `NTILE()`
- Date and time functions: `YEAR()`, `MONTH()`, `HOUR()`, `DATE_FORMAT()`, `DATEDIFF()`
- `COUNT(DISTINCT ...)`, subqueries, aliasing

---

## Selected findings

**Dataset:** 1,997 transactions from 155 customers, 2022-01-01 to 2023-12-31. Total revenue ₹911,720; average order value ₹456.54.

- **Revenue ranking and profit ranking disagree.** Electronics leads on revenue (₹313,810 across 684 orders) but Clothing generates more gross profit (₹143,963 vs ₹142,030) because it carries a higher margin — 46.28% against 45.26%. Beauty has the best margin of the three at 47.93% but the smallest revenue base. Ranking categories by revenue alone would point at the wrong winner.
- **The three categories are far more evenly matched than expected**, at 34.4%, 34.1% and 31.5% of revenue. There is no dominant line to build a strategy around.
- **Evening is the dominant trading window**, taking 1,062 of 1,997 orders (53.2%) against 558 in the morning and 377 in the afternoon. Staffing and promotion timing should follow that split.
- **But evening orders are smaller.** Average order value drops to ₹448.15 in the evening versus ₹465.77 in the morning and ₹466.53 in the afternoon. The evening wins on traffic, not on basket size.
- **Beauty attracts the largest baskets** at ₹468.69 per order, ahead of Electronics at ₹458.79 and Clothing at ₹443.75 — the reverse of the order-count ranking.
- **The top quartile of customers drives 51.37% of revenue** — 39 of 155 customers, contributing ₹468,325 against ₹71,285 from the bottom quartile. The top two quartiles together account for 77.16%.
- **That gap is about frequency more than basket size.** Top-quartile customers place 23.38 orders on average against 6.74 in the bottom quartile — a 3.5× difference — while their average order is only 1.8× larger (₹513.62 vs ₹278.33). Retention efforts would pay off more than upselling.
- **No stable seasonal pattern across the two years.** The strongest month by average sale was July 2022 (₹541.34) and February 2023 (₹535.53) — different months, and each only about 18% above the overall average of ₹456.54. With two years of data there is no basis for a seasonality claim.

## Data quality notes

- 13 of 2,000 raw rows were incomplete, in two distinct groups: 3 rows missing `quantity`, `price_per_unit`, `cogs` and `total_sale` together, and 10 complete sales missing only `customer_age`.
- The first group was deleted — with no quantity or revenue, those rows cannot contribute to any analysis here. The second group was kept, and the age-based queries exclude NULLs instead. Dropping 10 valid sales to fix a demographic field that two queries use would have discarded real revenue.
- `total_sale` reconciles against `quantity × price_per_unit` across the cleaned dataset, and `transactions_id` contains no duplicates.

## How to run

1. Create the database and table: run `01_create_database_and_table.sql`.
2. Load the CSV with `LOAD DATA INFILE` (the statement is in script 01). MySQL only reads files from the folder returned by `SHOW VARIABLES LIKE 'secure_file_priv';`, so copy the CSV there first and point the path at it. Use forward slashes even on Windows.
3. Run scripts 02, 03 and 04 in order.

Two notes on the load. The CSV has blank cells in numeric columns, and MySQL 8's strict mode rejects `''` in an INT — the statement reads those columns into user variables and applies `NULLIF` so they arrive as NULL. Workbench's Table Data Import Wizard silently drops those 13 rows instead, which would leave nothing for the cleaning script to do.

If `DELETE` fails with error 1175, run `SET SQL_SAFE_UPDATES = 0;` first — that is Workbench's safe update mode, not a problem with the query.

---

## Dataset credit

The retail sales CSV is a widely used public practice dataset. The SQL, schema and analysis in this repository are my own.
