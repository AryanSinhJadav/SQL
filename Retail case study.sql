-- Retail Sales SQL Case Study
-- Data Source: Kaggle Retail Dataset
-- Link: https://www.kaggle.com/datasets/manjeetsingh/retaildataset
-- Personal data analytics project (inspired by a learning assignment)

-- 1. Create database and tables
CREATE DATABASE IF NOT EXISTS retail;
USE retail;

CREATE TABLE IF NOT EXISTS stores (
  Store INT PRIMARY KEY,
  Type VARCHAR(1),
  Size INT
);

DESCRIBE stores;

CREATE TABLE IF NOT EXISTS features (
  Store INT,
  Date DATE,
  Temperature DECIMAL(6, 2),
  Fuel_Price DECIMAL(5, 3),
  MarkDown1 DECIMAL(10, 2) DEFAULT NULL,
  MarkDown2 DECIMAL(10, 2) DEFAULT NULL,
  MarkDown3 DECIMAL(10, 2) DEFAULT NULL,
  MarkDown4 DECIMAL(10, 2) DEFAULT NULL,
  MarkDown5 DECIMAL(10, 2) DEFAULT NULL,
  CPI DECIMAL(10, 7) DEFAULT NULL,
  Unemployment DECIMAL(6, 3) DEFAULT NULL,
  IsHoliday BOOLEAN,
  -- PRIMARY KEY (Store, Date, IsHoliday),
  FOREIGN KEY (Store) REFERENCES stores (Store)
);

CREATE INDEX idx_features_store_date ON features (Store, Date);

CREATE TABLE IF NOT EXISTS sales (
  Store INT,
  Dept INT,
  Date DATE,
  Weekly_Sales DECIMAL(10, 2),
  IsHoliday BOOLEAN,
  PRIMARY KEY (Store, Dept, Date),
  FOREIGN KEY (Store) REFERENCES stores (Store),
  FOREIGN KEY (Store, Date) REFERENCES features (Store, Date)
);

-- 2. Load data (update local paths as per your system)
SHOW VARIABLES LIKE 'secure_file_priv';

-- TODO: change file paths according to your machine before running
LOAD DATA LOCAL INFILE 'C:/path/to/datasets/stores data-set.csv'
INTO TABLE stores
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/path/to/datasets/sales data-set.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/path/to/datasets/Features data set_new1.csv'
INTO TABLE features
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 3. Quick data quality checks
SELECT * FROM stores   LIMIT 10;
SELECT * FROM features LIMIT 10;
SELECT * FROM sales    LIMIT 10;

-- 4. Add and populate HolidayName column for major US holidays
ALTER TABLE features
ADD COLUMN IF NOT EXISTS HolidayName VARCHAR(20);

-- Super Bowl
UPDATE features
SET HolidayName = 'Super Bowl'
WHERE IsHoliday = TRUE
  AND Date BETWEEN '2013-02-08' AND '2013-02-11';

-- Labor Day
UPDATE features
SET HolidayName = 'Labor Day'
WHERE IsHoliday = TRUE
  AND Date BETWEEN '2013-09-07' AND '2013-09-09';

-- Thanksgiving Weekend
UPDATE features
SET HolidayName = 'Thanksgiving Weekend'
WHERE IsHoliday = TRUE
  AND Date BETWEEN '2013-11-23' AND '2013-11-29';

-- Christmas
UPDATE features
SET HolidayName = 'Christmas'
WHERE IsHoliday = TRUE
  AND Date BETWEEN '2013-12-28' AND '2013-12-31';

-- Validate holiday tagging
SELECT
  Store,
  Date,
  IsHoliday,
  HolidayName
FROM features
WHERE IsHoliday = TRUE;

-------------------------------------------------------------
-- ANALYTICAL QUERIES
-------------------------------------------------------------

/* Q1: Weekly sales by store and department
   Business question:
   How much did each department sell every week in each store?
   This helps understand weekly revenue drivers by store and department.
*/
SELECT
  Store,
  Dept,
  Date,
  SUM(Weekly_Sales) AS Total_Weekly_Sales
FROM sales
GROUP BY Store, Dept, Date
ORDER BY Store ASC, Dept ASC, Date ASC;

/* Q2: Average CPI by store
   Business question:
   What is the average CPI per store over the entire period?
   This helps compare stores operating under different economic conditions.
*/
SELECT
  Store,
  ROUND(AVG(CPI), 2) AS Average_CPI
FROM features
GROUP BY Store
ORDER BY Average_CPI DESC, Store ASC;

/* Q3: Sales where CPI > 160
   Business question:
   For which store–department–date combinations was CPI high (>160),
   and what were the corresponding weekly sales?
*/
SELECT
  s.Store,
  s.Dept,
  s.Date,
  s.Weekly_Sales
FROM sales s
JOIN features f
  ON s.Store = f.Store
 AND s.Date  = f.Date
WHERE f.CPI > 160
ORDER BY s.Store ASC, s.Dept ASC, s.Date ASC;

