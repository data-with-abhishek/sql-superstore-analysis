-- 1. Overall Business Performance

SELECT
    COUNT(DISTINCT Order_ID) AS total_orders,
    COUNT(DISTINCT Customer_ID) AS total_customers,
    SUM(Sales) AS total_sales,
    ROUND(SUM(Sales) * 1.0 / COUNT(DISTINCT Order_ID), 2) AS avg_order_value
FROM superstore;


-- Region-wise Total Sales

SELECT
    Region,
    COUNT(DISTINCT Order_ID) AS total_orders,
    SUM(Sales) AS total_sales
FROM superstore
GROUP BY Region;


-- Identify Best & Worst Region based on Total Sales
WITH sales AS (
    SELECT
        Region,
        COUNT(DISTINCT Order_ID) AS total_orders,
        SUM(Sales) AS total_sales
    FROM superstore
    GROUP BY Region
)
SELECT
    Region,
    total_orders,
    total_sales,
    CASE
        WHEN total_sales = MAX(total_sales) OVER () THEN 'Best Performer'
        WHEN total_sales = MIN(total_sales) OVER () THEN 'Worst Performer'
        ELSE 'Normal Performer'
    END AS performance_flag
FROM sales
ORDER BY total_sales DESC;


--------- Identifying the reason for bad performance -----------

-- Contribution % by Region

WITH region_sales AS (
    SELECT
        Region,
        SUM(Sales) AS total_sales
    FROM superstore
    GROUP BY Region
)
SELECT
    Region,
    total_sales,
    ROUND(total_sales * 100.0 / SUM(total_sales) OVER(), 2) AS contribution_pct
FROM region_sales
ORDER BY total_sales DESC;


-- Revenue per Order (Avg. Order Value) by Region & Category
SELECT
    Region,
    Category,
    COUNT(DISTINCT Order_ID) AS total_orders,
    SUM(Sales) AS total_sales,
    ROUND(SUM(Sales) * 1.0 / COUNT(DISTINCT Order_ID), 2) AS revenue_per_order
FROM superstore
GROUP BY Region, Category;


-- Root Cause of Bad Performance (South Region - Lowest Category)
SELECT TOP 1
    Category,
    COUNT(DISTINCT Order_ID) AS total_orders,
    SUM(Sales) AS total_sales
FROM superstore
WHERE Region = 'South'
GROUP BY Category
ORDER BY SUM(Sales) ASC;


-- Total Sales of Each Region by Year
SELECT
    YEAR(Order_Date) AS order_year,
    Region,
    COUNT(DISTINCT Order_ID) AS total_orders,
    SUM(Sales) AS total_sales
FROM superstore
GROUP BY YEAR(Order_Date), Region
ORDER BY order_year ASC, total_orders DESC;


-- Pivot Form (Order Count by Region)
SELECT
    YEAR(Order_Date) AS order_year,
    COUNT(DISTINCT CASE WHEN Region = 'East' THEN Order_ID END) AS East,
    COUNT(DISTINCT CASE WHEN Region = 'West' THEN Order_ID END) AS West,
    COUNT(DISTINCT CASE WHEN Region = 'Central' THEN Order_ID END) AS Central,
    COUNT(DISTINCT CASE WHEN Region = 'South' THEN Order_ID END) AS South
FROM superstore
GROUP BY YEAR(Order_Date)
ORDER BY order_year ASC;


-- YoY Change in Total Sales
WITH records AS (
    SELECT
        YEAR(Order_Date) AS order_year,
        COUNT(DISTINCT Order_ID) AS total_orders,
        SUM(Sales) AS total_sales
    FROM superstore
    GROUP BY YEAR(Order_Date)
),
lagged AS (
    SELECT *,
        LAG(total_orders) OVER (ORDER BY order_year) AS prev_orders,
        LAG(total_sales) OVER (ORDER BY order_year) AS prev_sales
    FROM records
)
SELECT
    order_year,
    total_orders,
    total_sales,
    COALESCE(total_orders - prev_orders, 0) AS yoy_order_change,
    COALESCE(total_sales - prev_sales, 0) AS yoy_sales_change,
    CONCAT(
        ROUND(COALESCE((total_orders - prev_orders) * 1.0 / NULLIF(prev_orders, 0), 0) * 100, 2),
        '%'
    ) AS yoy_order_pct,
    CONCAT(
        ROUND(COALESCE((total_sales - prev_sales) * 1.0 / NULLIF(prev_sales, 0), 0) * 100, 2),
        '%'
    ) AS yoy_sales_pct
FROM lagged;





-- YoY Change (Region-wise)
WITH records AS (
    SELECT
        YEAR(Order_Date) AS order_year,
        Region,
        COUNT(DISTINCT Order_ID) AS total_orders,
        SUM(Sales) AS total_sales
    FROM superstore
    GROUP BY YEAR(Order_Date), Region
),
lagged AS (
    SELECT *,
        LAG(total_orders) OVER (PARTITION BY Region ORDER BY order_year) AS prev_orders,
        LAG(total_sales) OVER (PARTITION BY Region ORDER BY order_year) AS prev_sales
    FROM records
)
SELECT
    order_year,
    Region,
    total_orders,
    total_sales,
    COALESCE(total_orders - prev_orders, 0) AS yoy_order_change,
    COALESCE(total_sales - prev_sales, 0) AS yoy_sales_change,
    CONCAT(
        ROUND(COALESCE((total_orders - prev_orders) * 1.0 / NULLIF(prev_orders, 0), 0) * 100, 2),
        '%'
    ) AS yoy_order_pct,
    CONCAT(
        ROUND(COALESCE((total_sales - prev_sales) * 1.0 / NULLIF(prev_sales, 0), 0) * 100, 2),
        '%'
    ) AS yoy_sales_pct
FROM lagged;



-- Customer Segment

WITH customer_sales AS (
    SELECT
        Customer_ID,
        SUM(Sales) AS total_spent
    FROM superstore
    GROUP BY Customer_ID
)
SELECT
    Customer_ID,
    total_spent,
    NTILE(3) OVER (ORDER BY total_spent DESC) AS customer_segment
FROM customer_sales;


-- Top 10 Customers (Based on Total Sales)
WITH summary AS (
    SELECT
        Customer_ID,
        Customer_Name,
        COUNT(DISTINCT Order_ID) AS total_orders,
        SUM(Sales) AS total_sales
    FROM superstore
    GROUP BY Customer_ID, Customer_Name
),
final AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
    FROM summary
)
SELECT *
FROM final
WHERE rn <= 10;


-- Repeat Customers
SELECT
    Customer_ID,
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS num_orders
FROM superstore
GROUP BY Customer_ID, Customer_Name
HAVING COUNT(DISTINCT Order_ID) > 1
ORDER BY num_orders DESC;





-- Top Products (Based on total sales)
SELECT TOP 10
    Product_Name,
    SUM(Sales) AS total_sales
FROM superstore
GROUP BY Product_Name
ORDER BY total_sales DESC;


-- Top Products (Based on total orders)
select top 10
Product_Name,
COUNT(*) total_orders
from superstore
group by Product_Name
order by COUNT(*) desc


-- Lowest Performing Products (Based on total sales)
SELECT TOP 10
    Product_Name,
    SUM(Sales) AS total_sales
FROM superstore
GROUP BY Product_Name
ORDER BY total_sales ASC;

