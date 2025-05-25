-- Advanced Analytics with Trino using Memory Catalog
-- Demonstrates all analytics features without S3/file system dependencies

-- Clean up any existing table
DROP TABLE IF EXISTS memory.default.sales;

-- Create sales table
CREATE TABLE memory.default.sales (
    id BIGINT,
    customer_id BIGINT,
    product_id BIGINT,
    amount DECIMAL(10,2),
    quantity INTEGER,
    sale_date DATE,
    region VARCHAR
);

-- Insert sample sales data
INSERT INTO memory.default.sales VALUES
(1, 101, 1001, 99.99, 1, DATE '2024-01-15', 'North'),
(2, 102, 1002, 149.99, 2, DATE '2024-01-16', 'South'),
(3, 103, 1001, 99.99, 1, DATE '2024-01-17', 'East'),
(4, 104, 1003, 299.99, 1, DATE '2024-01-18', 'West'),
(5, 105, 1002, 149.99, 3, DATE '2024-01-19', 'North'),
(6, 106, 1001, 99.99, 2, DATE '2024-01-20', 'South'),
(7, 107, 1004, 499.99, 1, DATE '2024-01-21', 'East'),
(8, 108, 1002, 149.99, 1, DATE '2024-01-22', 'West'),
(9, 109, 1003, 299.99, 2, DATE '2024-01-23', 'North'),
(10, 110, 1001, 99.99, 4, DATE '2024-01-24', 'South');

-- Sales by region
SELECT 
    region,
    COUNT(*) as total_sales,
    SUM(amount) as total_revenue,
    AVG(amount) as avg_sale_amount,
    SUM(quantity) as total_quantity
FROM memory.default.sales
GROUP BY region
ORDER BY total_revenue DESC;

-- Daily sales trends
SELECT 
    sale_date,
    COUNT(*) as daily_sales,
    SUM(amount) as daily_revenue
FROM memory.default.sales
GROUP BY sale_date
ORDER BY sale_date;

-- Top products by revenue
SELECT 
    product_id,
    COUNT(*) as times_sold,
    SUM(amount) as total_revenue,
    SUM(quantity) as total_quantity
FROM memory.default.sales
GROUP BY product_id
ORDER BY total_revenue DESC;

-- Window functions for running totals
SELECT 
    sale_date,
    region,
    amount,
    SUM(amount) OVER (
        PARTITION BY region 
        ORDER BY sale_date 
        ROWS UNBOUNDED PRECEDING
    ) as running_total_by_region
FROM memory.default.sales
ORDER BY region, sale_date;

-- Advanced window functions
SELECT 
    sale_date,
    region,
    amount,
    LAG(amount) OVER (PARTITION BY region ORDER BY sale_date) as prev_amount,
    LEAD(amount) OVER (PARTITION BY region ORDER BY sale_date) as next_amount,
    RANK() OVER (PARTITION BY region ORDER BY amount DESC) as amount_rank,
    NTILE(4) OVER (ORDER BY amount) as quartile
FROM memory.default.sales
ORDER BY region, sale_date;

-- Complex analytics with CTEs
WITH regional_stats AS (
    SELECT 
        region,
        AVG(amount) as avg_amount,
        STDDEV(amount) as stddev_amount
    FROM memory.default.sales
    GROUP BY region
),
sales_with_stats AS (
    SELECT 
        s.*,
        rs.avg_amount as region_avg,
        rs.stddev_amount as region_stddev,
        (s.amount - rs.avg_amount) / rs.stddev_amount as z_score
    FROM memory.default.sales s
    JOIN regional_stats rs ON s.region = rs.region
)
SELECT 
    region,
    sale_date,
    amount,
    region_avg,
    z_score,
    CASE 
        WHEN ABS(z_score) > 1.5 THEN 'Outlier'
        ELSE 'Normal'
    END as outlier_status
FROM sales_with_stats
ORDER BY region, sale_date;