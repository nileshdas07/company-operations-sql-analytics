-- ============================================================
-- Company Operations Database & Analytics
-- Full reference file: Data Cleaning + Business Analysis Queries
-- ============================================================
USE company_ops;

-- ============================================================
-- SECTION 1: DATA CLEANING
-- ============================================================

-- 1a. Find duplicate attendance records (same employee + same date)
SELECT employee_id, attendance_date, COUNT(*) AS duplicate_count
FROM attendance
GROUP BY employee_id, attendance_date
HAVING COUNT(*) > 1;

-- 1b. View full detail of duplicate rows
SELECT a.*
FROM attendance a
JOIN (
    SELECT employee_id, attendance_date
    FROM attendance
    GROUP BY employee_id, attendance_date
    HAVING COUNT(*) > 1
) dup ON a.employee_id = dup.employee_id
      AND a.attendance_date = dup.attendance_date
ORDER BY a.employee_id, a.attendance_date;

-- 1c. Remove duplicates (keep the row with the lowest attendance_id)
DELETE a1 FROM attendance a1
INNER JOIN attendance a2
    ON a1.employee_id = a2.employee_id
    AND a1.attendance_date = a2.attendance_date
    AND a1.attendance_id > a2.attendance_id;

-- 1d. Clean employees.department — remove extra spaces
UPDATE employees
SET department = TRIM(department);

-- 1e. Clean employees.department — standardize casing
UPDATE employees
SET department = CASE
    WHEN LOWER(department) = 'sales' THEN 'Sales'
    WHEN LOWER(department) = 'warehouse' THEN 'Warehouse'
    WHEN LOWER(department) = 'hr' THEN 'HR'
    WHEN LOWER(department) = 'finance' THEN 'Finance'
    WHEN LOWER(department) = 'operations' THEN 'Operations'
    ELSE department
END;

-- 1f. Clean products.category — standardize casing
UPDATE products
SET category = CASE
    WHEN LOWER(category) = 'electronics' THEN 'Electronics'
    WHEN LOWER(category) = 'stationery' THEN 'Stationery'
    WHEN LOWER(category) = 'furniture' THEN 'Furniture'
    WHEN LOWER(category) = 'apparel' THEN 'Apparel'
    WHEN LOWER(category) = 'groceries' THEN 'Groceries'
    ELSE category
END;

-- 1g. Fix Cancelled orders that still have a delivery_date (should be NULL)
UPDATE orders
SET delivery_date = NULL
WHERE status = 'Cancelled' AND delivery_date IS NOT NULL;

-- 1h. Fix invalid rows where delivery_date < order_date (set to NULL)
UPDATE orders
SET delivery_date = NULL
WHERE delivery_date < order_date;


-- ============================================================
-- SECTION 2: BUSINESS ANALYSIS QUERIES
-- ============================================================

-- Q1. Which department has the highest late-arrival / absenteeism rate?
SELECT
    e.department,
    COUNT(*) AS total_records,
    SUM(CASE WHEN a.status = 'Late' THEN 1 ELSE 0 END) AS late_count,
    SUM(CASE WHEN a.status = 'Absent' THEN 1 ELSE 0 END) AS absent_count,
    ROUND(SUM(CASE WHEN a.status = 'Late' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_pct,
    ROUND(SUM(CASE WHEN a.status = 'Absent' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS absent_pct
FROM attendance a
JOIN employees e ON a.employee_id = e.employee_id
GROUP BY e.department
ORDER BY late_pct DESC;

-- Q2. Which products are below reorder level (stockout risk)?
SELECT 
    product_id,
    product_name,
    category,
    current_stock,
    reorder_level,
    (reorder_level - current_stock) AS units_below_reorder
FROM products
WHERE current_stock < reorder_level
ORDER BY units_below_reorder DESC;

-- Q3a. Order status breakdown (% of total)
SELECT 
    status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct_of_total
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- Q3b. Average / fastest / slowest delivery time (Delivered orders only)
SELECT 
    ROUND(AVG(DATEDIFF(delivery_date, order_date)), 2) AS avg_delivery_days,
    MIN(DATEDIFF(delivery_date, order_date)) AS fastest_delivery,
    MAX(DATEDIFF(delivery_date, order_date)) AS slowest_delivery
FROM orders
WHERE status = 'Delivered';

-- Q4. Employee performance — orders processed + delayed %
SELECT 
    e.employee_id,
    e.full_name,
    e.department,
    COUNT(o.order_id) AS total_orders_processed,
    SUM(CASE WHEN o.status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_orders,
    ROUND(SUM(CASE WHEN o.status = 'Delayed' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id), 2) AS delayed_pct
FROM orders o
JOIN employees e ON o.employee_id = e.employee_id
GROUP BY e.employee_id, e.full_name, e.department
HAVING COUNT(o.order_id) >= 3
ORDER BY total_orders_processed DESC
LIMIT 10;

-- Q5. Cross-domain: does attendance discipline correlate with delivery delays?
SELECT 
    e.department,
    ROUND(AVG(att.late_pct), 2) AS avg_attendance_late_pct,
    ROUND(AVG(ord.delayed_pct), 2) AS avg_orders_delayed_pct
FROM employees e
JOIN (
    SELECT employee_id, 
           SUM(CASE WHEN status = 'Late' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS late_pct
    FROM attendance
    GROUP BY employee_id
) att ON e.employee_id = att.employee_id
JOIN (
    SELECT employee_id,
           SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS delayed_pct
    FROM orders
    GROUP BY employee_id
) ord ON e.employee_id = ord.employee_id
GROUP BY e.department
ORDER BY avg_attendance_late_pct DESC;
