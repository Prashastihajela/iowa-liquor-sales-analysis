# Table of Contents

Overview
Available Data
Business Case Study Questions and Answers

Overview

This project analyzes 33.8 million Iowa liquor wholesale transactions (2021–2025) from the Iowa Alcoholic Beverages Division, publicly available in Google BigQuery to identify which category trend, top revenue stores, and to recommend data-backed shelf-space decisions for 2026. Using BigQuery SQL and Looker Studio, the analysis combines trend tracking, store-level ranking, geospatial mapping, and product-level profitability diagnostics.
Four business questions were solved: 
Top 5 category trend and YoY movement
Whether top 2025 stores are driven by statewide top categories or local outliers
Where top stores are geographically and which category-size-brand mix is most profitable
Which low-performing SKUs are candidates for removal to free shelf space

Available Data

Dataset: iowa_liquor_sales Data

Data source: BigQuery Public Data
Data Coverage: 2021–2025 for trend and performance questions (with 2024–2025 comparison for shelf optimization)
Key Columns: date, store_name, store_location (geospatial), category_name, item_description, bottle_volume_ml, state_bottle_cost, state_bottle_retail, bottles_sold, sale_dollars

Business Case Study Questions and Answers

