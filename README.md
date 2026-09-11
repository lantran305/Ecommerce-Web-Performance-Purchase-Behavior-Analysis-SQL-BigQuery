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
3. Which high-traffic sources had relatively low conversion performance?
4. How did traffic source performance change over time?
5. Which products generated the most revenue?
6. Which traffic sources contributed the most revenue to the top products?
7. How did e-commerce performance differ across devices?

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

# 🔍 5. Analysis & Queries

## Q1. Overall E-commerce Performance

🔎 **Calculate monthly visits, transactions, revenue, and conversion rate from January to July 2017.**

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

## Q2. Traffic Source Performance

**🔎 Identify high-traffic sources and compare their transactions, revenue, and conversion rates.**

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

## Q3. Source performance over time
**🔎 Identify ....**

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
## Q4. Top 10 highest revenue products
**🔎 Identify ....**

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

## Q6. Revenue share by traffic source for top 10 products
**🔎 Identify ....**

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

## Q7. Device performance
**🔎 Identify ....**

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
