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

### Data Preparation

The raw GA data was cleaned and transformed by:

- Converting date fields into standard `DATE` format
- Handling missing traffic-source and device values
- Excluding sessions with missing pageviews
- Converting revenue from micro-units to USD
- Extracting purchased products from nested e-commerce data
- Creating session-level and product-level analytical tables
## 5. Query
1.Check available date range
<img width="520" height="79" alt="image" src="https://github.com/user-attachments/assets/4f2e2b63-a091-477c-bffa-a660a6bd0e98" />

0.2 Check number of days by month
<img width="324" height="246" alt="image" src="https://github.com/user-attachments/assets/b184c6e9-af9f-4173-b8a8-e8c5b142ab3c" />

0.3 Check NULL / missing values
<img width="933" height="75" alt="image" src="https://github.com/user-attachments/assets/16858777-0fe3-4bd2-87bb-4e27f0e6bd35" />

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
