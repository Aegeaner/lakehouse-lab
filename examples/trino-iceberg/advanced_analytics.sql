-- Advanced Analytics with Trino-Iceberg

-- Create a partitioned table for better performance
CREATE SCHEMA IF NOT EXISTS iceberg.analytics;

CREATE TABLE iceberg.analytics.sales (
    id BIGINT,
    customer_id BIGINT,
    product_id BIGINT,
    amount DECIMAL(10,2),
    quantity INTEGER,
    sale_date DATE,
    region VARCHAR
) WITH (
    format = 'PARQUET',
    location = 's3://lakehouse/iceberg/analytics/sales',
    partitioning = ARRAY['region', 'sale_date']
);

-- Insert sample sales data
INSERT INTO iceberg.analytics.sales VALUES
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
FROM iceberg.analytics.sales
GROUP BY region
ORDER BY total_revenue DESC;

-- Daily sales trends
SELECT 
    sale_date,
    COUNT(*) as daily_sales,
    SUM(amount) as daily_revenue
FROM iceberg.analytics.sales
GROUP BY sale_date
ORDER BY sale_date;

-- Top products by revenue
SELECT 
    product_id,
    COUNT(*) as times_sold,
    SUM(amount) as total_revenue,
    SUM(quantity) as total_quantity
FROM iceberg.analytics.sales
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
FROM iceberg.analytics.sales
ORDER BY region, sale_date;

-- Monthly aggregations
SELECT 
    YEAR(sale_date) as year,
    MONTH(sale_date) as month,
    region,
    COUNT(*) as monthly_sales,
    SUM(amount) as monthly_revenue
FROM iceberg.analytics.sales
GROUP BY YEAR(sale_date), MONTH(sale_date), region
ORDER BY year, month, region;

-- Show partition information
SELECT * FROM iceberg.analytics."sales$partitions";