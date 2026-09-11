-- GOOGLE MERCHANDISE STORE E-COMMERCE ANALYSIS
-- =====================================================


-- 0. DATA VALIDATION
-- =====================================================

-- 0.1 Check available date range
SELECT
  MIN(_TABLE_SUFFIX) AS first_date,
  MAX(_TABLE_SUFFIX) AS last_date
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX LIKE '2017%';

-- 0.2 Check number of days by month
SELECT
  FORMAT_DATE('%Y-%m',PARSE_DATE('%Y%m%d',_TABLE_SUFFIX)) AS month,
  COUNT (DISTINCT _TABLE_SUFFIX) AS number_of_days
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170731'
GROUP BY month
ORDER BY month;
         
-- 0.3 Check NULL / missing values
SELECT
  COUNT(*) AS total_rows,

  COUNTIF(fullVisitorId IS NULL) AS null_fullVisitorId,
  COUNTIF(visitId IS NULL) AS null_visitId,
  COUNTIF(date IS NULL) AS null_date,
  COUNTIF(trafficSource.source IS NULL) AS null_source,
  COUNTIF(trafficSource.medium IS NULL) AS null_medium,

  COUNTIF(totals.visits IS NULL) AS null_visits,
  COUNTIF(totals.pageviews IS NULL) AS null_pageviews,
  COUNTIF(totals.bounces IS NULL) AS null_bounces,
  COUNTIF(totals.transactions IS NULL) AS null_transactions,
  COUNTIF(totals.transactionRevenue IS NULL) AS null_revenue

FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170731';

--check NULL pageviews
SELECT
  fullVisitorId,
  visitId,
  totals.visits,
  totals.pageviews,
  totals.bounces,
  totals.transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170731'
  AND totals.pageviews IS NULL;
-->drop

-- 0.4 Check data types
SELECT
  field_path,
  data_type
FROM `bigquery-public-data.google_analytics_sample.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS`
WHERE table_name = 'ga_sessions_20170101'
  AND field_path IN (
    'date',
    'trafficSource.source',
    'trafficSource.medium',
    'totals.visits',
    'totals.pageviews',
    'totals.bounces',
    'totals.transactions',
    'totals.transactionRevenue'
  )
ORDER BY field_path;


-- 0.5 Check invalid / abnormal values
SELECT
  MIN(totals.pageviews) AS min_pageviews,
  MAX(totals.pageviews) AS max_pageviews,

  MIN(totals.transactions) AS min_transactions,
  MAX(totals.transactions) AS max_transactions,

  MIN(totals.transactionRevenue) AS min_revenue,
  MAX(totals.transactionRevenue) AS max_revenue

FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170731';


-- 0.6 Check duplicates
SELECT
  fullVisitorId,
  visitId,
  date,
  COUNT(*) AS row_count
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170731'
GROUP BY fullVisitorId, visitId,date
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;

-- =========================================
-- 1. DATA CLEANING

--create table 1: sessions
CREATE OR REPLACE TABLE `fluid-axe-481410-j7.analytics.cleaned_ga_sessions` AS

SELECT
  PARSE_DATE('%Y%m%d', date) AS session_date,

  COALESCE(trafficSource.source, 'unknown') AS source,
  COALESCE(trafficSource.medium, 'unknown') AS medium,

  fullVisitorId AS visitor_id,

  totals.visits AS visits,
  totals.pageviews AS pageviews,
  totals.bounces AS bounces,
  totals.transactions AS transactions,

  COALESCE(totals.transactionRevenue, 0) / 1000000 AS revenue,

  COALESCE(device.deviceCategory, 'unknown') AS device_category,
  COALESCE(device.operatingSystem, 'unknown') AS operating_system

FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`

WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170731'
  AND totals.pageviews IS NOT NULL;

--create table 2: product
CREATE OR REPLACE TABLE `fluid-axe-481410-j7.analytics.cleaned_products` AS

SELECT
  PARSE_DATE('%Y%m%d', date) AS session_date,
  fullVisitorId AS visitor_id,
  visitId AS visit_id,

  COALESCE(trafficSource.source, 'unknown') AS source,
  COALESCE(trafficSource.medium, 'unknown') AS medium,

  COALESCE(device.deviceCategory, 'unknown') AS device_category,

  product.productSKU AS product_sku,
  product.v2ProductName AS product_name,
  product.v2ProductCategory AS product_category,

  product.productPrice / 1000000 AS product_price,
  product.productQuantity AS product_quantity,
  product.productRevenue / 1000000 AS product_revenue

FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
UNNEST(hits) AS hit,
UNNEST(hit.product) AS product

WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170731'
  AND hit.eCommerceAction.action_type = '6'
  AND product.v2ProductName IS NOT NULL;
  

-- =========================================
-- 2. ANALYSIS

-- Q1. Overall performance
SELECT
  FORMAT_DATE('%Y-%m', session_date) AS month,
  SUM(visits) AS visits,
  SUM(transactions) AS transactions,
  round(SUM(revenue),0) AS revenue,
  round(SAFE_DIVIDE(SUM(transactions), SUM(visits))*100,2) AS conversion_rate

FROM `fluid-axe-481410-j7.analytics.cleaned_ga_sessions`

GROUP BY month
ORDER BY month;


-- Q2. Traffic source performance
SELECT
  source,
  SUM(visits) AS visits,
  SUM(transactions) AS transactions,
  round(SUM(revenue),0) AS revenue,
  round(SAFE_DIVIDE(SUM(transactions), SUM(visits))*100,2) AS conversion_rate

FROM `fluid-axe-481410-j7.analytics.cleaned_ga_sessions`

GROUP BY source
HAVING visits >= 5000
ORDER BY revenue DESC;

-- Q4. Source performance over time
SELECT
  FORMAT_DATE('%Y-%m', session_date) AS month,
  source,
  SUM(visits) AS visits,
  SUM(transactions) AS transactions,
  SUM(revenue) AS revenue,
  ROUND(
    SAFE_DIVIDE(SUM(transactions), SUM(visits)) * 100,
    2
  ) AS conversion_rate

FROM `fluid-axe-481410-j7.analytics.cleaned_ga_sessions`

WHERE source IN (
  '(direct)'
, 'google'
, 'youtube.com'
, 'Partners'
)
GROUP BY month, source
ORDER BY source, month;

--Q5  Top 10 highest revenue products
SELECT
  product_name,
  SUM(product_quantity) AS quantity_sold,
  ROUND(
    SAFE_DIVIDE(
      SUM(product_revenue),
      SUM(product_quantity)
    ),
    2
  ) AS avg_revenue_per_unit,
  round(SUM(product_revenue),0) AS revenue
FROM `fluid-axe-481410-j7.analytics.cleaned_products`
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;


-- Q6. Revenue share by traffic source for top 10 products
----Identify the top 10 products by total revenue
WITH top_products AS (
  SELECT
    product_name,
    SUM(product_revenue) AS total_revenue
  FROM `fluid-axe-481410-j7.analytics.cleaned_products`
  GROUP BY product_name
  ORDER BY total_revenue DESC
  LIMIT 10
),
---- Calculate revenue by product and traffic source
product_source AS (
  SELECT
    p.product_name,
    CASE WHEN p.source IN ('(direct)', 'google', 'dfa')
         THEN p.source ELSE 'other' END AS source,
    SUM(p.product_revenue) AS revenue
  FROM `fluid-axe-481410-j7.analytics.cleaned_products` AS p
  JOIN top_products AS t
    ON p.product_name = t.product_name
  GROUP BY p.product_name, source
),
----Calculate each source's share of the product's total revenue
product_share AS (
  SELECT
    product_name,
    source,
    SAFE_DIVIDE(
      revenue,
      SUM(revenue) OVER (PARTITION BY product_name)
    ) * 100 AS revenue_share
  FROM product_source
)
---- Pivot traffic sources into separate columns
SELECT
  product_name,
  ROUND(MAX(CASE WHEN source = '(direct)' THEN revenue_share ELSE 0 END), 2) AS direct_share,
  ROUND(MAX(CASE WHEN source = 'google' THEN revenue_share ELSE 0 END), 2) AS google_share,
  ROUND(MAX(CASE WHEN source = 'dfa' THEN revenue_share ELSE 0 END), 2) AS dfa_share,
  ROUND(MAX(CASE WHEN source = 'other' THEN revenue_share ELSE 0 END), 2) AS other_share

FROM product_share

GROUP BY product_name
ORDER BY product_name;


--Q7. Device performance
SELECT
  device_category,
  SUM(visits) AS visits,
  SUM(transactions) AS transactions,
  SUM(revenue) AS revenue,
  ROUND(
    SAFE_DIVIDE(SUM(transactions), SUM(visits)) * 100,
    2
  ) AS conversion_rate,
  ROUND(
    SAFE_DIVIDE(SUM(revenue), SUM(visits)),
    2
  ) AS revenue_per_visit

FROM `fluid-axe-481410-j7.analytics.cleaned_ga_sessions`

GROUP BY device_category
ORDER BY revenue DESC;

