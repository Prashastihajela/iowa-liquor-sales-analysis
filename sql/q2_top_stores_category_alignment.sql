-- Top 5 Stores (In 2025)

With Top5_category_2025 AS (
SELECT 
category_name,
ROUND(SUM(sale_dollars),2) As category_sale,
SUM(bottles_sold) AS total_bottles_sold
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE EXTRACT(YEAR FROM date) = 2025
GROUP BY category_name
ORDER BY category_sale DESC
LIMIT 5
),
Top5_store AS (
SELECT
store_number,
ANY_VALUE(store_name) AS store_name, 
ROUND(SUM(sale_dollars),2) As store_total_sale,
SUM(bottles_sold) AS total_bottles_sold,
RANK() OVER (ORDER BY SUM(sale_dollars) DESC) AS store_rank
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE EXTRACT(YEAR FROM date) = 2025
GROUP BY store_number
),
store_cat_brakdown AS (
SELECT 
s.store_number,
s.category_name,
ROUND(SUM(s.sale_dollars),2) As Store_cat_sale,
SUM(s.bottles_sold) AS total_bottles_sold,
t.store_rank,
RANK() OVER (PARTITION BY (s.store_number) ORDER BY (SUM(s.sale_dollars))DESC) AS Store_best_cat_rank
FROM `bigquery-public-data.iowa_liquor_sales.sales`s
INNER JOIN Top5_store t ON s.store_number = t.store_number
WHERE EXTRACT(YEAR FROM date) = 2025 AND 
t.store_rank<=5 
GROUP BY s.store_number,
s.category_name,
t.store_rank
)
SELECT *,
CASE
WHEN category_name IN (SELECT category_name FROM Top5_category_2025 )
THEN "Top 5"
ELSE "Other"
END AS is_cat_top5
FROM store_cat_brakdown
WHERE Store_best_cat_rank <=5
ORDER BY store_rank, Store_best_cat_rank 
;
