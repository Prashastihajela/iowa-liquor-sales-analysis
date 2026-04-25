-- Top 5 Category Trend (2021-2025)

With top5_category AS (
SELECT category_name, EXTRACT(YEAR FROM date) AS year,
ROUND(SUM(sale_dollars),2) AS category_revenue,
SUM(bottles_sold) As Bottles_sold,
SUM((state_bottle_retail - state_bottle_cost)*bottles_sold)/NULLIF(SUM(bottles_sold),0) AS avg_profit_per_bottle
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE EXTRACT(YEAR FROM date) BETWEEN 2021 AND 2025
AND category_name IS NOT NULL
AND store_name IS NOT NULL
GROUP BY category_name, year
),
ranked AS (
SELECT 
category_name,
ROUND(SUM(Category_revenue),2) AS total_revenue,
SUM(Bottles_sold) As total_Bottles_sold,
RANK() OVER (ORDER BY SUM(Category_revenue) DESC) AS rnk
FROM top5_category
GROUP BY category_name
),
YoY_growth AS (
SELECT
t.year,
t.category_name,
t.category_revenue,
t.Bottles_sold,
t.avg_profit_per_bottle,
LAG(t.category_revenue) OVER (
PARTITION BY t.category_name
ORDER BY t.year
) AS prev_year_revenue,
ROUND(
(t.category_revenue - LAG(t.category_revenue) OVER (
PARTITION BY t.category_name ORDER BY t.year
))
/ NULLIF(LAG(t.category_revenue) OVER (
PARTITION BY t.category_name ORDER BY t.year
), 0) * 100, 2
) AS yoy_growth_pct
FROM top5_category t
WHERE t.category_name IN (SELECT category_name FROM ranked WHERE rnk <= 5 )
)
SELECT
year,
category_name,
category_revenue,
bottles_sold,
avg_profit_per_bottle,
prev_year_revenue,
yoy_growth_pct
FROM yoy_growth
ORDER BY category_name, year;
