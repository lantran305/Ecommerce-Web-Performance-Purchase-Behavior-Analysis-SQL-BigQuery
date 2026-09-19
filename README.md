# Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery
**Author:** Tran Thi Lan

**Date:** 16/10/2002

**Tools Used:** SQL


## 1. Project Overview
### 📖 What is this project about?
This project uses **SQL** and **BigQuery** to analyze e-commerce data from the Google Merchandise Store to understand the key drivers of revenue and conversion performance. Using Google Analytics data from January to July 2017, the analysis examines overall performance, traffic sources, product performance, and device usage to identify revenue opportunities and areas for improvement.

### Business Questions
Understand where revenue comes from, which factors influence e-commerce performance, and where the business should focus improvement efforts.
1. How did traffic, transactions, conversion rate, and revenue change over time?
2. Which traffic sources generated the most revenue and had the highest conversion rates?
3. How did traffic source performance change over time?
4. Which products generated the most revenue?
5. Which traffic sources contributed the most revenue to the top products?
6. How did e-commerce performance differ across devices?

## 👥 Target Audience

- ✔️ **Data Analysts & Business Analysts**
- ✔️ **Digital Marketing Teams**
- ✔️ **E-commerce Managers & Stakeholders**
- ✔️ **Business Intelligence Teams**

## 📂 Dataset Description & Data Structure

**📌 Data Source:**  
This project uses the **Google Analytics Sample Dataset**, containing session and e-commerce activity data from the **Google Merchandise Store**.

**📌 Analysis Period:**  
**January 2017 – July 2017**

**📌 Original Dataset:**  
`bigquery-public-data.google_analytics_sample.ga_sessions_*`

The dataset consists of daily sharded `ga_sessions_YYYYMMDD` tables containing session-level information such as traffic sources, devices, pageviews, transactions, revenue, and product data.

### Data Structure

For this analysis, the raw data was transformed into two analytical tables:

| Table | Granularity | Purpose |
|---|---|---|
| `cleaned_ga_sessions` | 1 row = 1 session | Traffic, conversion, revenue, and device analysis |
| `cleaned_products` | 1 row = 1 purchased product occurrence | Product revenue and traffic-source analysis |

### Key Fields

**`cleaned_ga_sessions`**  
`session_date`, `source`, `medium`, `visitor_id`, `visits`, `pageviews`, `transactions`, `revenue`, `device_category`, `operating_system`

**`cleaned_products`**  
`session_date`, `visitor_id`, `visit_id`, `source`, `medium`, `device_category`, `product_sku`, `product_name`, `product_category`, `product_price`, `product_quantity`, `product_revenue`


## 🔍 5. Analysis & Queries
### 0. DATA VALIDATION
- Check available date range
- Check number of days by month
- Check NULL / missing values
- Check data types
- Check invalid / abnormal values
- Check duplicates
- Create table

🚀 **Query sample**

```sql
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
  
```

### Q1. Overall E-commerce Performance

🔎 The goal of this analysis is to identify which traffic sources generate the most revenue and evaluate whether high-traffic sources also perform well in terms of conversion.

🚀 **Query**

```sql
SELECT 
  FORMAT_DATE('%Y-%m', session_date) AS month, 
  SUM(visits) AS visits, 
  SUM(transactions) AS transactions, 
  ROUND(SUM(revenue), 0) AS revenue, 
  ROUND(SAFE_DIVIDE(SUM(transactions), SUM(visits)) * 100, 2) AS conversion_rate

FROM `fluid-axe-481410-j7.analytics.cleaned_ga_sessions`

GROUP BY month
ORDER BY month;
```
**💡 Queries result**

<img width="715" height="234" alt="image" src="https://github.com/user-attachments/assets/f281ad6a-81d9-4370-ac95-2522a9c4e267" />

* **Traffic volume did not directly translate into revenue**. April generated the highest revenue ($158.8K) with 67.1K visits, while July had more visits (71.8K) but lower revenue ($124.5K).
* --> Revenue performance depends on more than traffic volume.

* **Conversion rate improved over the period**, from 1.10% in January to 1.49% in July, peaking at 1.77% in May.
* --> Conversion efficiency improved despite revenue fluctuations.
### Q2. Traffic Source Performance

🔎The goal of this analysis is to identify which traffic sources generate the most revenue and evaluate whether high-traffic sources also perform well in terms of conversion.

🚀 **Query**

```sql
SELECT 
  source, 
  SUM(visits) AS visits, 
  SUM(transactions) AS transactions, 
  ROUND(SUM(revenue), 0) AS revenue, 
  ROUND(SAFE_DIVIDE(SUM(transactions), SUM(visits)) * 100, 2) AS conversion_rate

FROM `fluid-axe-481410-j7.analytics.cleaned_ga_sessions`

GROUP BY source
HAVING visits >= 5000
ORDER BY revenue DESC;
```
**💡 Queries result**

