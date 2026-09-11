# Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery
**Author:** Tran Thi Lan

**Date:** 16/10/2002

**Tools Used:** SQL


## 1. Project Overview
### 📖 What is this project about?
This project uses **SQL** and **BigQuery** to analyze the performance of an e-commerce website, focusing on website traffic, user behavior, marketing channel performance, conversion, transactions, and revenue over time. 
The goal is to identify key performance trends, understand customer purchasing behavior, and evaluate how different traffic sources and devices contribute to overall business performance.
### Business Questions
1. **How is the e-commerce website performing?**
   - Analyze visits, pageviews, transactions, bounce rate, and revenue trends over time.

2. **Which traffic sources and devices drive the best business performance?**
   - Evaluate traffic, conversion rate, and revenue contribution by traffic source and device.

3. **How do customers behave throughout the purchasing journey?**
   - Compare browsing behavior between purchasers and non-purchasers and analyze purchasing frequency.

4. **Which products and product journeys contribute to sales?**
   - Analyze product-level conversion from view → add to cart → purchase and identify products purchased together.
...

## 📂 Dataset Description & Data Structure

**📌 Data Source**: The sample data is from **Google Analytics 4 (GA4)**, exported to **BigQuery**, including user activity data from the **Google Merchandise Store** e-commerce website.

**📌 Data Size**:

- **Dataset**: `ga4_obfuscated_sample_ecommerce`

**📌 How to Access the Data:**
1. Log in to your **Google Cloud Platform** account and create a new project.
2. Open the **BigQuery Console** and select your project.
3. Click on **"Add Data"** in the navigation panel, then choose **"Search a project"**.
4. In the search bar, enter the project ID: `bigquery-public-data.google_analytics_sample.ga_sessions` and press **Enter**.
5. Click on the `ga_sessions_` table to explore its structure and data.

## 4. Data Model
- Mô tả relationship giữa các bảng
- Có thể chèn ERD/schema diagram
## 5. Query
1.Check available date range
<img width="520" height="79" alt="image" src="https://github.com/user-attachments/assets/4f2e2b63-a091-477c-bffa-a660a6bd0e98" />

0.2 Check number of days by month
<img width="324" height="246" alt="image" src="https://github.com/user-attachments/assets/b184c6e9-af9f-4173-b8a8-e8c5b142ab3c" />

