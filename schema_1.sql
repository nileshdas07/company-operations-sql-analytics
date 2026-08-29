USE company_ops;

-- ============================================
-- TABLE 1: employees
-- ============================================
CREATE TABLE employees (
    employee_id     INT AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    department      VARCHAR(50) NOT NULL,
    designation     VARCHAR(50),
    join_date       DATE NOT NULL,
    shift           VARCHAR(20)   -- Morning / Evening / Night
);

-- ============================================
-- TABLE 2: attendance
-- ============================================
CREATE TABLE attendance (
    attendance_id   INT AUTO_INCREMENT PRIMARY KEY,
    employee_id     INT NOT NULL,
    attendance_date DATE NOT NULL,
    check_in        TIME,
    check_out       TIME,
    status          VARCHAR(20) NOT NULL,   -- Present / Absent / Late / Half-Day
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- ============================================
-- TABLE 3: products
-- ============================================
CREATE TABLE products (
    product_id      INT AUTO_INCREMENT PRIMARY KEY,
    product_name    VARCHAR(100) NOT NULL,
    category        VARCHAR(50) NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    reorder_level   INT NOT NULL,
    current_stock   INT NOT NULL
);

-- ============================================
-- TABLE 4: orders
-- ============================================
CREATE TABLE orders (
    order_id        INT AUTO_INCREMENT PRIMARY KEY,
    product_id      INT NOT NULL,
    employee_id     INT NOT NULL,
    order_date      DATE NOT NULL,
    delivery_date   DATE,
    quantity        INT NOT NULL,
    status          VARCHAR(20) NOT NULL,   -- Delivered / Pending / Delayed / Cancelled
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);
