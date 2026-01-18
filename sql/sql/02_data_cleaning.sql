CREATE TABLE dbo.Retail_Clean AS
SELECT
    LTRIM(RTRIM(InvoiceNo)) AS InvoiceNo,
    LTRIM(RTRIM(StockCode)) AS StockCode,
    LTRIM(RTRIM(Description)) AS Description,
    TRY_CONVERT(INT, Quantity) AS Quantity,
    TRY_CONVERT(DATETIME, InvoiceDate) AS InvoiceDate,
    TRY_CONVERT(DECIMAL(10,2), UnitPrice) AS UnitPrice,
    TRY_CONVERT(INT, CustomerID) AS CustomerID,
    LTRIM(RTRIM(Country)) AS Country,
    TRY_CONVERT(INT, Quantity) * TRY_CONVERT(DECIMAL(10,2), UnitPrice) AS Revenue
FROM dbo.OnlineRetail_Raw
WHERE
    TRY_CONVERT(INT, Quantity) IS NOT NULL
    AND TRY_CONVERT(DECIMAL(10,2), UnitPrice) IS NOT NULL
    AND TRY_CONVERT(INT, CustomerID) IS NOT NULL