<img width="777" height="183" alt="image" src="https://github.com/user-attachments/assets/4dd5fd0f-8efe-443c-a454-4270d100ac78" />

* **Direct was the largest revenue-generating source**, with $622K revenue, 187K visits, and a 2.48% conversion rate.
* **Google generated similar traffic to Direct but much lower conversion**: 180K visits, $152K revenue, and 0.92% conversion.
* YouTube generated 50K visits but only 9 transactions, with a 0.02% conversion rate.
  -->Traffic volume alone does not indicate traffic quality.
  
### Q3. Source performance over time
🔎 The goal of this analysis is to determine whether the performance patterns of major traffic sources are consistent over time.

🚀 **Query**

```sql
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
```
**💡 Queries result**


<img width="720" height="409" alt="image" src="https://github.com/user-attachments/assets/c4d035ae-a357-4128-805b-499bc6f7422c" />
<img width="716" height="407" alt="image" src="https://github.com/user-attachments/assets/ecbe3598-c971-4012-a273-f251beb546f4" />

* **Direct consistently maintained relatively strong conversion**, ranging from 1.38% to 3.75% across the period.
*  **Google consistently had high traffic but lower conversion**, around 0.78%–1.00%.

### Q4. Top 10 highest revenue products
🔎 The goal of this analysis is to understand which products contribute the most to e-commerce revenue and whether revenue is driven by sales volume or product value.

🚀 **Query**

```sql
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
```
**💡 Queries result**

<img width="664" height="307" alt="image" src="https://github.com/user-attachments/assets/fda3b158-2a43-4c2b-8407-7bc6014f522a" />

* **Product revenue was not driven by sales volume alone**. **The Men's Zip Hoodie** generated $26.4K from only 501 units, while the 22 oz Water Bottle sold 8,187 units but generated $23.2K. --> High-volume and high-value products require different merchandising strategies.

### Q5. Revenue share by traffic source for top 10 products
🔎 The goal of this analysis is to identify which traffic sources contribute most to the revenue of high-performing products.

🚀 **Query**

```sql
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
```
**💡 Queries result**

<img width="773" height="309" alt="image" src="https://github.com/user-attachments/assets/0ff706b0-fc0d-4d63-857b-b1216b15514d" />

* Direct accounted for the majority of revenue for 9 of the top 10 products.
* DFA contributed a substantial share of revenue for several products: 43.65% for Men's Zip Hoodie, 33.21% for Hard Cover Journal, and 24.71% for Leatherette Journal.

### Q6. Device performance

🔎 The goal of this analysis is to identify differences in traffic, conversion, revenue, and revenue per visit across devices.

🚀 **Query**

```sql
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
```
**💡 Queries result**

<img width="716" height="127" alt="image" src="https://github.com/user-attachments/assets/3943b989-c735-4204-9759-921c8f7f7b6b" />

* Desktop generated over 95% of revenue, with $832.5K revenue and a 1.92% conversion rate.
* Mobile generated 133K visits but only $27.8K revenue, with a 0.38% conversion rate versus 1.92% on desktop.




## 5.Key Insights

**1. April generated the highest revenue despite lower traffic than July.**
April generated $158.8K from 67,119 visits, compared with $124.5K from 71,796 visits in July.

**2. Direct was the largest revenue-generating traffic source, while Google generated similar traffic with much lower conversion.**
Direct generated $622K revenue from 187K visits (2.48% conversion), compared with $152K from Google’s 180K visits (0.92% conversion).

**3. DFA generated a large share of revenue for several top products (Google Men's Zip Hoodie, Google Hard Cover Journal, and Leatherette Journal).**
DFA contributed 43.65%, 33.21%, and 24.71% of their respective revenue.

**4. Desktop generated over 95% of revenue, while mobile had a much lower conversion rate.**
Desktop generated $832.5K revenue (1.92% conversion) versus $27.8K on mobile (0.38% conversion), despite mobile accounting for 133K visits.

## 6. Recommendations

**1. Prioritize high-converting traffic sources over traffic volume.**
Focus on improving the quality and conversion of Google traffic, while maintaining the strong performance of Direct traffic.

**2. Investigate and scale DFA campaigns for high-value products.**
Analyze the campaigns/referrals behind DFA traffic for Google Men's Zip Hoodie, Google Hard Cover Journal, and Leatherette Journal, and scale the most effective ones based on revenue and ROI.

**3. Prioritize high-revenue products in marketing and merchandising.**
Give greater visibility and promotional focus to products such as Leatherette Journal, Google Men's Zip Hoodie, and Google Hard Cover Journal, which generate high revenue despite different sales volumes.

**4. Investigate the mobile conversion funnel.**
Review the product page → cart → checkout journey on mobile to identify where the large performance gap versus desktop occurs.
