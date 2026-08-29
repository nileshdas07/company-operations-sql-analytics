# Company Operations Database \& Analytics

A multi-domain SQL project simulating how an Ops/MIS team tracks and reports on **employee attendance, inventory, and sales orders** — built as a single relational database in MySQL.

## Problem Statement

Companies typically track HR/attendance, inventory, and sales/order data in separate systems, making it hard to answer cross-functional business questions quickly (e.g. *"Is a department's attendance discipline linked to its delivery performance?"*). This project simulates a small ops team's data in one relational database so that these questions can be answered directly with SQL — the kind of reporting work an MIS Executive / Operations Analyst does day to day.

## Tech Stack

* **MySQL 8.0**
* Sample data generated with Python (Faker library) — includes intentionally realistic data quality issues (duplicates, inconsistent text casing, invalid dates) to practice and demonstrate data cleaning

## Schema

Four tables, connected via foreign keys:

```
employees (1) ──< attendance (many)
employees (1) ──< orders (many)
products  (1) ──< orders (many)
```

|Table|Description|Key Columns|
|-|-|-|
|`employees`|Employee master data|employee\_id (PK), department, designation, shift|
|`attendance`|Daily attendance logs|attendance\_id (PK), employee\_id (FK), status, check\_in/out|
|`products`|Inventory master data|product\_id (PK), category, current\_stock, reorder\_level|
|`orders`|Sales orders|order\_id (PK), product\_id (FK), employee\_id (FK), status, order/delivery dates|

**Scale:** 30 employees · 15 products · \~2,300 attendance records (90 days) · 150 orders

See [`schema.sql`](schema.sql) for full DDL.

## Data Quality Issues (Intentionally Included)

Real operational data is rarely clean. This dataset includes common real-world issues, handled in the cleaning section of [`queries.sql`](queries.sql):

* Duplicate attendance entries (same employee + date logged twice)
* Inconsistent text casing/spacing (`'SALES'`, `'sales '`, `'Sales'`)
* Orders marked "Cancelled" that still had a delivery date (logical inconsistency)
* Rows where `delivery\_date` was earlier than `order\_date` (invalid data entry)

Each issue was first identified with a `SELECT` query, then corrected with a targeted `UPDATE`/`DELETE`, following the practice of always previewing affected rows before modifying data.

## Business Questions Answered

|#|Question|Technique Used|
|-|-|-|
|1|Which department has the highest late-arrival / absenteeism rate?|JOIN, conditional aggregation (`SUM(CASE WHEN...)`)|
|2|Which products are below reorder level (stockout risk)?|Filtering, calculated column|
|3|What % of orders are delayed/cancelled? What's the average delivery time?|Subquery, `DATEDIFF()`, aggregate functions|
|4|Which employees process the most orders, and what's their delay rate?|Multi-column GROUP BY, HAVING|
|5|Does attendance discipline correlate with order delivery delays? (cross-domain)|Nested subqueries, multi-table JOIN, AVG aggregation|

### Key Insights

* **Warehouse** has the most attendance records but the lowest late-arrival rate (8.66%) — the largest team is also the most disciplined.
* **\~19% of all orders were delayed** — a meaningful SLA breach rate worth flagging to management.
* **No clear correlation** was found between a department's attendance discipline and its order-delay rate (e.g. Sales has strong attendance but the highest delay rate) — suggesting delays stem from causes other than employee punctuality, such as inventory availability or logistics.

## How to Run

1. Run `schema.sql` to create the database and tables
2. Load the sample data (`employees\_multirow.sql`, `products\_multirow.sql`, `attendance.csv` / `orders.csv` via `LOAD DATA INFILE`, or the provided multi-row insert files)
3. Run the cleaning queries in `queries.sql` (Section 1)
4. Run the business analysis queries (Section 2) to reproduce the insights above

## Notes

This project uses synthetic (generated) sample data to simulate a realistic single-location ops team — it is a practice/demonstration project, not based on real company data.

