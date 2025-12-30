## Retail Sales SQL Case Study (Kaggle Dataset)

This project is a retail SQL data analytics case study built using the Kaggle “Retail Dataset” (stores, sales, and external features). [file:66]  
It focuses on designing a relational schema, loading raw CSV data into MySQL, and writing analytical SQL queries to answer business questions about store and department performance, holidays, and markdowns. [file:66]

---

## Dataset

- Source: Kaggle – Retail Dataset  
  https://www.kaggle.com/datasets/manjeetsingh/retaildataset [file:66]  
- Tables used:  
  - stores: Store type and size  
  - features: Temperature, fuel price, markdowns, CPI, unemployment, holiday flags, holiday names  
  - sales: Weekly sales by store, department, and date [file:66]  

---

## Tech Stack

- Database: MySQL (or compatible SQL database)  
- Language: SQL (DDL + DML + analytical queries)  
- Data Source: Kaggle CSV files loaded via LOAD DATA LOCAL INFILE [file:66]  

---

## Project Objectives

- Design a relational schema for the retail dataset (stores, features, sales). [file:66]  
- Load raw CSV files into SQL tables and perform data quality checks. [file:66]  
- Use SQL to answer business questions, including:  
  - Weekly sales by store and department  
  - Impact of holidays (Super Bowl, Labor Day, Thanksgiving, Christmas) on sales  
  - Effect of markdowns on holiday vs non-holiday performance  
  - Best and worst performing departments per store  
  - Global maximum weekly sales and top revenue-generating departments [file:66]  

---

## Implementation Overview

Key steps implemented in Retail-case-study.sql: [file:66]

1. Database and tables  
   - Created database retail and tables stores, features, and sales with primary/foreign keys.  
   - Added index idx_features_store_date on (Store, Date) to optimize joins between sales and features. [file:66]  

2. Data loading  
   - Loaded stores, sales, and features CSV files using LOAD DATA LOCAL INFILE.  
   - Ran sample SELECT ... LIMIT 10 queries to confirm data was loaded correctly. [file:66]  

3. Holiday enrichment  
   - Added a HolidayName column in features.  
   - Tagged major US holidays (Super Bowl, Labor Day, Thanksgiving Weekend, Christmas) based on IsHoliday and date ranges. [file:66]  

> Note: File paths in the script are placeholders (C:/path/to/datasets/...) and should be updated to match the local machine before execution. [file:66]

---

## Analytical Questions Solved

All queries are in Retail-case-study.sql. Below are the main analyses. [file:66]

- Weekly sales by store and department  
  - Aggregates Weekly_Sales grouped by Store, Dept, and Date to understand weekly revenue drivers. [file:66]  

- Average CPI per store  
  - Calculates AVG(CPI) per Store to compare stores under different economic conditions. [file:66]  

- Sales when CPI > 160  
  - Joins sales and features and filters by CPI > 160 to study sales in high-CPI periods. [file:66]  

- Top department per store during holiday weeks  
  - Uses a CTE and RANK window function to find the highest weekly sales department in each store during holiday weeks. [file:66]  

- Markdown impact: holiday vs non-holiday  
  - Computes average sales for departments with markdowns on holidays vs non-holidays using CASE and AVG. [file:66]  

- Best Super Bowl performers per year  
  - Uses a CTE with ROW_NUMBER to identify, for each year, the top store–department combination during Super Bowl weeks. [file:66]  

- Best and worst departments per store  
  - Calculates average weekly sales per department and ranks them per store to label Highest performing and Least performing. [file:66]  

- Maximum weekly sales and top departments  
  - Finds the single highest Weekly_Sales across all stores and returns the top 5 departments by total sales. [file:66]  