/* Q4: Top department per store during holiday weeks
   Business question:
   During holiday weeks, which department in each store had the highest weekly sales?
   This supports holiday promotion and inventory planning.
*/
WITH holiday_sales AS (
  SELECT
    s.Store,
    s.Dept,
    s.Date,
    s.Weekly_Sales,
    f.HolidayName,
    RANK() OVER (
      PARTITION BY s.Store
      ORDER BY s.Weekly_Sales DESC
    ) AS Sales_Rank
  FROM sales s
  JOIN features f
    ON s.Store = f.Store
   AND s.Date  = f.Date
  WHERE f.IsHoliday = TRUE
)
SELECT
  Store,
  Dept,
  Date,
  WEEK(Date, 2) AS Week_Number, -- week number (Sunday as first day)
  Weekly_Sales,
  HolidayName
FROM holiday_sales
WHERE Sales_Rank = 1
ORDER BY Store ASC, Dept ASC, Date ASC;

/* Q5: Impact of markdowns on holiday vs non‑holiday sales
   Business question:
   For departments with markdowns, how do average sales on holidays
   compare to non‑holiday weeks?
*/
SELECT
  s.Dept,
  TRUNCATE(AVG(CASE WHEN f.IsHoliday = TRUE  THEN s.Weekly_Sales END), 2) AS Average_Sales_Holiday,
  TRUNCATE(AVG(CASE WHEN f.IsHoliday = FALSE THEN s.Weekly_Sales END), 2) AS Average_Sales_Non_Holiday
FROM sales s
JOIN features f
  ON s.Store = f.Store
 AND s.Date  = f.Date
WHERE
  f.MarkDown1 IS NOT NULL OR
  f.MarkDown2 IS NOT NULL OR
  f.MarkDown3 IS NOT NULL OR
  f.MarkDown4 IS NOT NULL OR
  f.MarkDown5 IS NOT NULL
GROUP BY s.Dept
ORDER BY s.Dept DESC;

/* Q6: Best performing store–department during Super Bowl week (per year)
   Business question:
   For each year, which store and department performed best during Super Bowl weeks?
*/
WITH super_bowl_sales AS (
  SELECT
    EXTRACT(YEAR FROM s.Date) AS Year,
    s.Store,
    s.Dept,
    SUM(s.Weekly_Sales) AS Total_Sales,
    ROW_NUMBER() OVER (
      PARTITION BY EXTRACT(YEAR FROM s.Date)
      ORDER BY SUM(s.Weekly_Sales) DESC
    ) AS Sales_Rank
  FROM sales s
  JOIN features f
    ON s.Store = f.Store
   AND s.Date  = f.Date
  WHERE
    f.IsHoliday = TRUE
    AND f.HolidayName = 'Super Bowl'
    AND EXTRACT(YEAR FROM s.Date) BETWEEN 2010 AND 2012
  GROUP BY
    EXTRACT(YEAR FROM s.Date),
    s.Store,
    s.Dept
)
SELECT
  Year,
  Store,
  Dept,
  Total_Sales
FROM super_bowl_sales
WHERE Sales_Rank = 1
ORDER BY Year, Store;

/* Q7: (Pending)
   Markdown Impact Evaluation – can be extended to model uplift % vs baseline.
*/

/* Q8: Best and worst departments per store
   Business question:
   For each store, which department performs best and which performs worst
   based on average weekly sales?
*/
WITH avg_sales AS (
  SELECT
    Store,
    Dept,
    ROUND(AVG(Weekly_Sales), 2) AS Average_Weekly_Sales,
    RANK() OVER (
      PARTITION BY Store
      ORDER BY AVG(Weekly_Sales) ASC
    ) AS Lowest_Sales_Rank,
    RANK() OVER (
      PARTITION BY Store
      ORDER BY AVG(Weekly_Sales) DESC
    ) AS Highest_Sales_Rank
  FROM sales
  GROUP BY Store, Dept
)
SELECT
  Store,
  Dept,
  Average_Weekly_Sales,
  CASE
    WHEN Lowest_Sales_Rank = 1  THEN 'Least performing'
    WHEN Highest_Sales_Rank = 1 THEN 'Highest performing'
    ELSE NULL
  END AS Status
FROM avg_sales
WHERE Lowest_Sales_Rank = 1 OR Highest_Sales_Rank = 1
ORDER BY Store ASC, Dept ASC;

/* Q9: Maximum weekly sales across all stores
   Business question:
   Across all stores and weeks, which department had the single
   highest weekly sales, and when?
*/
SELECT
  s.Dept AS Department_Number,
  MAX(s.Weekly_Sales) AS Highest_Weekly_Sales,
  s.Date AS Week
FROM sales s
GROUP BY
  s.Dept,
  s.Date
ORDER BY
  Highest_Weekly_Sales DESC
LIMIT 1;

/* Q10: Top 5 departments by total sales
   Business question:
   Which 5 departments generate the highest total sales across all stores?
*/
SELECT
  Dept AS Department_Number,
  SUM(Weekly_Sales) AS Total_Sales
FROM sales
GROUP BY Dept
ORDER BY Total_Sales DESC
LIMIT 5;
