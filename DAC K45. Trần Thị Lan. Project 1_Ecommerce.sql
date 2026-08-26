-- Query 01: calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)
SELECT
  SUBSTR(date, 1, 6) AS month,
  sum(totals.visits) AS visits,
  sum(totals.pageviews) AS pageviews,
  sum(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;

-- Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
SELECT
  trafficsource.source,
  sum(totals.bounces) AS total_no_of_bounces,
  COUNT(*) AS total_visits,
  round(sum(totals.bounces) * 100.0 / COUNT(*), 2) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY 1
ORDER BY 3 DESC;

-- Query 03: Revenue by traffic source by week, by month in June 2017
WITH
  week AS (
    SELECT
      'week' AS time_type,
      EXTRACT(week FROM (parse_date('%Y%m%d', date))) AS time,
      trafficSource.`source` AS source,
      sum(totals.transactionRevenue) / 1000000 AS revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
    GROUP BY 2, 3
    HAVING revenue IS NOT NULL
  ),
  month AS (
    SELECT
      'month' AS time_type,
      EXTRACT(month FROM (parse_date('%Y%m%d', date))) AS time,
      trafficSource.`source` AS source,
      sum(totals.transactionRevenue) / 1000000 AS revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
    GROUP BY 2, 3
    HAVING revenue IS NOT NULL
  )
SELECT time_type, time, source, revenue
FROM month
UNION ALL
SELECT time_type, time, source, revenue
FROM week
ORDER BY 3, 1, 2;

-- Query 04: Conversion rate by traffic source in 2017. (order by conversion_rate desc)
SELECT
  trafficSource.`source`,
  sum(totals.visits) AS visits,
  sum(totals.transactions) AS transactions,
  round(sum(totals.transactions) * 100 / sum(totals.visits), 0)
    AS conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
GROUP BY 1
HAVING transactions >= 50
ORDER BY conversion_rate DESC;

--Query 05: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.
  WITH user_month AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    fullVisitorId,
    SUM(totals.pageviews) AS total_pageviews,
    SUM(IFNULL(totals.transactions,0)) AS total_transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
  GROUP BY 1,2
)
SELECT
  month,
  round(AVG(CASE WHEN total_transactions >= 1 
           THEN total_pageviews END),1) AS avg_pageviews_purchase,
  round(AVG(CASE WHEN total_transactions = 0 
           THEN total_pageviews END),1) AS avg_pageviews_non_purchase
FROM user_month
GROUP BY 1
ORDER BY 1
;

-- Query 06: Average number of transactions per user that made a purchase in July 2017
WITH
  tpu AS (
    SELECT
      fullVisitorId,
      SUBSTR(DATE, 1, 6) AS month,
      sum(totals.transactions) AS total_transactions
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    WHERE totals.transactionRevenue IS NOT NULL
    GROUP BY 1, 2
    -- HAVING sum(totals.transactions)>=1
    ORDER BY 3
  )
SELECT
  tpu.month, avg(total_transactions) AS Avg_total_transactions_per_user
FROM tpu
GROUP BY 1;

-- Query 07: Revenue contribution by device (desktop,mobile...) (order by ratio desc)
WITH
  raw_data AS (
    SELECT
      device.deviceCategory,
      (SUM(productRevenue) / 1000000) AS revenue_by_device,
      sum(SUM(productRevenue) / 1000000) OVER () AS total_revenue
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_201*`,
      UNNEST(hits) AS h,
      UNNEST(h.product)
    WHERE productRevenue IS NOT NULL
    GROUP BY 1
  )
SELECT
  deviceCategory,
  revenue_by_device,
  total_revenue,
  round(revenue_by_device * 100 / total_revenue, 2) AS ratio
FROM raw_data
ORDER BY ratio DESC;

-- Query 08: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
SELECT
  p.v2ProductName AS other_purchased_products, SUM(productQuantity) AS quantity
FROM
  `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST(hits) AS h,
  UNNEST(h.product) AS p
WHERE
  fullVisitorId IN (
    SELECT
      fullVisitorId
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
      UNNEST(hits) AS h,
      UNNEST(h.product) AS p
    WHERE
      p.v2ProductName LIKE "YouTube Men's Vintage Henley"
      AND p.ProductRevenue IS NOT NULL
  )
GROUP BY 1
ORDER BY 2 DESC;

-- Query 9: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017.
WITH
  raw_data AS (
    SELECT
      FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
      SUM(CASE WHEN h.eCommerceAction.action_type = '2' THEN 1 END)
        AS num_product_view,
      SUM(CASE WHEN h.eCommerceAction.action_type = '3' THEN 1 END)
        AS num_addtocart,
      SUM(
        CASE
          WHEN
            h.eCommerceAction.action_type = '6'
            AND p.productRevenue IS NOT NULL
            THEN 1
          END) AS num_purchase
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
      UNNEST(hits) AS h,
      UNNEST(h.product) AS p
    WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
    GROUP BY 1
    ORDER BY 1
  )
SELECT
  raw_data.month,
  raw_data.num_product_view,
  raw_data.num_addtocart,
  raw_data.num_purchase,
  round(raw_data.num_addtocart * 100 / raw_data.num_product_view, 2)
    AS add_to_cart_rate,
  round(raw_data.num_purchase * 100 / raw_data.num_product_view, 2)
    AS purchase_rate
FROM raw_data;

-- Query 10: Calculate revenue by week from May to July 2017 and culmulative revenue.

WITH
  rv AS (
    SELECT
      FORMAT_DATE("%Y-%U", PARSE_DATE("%Y%m%d", date)) AS week,
      ROUND(SUM(p.productRevenue) / 1000000, 2) AS weekly_revenue
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
      UNNEST(hits) AS h,
      UNNEST(h.product) AS p
    WHERE
      _TABLE_SUFFIX BETWEEN '0501' AND '0731'
      AND p.productRevenue IS NOT NULL
    GROUP BY 1
    ORDER BY 1
  )
SELECT
  rv.week,
  rv.weekly_revenue,
  sum(rv.weekly_revenue)
    OVER (
      ORDER BY week
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM rv
ORDER BY 1;
