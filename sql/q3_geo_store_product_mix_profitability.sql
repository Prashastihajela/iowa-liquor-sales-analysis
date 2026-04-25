WITH map_store_details  AS(
SELECT
  store_number,
  store_name,
  ST_X(store_location) AS longitude,
  ST_Y(store_location) AS latitude,
  category_name,
  item_number,
  item_description,
  bottle_volume_ml,
  state_bottle_cost,
  state_bottle_retail,
  bottles_sold,
  sale_dollars
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE EXTRACT(YEAR FROM date) = 2025 
  AND  store_location IS NOT NULL
  AND bottle_volume_ml != 50
),
top_store AS (
SELECT
  m.store_number,
  ANY_VALUE(store_name) AS store_name,
  ANY_VALUE(m.latitude) AS latitude,
  ANY_VALUE(m.longitude) AS longitude,
  SUM(sale_dollars) As store_sale,
  RANK() OVER (ORDER BY (SUM(sale_dollars)) DESC) AS store_rank
FROM map_store_details m
GROUP BY m.store_number
),
store_cat_details AS (
SELECT
  m.store_number,
  ANY_VALUE(store_name) AS store_name,
  ANY_VALUE(m.latitude) AS latitude,
  ANY_VALUE(m.longitude) AS longitude,
  m.category_name,
  ROUND(SUM(sale_dollars),2) As store_cat_sale,
  SUM(m.bottles_sold) AS total_bottles_sold,  
  RANK() OVER (PARTITION BY m.store_number ORDER BY ROUND(SUM(sale_dollars),2) DESC) As store_cat_rank,
  SUM((state_bottle_retail - state_bottle_cost) * bottles_sold) / SUM(bottles_sold) AS profit_per_bottle
FROM map_store_details m  
WHERE m.store_number IN (SELECT store_number FROM top_store WHERE store_rank <=5 )
GROUP BY m.store_number, m.category_name
),
Store_cat_size_details AS (
SELECT 
  s.store_number,
  s.category_name,
  (m.item_number) AS item_num,
  (m.item_description) AS brand_item,
  m.bottle_volume_ml,
  SUM(m.bottles_sold) AS bottles_sold_per_size,
  SAFE_DIVIDE(
  SUM((m.state_bottle_retail - m.state_bottle_cost) * m.bottles_sold),
  SUM(m.bottles_sold)) AS profit_per_bottle_size,
  SUM(m.sale_dollars) AS sale_in_size
FROM store_cat_details s
JOIN map_store_details m
 ON m.store_number = s.store_number
 AND m.category_name = s.category_name
WHERE s.store_cat_rank <=5
GROUP BY s.store_number,m.bottle_volume_ml,
  s.category_name, item_num, brand_item
)
SELECT
  t.store_rank,
  t.store_number,
  t.store_name,
  t.latitude,
  t.longitude,
  t.store_sale,
  s.store_cat_rank,
  s.category_name,
  s.store_cat_sale,
  s.total_bottles_sold,
  d.bottle_volume_ml,
  d.bottles_sold_per_size,
  d.item_num,
  d.brand_item,
  ROUND(d.profit_per_bottle_size , 2) AS profit_per_bottle,
  ROUND(d.sale_in_size) AS sale_in_size,
  ROUND(s.profit_per_bottle, 2) AS category_profit_per_bottle,
FROM top_store t
JOIN store_cat_details s
  ON t.store_number = s.store_number
LEFT JOIN Store_cat_size_details d
  ON d.store_number = s.store_number
 AND d.category_name = s.category_name
WHERE t.store_rank <= 5
  AND s.store_cat_rank <= 5
ORDER BY t.store_rank, s.store_cat_rank;
