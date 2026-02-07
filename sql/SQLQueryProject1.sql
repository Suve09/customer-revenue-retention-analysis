
USE BA_PROJECT
GO

DROP TABLE IF EXISTS dbo.OnlineRetail_Raw;
GO

CREATE TABLE dbo.OnlineRetail_Raw (
    InvoiceNo     NVARCHAR(50),
    StockCode     NVARCHAR(50),
    Description   NVARCHAR(255),
    Quantity      NVARCHAR(50),
    InvoiceDate   NVARCHAR(50),
    UnitPrice     NVARCHAR(50),
    CustomerID    NVARCHAR(50),
    Country       NVARCHAR(100)
)
GO
BULK INSERT dbo.OnlineRetail_Raw
FROM 'C:\PROJECTS FOR RESUME\ONLINE RETAIL.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
)
GO

SELECT TOP 10 *
FROM dbo.OnlineRetail_Raw

SELECT COUNT(*) AS total_rows
FROM dbo.OnlineRetail_Raw

DROP TABLE IF EXISTS dbo.Retail_Clean;
GO

SELECT
    InvoiceNo     = LTRIM(RTRIM(InvoiceNo)),
    StockCode     = LTRIM(RTRIM(StockCode)),
    Description   = LTRIM(RTRIM(Description)),
    CustomerID    = TRY_CONVERT(INT, CustomerID),
    InvoiceDateTime = TRY_CONVERT(DATETIME, InvoiceDate),
    InvoiceDate   = CAST(TRY_CONVERT(DATETIME, InvoiceDate) AS DATE),
    InvoiceTime   = CAST(TRY_CONVERT(DATETIME, InvoiceDate) AS TIME),
    Quantity      = TRY_CONVERT(INT, Quantity),
    UnitPrice     = TRY_CONVERT(DECIMAL(18,2), UnitPrice),
    Revenue       = CAST(TRY_CONVERT(INT, Quantity) * TRY_CONVERT(DECIMAL(18,2), UnitPrice) AS DECIMAL(18,2)),
    Country       = LTRIM(RTRIM(Country))
INTO dbo.Retail_Clean
FROM dbo.OnlineRetail_Raw
WHERE
    TRY_CONVERT(INT, CustomerID) IS NOT NULL
    AND TRY_CONVERT(DATETIME, InvoiceDate) IS NOT NULL
    AND TRY_CONVERT(INT, Quantity) > 0
    AND TRY_CONVERT(DECIMAL(18,2), UnitPrice) > 0
