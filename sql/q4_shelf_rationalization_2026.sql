WITH item_year AS (
  SELECT
    item_number,
    item_description,
    bottle_volume_ml,
    EXTRACT(YEAR FROM date) AS yr,
    SUM(sale_dollars) AS revenue,
    SUM((state_bottle_retail - state_bottle_cost) * bottles_sold) AS profit,
    SUM(bottles_sold) AS bottles,
    COUNT(DISTINCT store_number) AS stores
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM date) IN (2024, 2025)
    AND item_number IS NOT NULL
    AND bottle_volume_ml IS NOT NULL
  GROUP BY item_number, item_description, bottle_volume_ml, yr
),
perf AS (
  SELECT
    a.item_number,
    a.item_description,
    a.bottle_volume_ml,
    a.revenue AS rev_2024,
    b.revenue AS rev_2025,
    SAFE_DIVIDE(b.revenue - a.revenue, a.revenue) AS yoy_growth,
    SAFE_DIVIDE(b.profit, b.revenue) AS margin_2025,
    SAFE_DIVIDE(b.bottles, b.stores) AS bottles_per_store_2025,
    b.stores AS store_coverage_2025
  FROM item_year a
  JOIN item_year b
    ON a.item_number = b.item_number
   AND a.bottle_volume_ml = b.bottle_volume_ml
  WHERE a.yr = 2024
    AND b.yr = 2025
),
filtered AS (
  SELECT *
  FROM perf
  WHERE rev_2025 > 0
    AND store_coverage_2025 >= 5
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      ORDER BY yoy_growth ASC, margin_2025 ASC, bottles_per_store_2025 ASC, rev_2025 ASC
    ) AS weakness_rank
  FROM filtered
)
SELECT
  item_number,
  item_description,
  bottle_volume_ml,
  ROUND(rev_2024, 2) AS rev_2024,
  ROUND(rev_2025, 2) AS rev_2025,
  ROUND(yoy_growth * 100, 2) AS yoy_growth_pct,
  ROUND(margin_2025 * 100, 2) AS margin_pct_2025,
  ROUND(bottles_per_store_2025, 2) AS bottles_per_store_2025,
  store_coverage_2025
FROM ranked
WHERE weakness_rank <= 3
ORDER BY weakness_rank;