GO
SELECT
    SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS null_invoice,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_customer,
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS null_invoicedate,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS null_unitprice,
    SUM(CASE WHEN Revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue
FROM dbo.Retail_Clean

SELECT COUNT(*) AS clean_rows
FROM dbo.Retail_Clean

SELECT
  MIN(InvoiceDate) AS min_date,
  MAX(InvoiceDate) AS max_date,
  SUM(Revenue) AS total_revenue
FROM dbo.Retail_Clean

SELECT
    MIN(Revenue) AS min_revenue,
    MAX(Revenue) AS max_revenue,
    AVG(Revenue) AS avg_revenue
FROM dbo.Retail_Clean

SELECT TOP 20
    InvoiceNo,
    CustomerID,
    InvoiceDate,
    InvoiceTime,
    Quantity,
    UnitPrice,
    Revenue,
    Country
FROM dbo.Retail_Clean
ORDER BY InvoiceDate

SELECT
    (SELECT COUNT(*) FROM dbo.OnlineRetail_Raw) AS raw_rows,
    (SELECT COUNT(*) FROM dbo.Retail_Clean) AS clean_rows

----TOTAL REVENUE---
SELECT SUM (Revenue) AS total_revenue
FROM dbo.Retail_Clean

---How much revenue did the business generate each month?---
	SELECT
    YEAR(InvoiceDate)  AS year,
    MONTH(InvoiceDate) AS month,
    SUM(Revenue)       AS monthly_revenue
FROM dbo.Retail_Clean
GROUP BY
    YEAR(InvoiceDate),
    MONTH(InvoiceDate)
ORDER BY
    year, month

----ACTIVE CUSTOMER PER MONTH---
SELECT
    YEAR(InvoiceDate)  AS year,
    MONTH(InvoiceDate) AS month,
    COUNT(DISTINCT CustomerID) AS active_customers
FROM dbo.Retail_Clean
GROUP BY
    YEAR(InvoiceDate),
    MONTH(InvoiceDate)
ORDER BY
    year, month
----Revenue Per Customer--
---On average, how much revenue does each customer generate per month?
	SELECT
    YEAR(InvoiceDate)  AS year,
    MONTH(InvoiceDate) AS month,
    SUM(Revenue) / COUNT(DISTINCT CustomerID) AS revenue_per_customer
FROM dbo.Retail_Clean
GROUP BY
    YEAR(InvoiceDate),
    MONTH(InvoiceDate)
ORDER BY
    year, month

---How many customers bought only once vs multiple times?---
SELECT
    CASE
        WHEN COUNT(DISTINCT InvoiceNo) = 1 THEN 'One-Time'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM dbo.Retail_Clean
GROUP BY CustomerID

---Which group contributes more revenue?---
SELECT
    customer_type,
    SUM(total_revenue) AS revenue
FROM (
    SELECT
        CustomerID,
        CASE
            WHEN COUNT(DISTINCT InvoiceNo) = 1 THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type,
        SUM(Revenue) AS total_revenue
    FROM dbo.Retail_Clean
    GROUP BY CustomerID
) t
GROUP BY customer_type

---Who spends more on average?--
 SELECT
    customer_type,
    AVG(total_revenue) AS avg_revenue_per_customer
FROM (
    SELECT
        CustomerID,
        CASE
            WHEN COUNT(DISTINCT InvoiceNo) = 1 THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type,
        SUM(Revenue) AS total_revenue
    FROM dbo.Retail_Clean
    GROUP BY CustomerID
) t
GROUP BY customer_type

---A customer is active in a month if they made at least one purchase in that month.---
SELECT
    YEAR(InvoiceDate) AS year,
	MONTH(InvoiceDate) AS month,
	COUNT(DISTINCT CustomerID) AS active_customers
	FROM dbo.Retail_Clean
	GROUP BY 
	YEAR(InvoiceDate),
	MONTH(InvoiceDate)
	ORDER BY
	year, month

----How many customers purchased this month and also purchased in the previous month?--
WITH monthly_customers AS (
    SELECT DISTINCT
        CustomerID,
        YEAR(InvoiceDate)  AS year,
        MONTH(InvoiceDate) AS month
    FROM dbo.Retail_Clean
)
SELECT
    curr.year,
    curr.month,
    COUNT(DISTINCT curr.CustomerID) AS returning_customers
FROM monthly_customers curr
JOIN monthly_customers prev
    ON curr.CustomerID = prev.CustomerID
   AND (curr.year = prev.year AND curr.month = prev.month + 1
        OR curr.year = prev.year + 1 AND curr.month = 1 AND prev.month = 12)
GROUP BY
    curr.year, curr.month
ORDER BY
    curr.year, curr.month

---CALCULATE RETENTION RATE---
--Retention rate = returning customers ÷ active customers (previous month)--
WITH monthly_active AS (
    SELECT
        YEAR(InvoiceDate)  AS year,
        MONTH(InvoiceDate) AS month,
        COUNT(DISTINCT CustomerID) AS active_customers
    FROM dbo.Retail_Clean
    GROUP BY
        YEAR(InvoiceDate),
        MONTH(InvoiceDate)
),
monthly_returning AS (
    SELECT
        curr.year,
        curr.month,
        COUNT(DISTINCT curr.CustomerID) AS returning_customers
    FROM (
        SELECT DISTINCT
            CustomerID,
            YEAR(InvoiceDate) AS year,
            MONTH(InvoiceDate) AS month
        FROM dbo.Retail_Clean
    ) curr
    JOIN (
        SELECT DISTINCT
            CustomerID,
            YEAR(InvoiceDate) AS year,
            MONTH(InvoiceDate) AS month
        FROM dbo.Retail_Clean
    ) prev
      ON curr.CustomerID = prev.CustomerID
     AND (curr.year = prev.year AND curr.month = prev.month + 1
          OR curr.year = prev.year + 1 AND curr.month = 1 AND prev.month = 12)
    GROUP BY curr.year, curr.month
)
SELECT
    r.year,
    r.month,
    r.returning_customers * 1.0 / a.active_customers AS retention_rate
FROM monthly_returning r
JOIN monthly_active a
  ON r.year = a.year AND r.month = a.month
ORDER BY r.year, r.month
