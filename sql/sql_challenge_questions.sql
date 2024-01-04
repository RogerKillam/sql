-- https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak

USE [AdventureWorks2019]
GO

/*
* Create a procedure that's called from a CATCH block and prints the following information. Output will be a message as opposed to a result.
* Error Number
* Error Severity
* Error State
* Error Procedure
* Error Line
* Error Message
*/

CREATE OR ALTER PROCEDURE [dbo].[p_report_error_test_procedure]
AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON;
    BEGIN TRY
        SELECT 1 / 0; -- divide by zero error
    END TRY
    BEGIN CATCH
        EXEC [dbo].[p_report_error];
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE [dbo].[p_report_error]
AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON;
    PRINT 'Error ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Severity ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
    PRINT 'State ' + CAST(ERROR_STATE() AS VARCHAR(10));
    PRINT 'Procedure ' + CAST(ERROR_PROCEDURE() AS VARCHAR(50));
    PRINT 'Line ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT ERROR_MESSAGE();
END
GO

EXEC [dbo].[p_report_error_test_procedure];
GO

-- Cleanup
DROP PROCEDURE [dbo].[p_report_error];
DROP PROCEDURE [dbo].[p_report_error_test_procedure];
GO

/*
* Create a procedure that accepts a BusinessEntityID and returns the following information:
* LoginID
* JobTitle
* BirthDate
* MaritalStatus
* Gender
* HireDate
* Current PayRate and PayFrequency
* Current DepartmentName
*
* Check incoming parameters for validity and only return information if the employee is currently employed.
*
* Test
* EXEC [dbo].[p_get_employee_info] 4
* EXEC [dbo].[p_get_employee_info] 16
* EXEC [dbo].[p_get_employee_info] 224
* EXEC [dbo].[p_get_employee_info] 234
* EXEC [dbo].[p_get_employee_info] 250
*/

CREATE OR ALTER PROCEDURE [dbo].[p_get_employee_info] @BusinessEntityID INT
AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON;
    IF NOT EXISTS (SELECT [BusinessEntityID] FROM [HumanResources].[Employee] WHERE [BusinessEntityID] = @BusinessEntityID)
    BEGIN
        RAISERROR ('Employee not found.',16,1);
    END
    IF NOT EXISTS (SELECT [CurrentFlag] FROM [HumanResources].[Employee] WHERE [BusinessEntityID] = @BusinessEntityID)
    BEGIN
        RAISERROR ('Employee is not active.',16,1);
    END
    ;WITH CurrentPayRate AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY [Rate] ORDER BY [RateChangeDate] DESC) AS RowNum
        FROM [HumanResources].[EmployeePayHistory]
    )
    SELECT TOP(1) e.[LoginID]
        , e.[JobTitle]
        , e.[BirthDate]
        , e.[MaritalStatus]
        , e.[Gender]
        , e.[HireDate]
        , [PayRate] = eph.[Rate]
        , eph.[PayFrequency]
        , [DepartmentName] = d.[Name]
    FROM [HumanResources].[Employee] AS e
        , [HumanResources].[EmployeePayHistory] AS eph
        , [HumanResources].[EmployeeDepartmentHistory] AS edh
        , [HumanResources].[Department] AS d
    WHERE e.[BusinessEntityID] = eph.[BusinessEntityID]
        AND e.[BusinessEntityID] = edh.[BusinessEntityID]
        AND edh.[DepartmentID] = d.[DepartmentID]
        AND e.[BusinessEntityID] = @BusinessEntityID
        AND edh.[EndDate] IS NULL
    ORDER BY eph.[RateChangeDate] DESC;
END
GO

-- Cleanup
DROP PROCEDURE [dbo].[p_get_employee_info];
GO

/*
* Create a procedure that returns: ProductID, ProductName, CultureID, and Description.
* The procedure should accept two parameters, ProductID and CultureID.
* If not specified by the caller, the parameters should default to a NULL value.
* If specified the result should be limited to a matching ProductID and CultureID.
* If not specified, the procedure should return all values.
*
* Test
* EXEC [dbo].[p_get_product_info] NULL, NULL
* EXEC [dbo].[p_get_product_info] NULL, 'ar'
* EXEC [dbo].[p_get_product_info] 980, NULL
* EXEC [dbo].[p_get_product_info] 931, 'zh-cht'
* EXEC [dbo].[p_get_product_info] 931, 'en'
* EXEC [dbo].[p_get_product_info] 931, 'fr'
*/

CREATE OR ALTER PROCEDURE [dbo].[p_get_product_info] @ProductID INT = NULL, @CultureID NCHAR(6) = NULL
AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON;
    SELECT [ProductID]
        , [ProductName] = [Name]
        , [CultureID]
        , [Description]
    FROM [Production].[vProductAndDescription]
    WHERE [ProductID] = IIF(@ProductID IS NULL, [ProductID], @ProductID)
        AND [CultureID] = IIF(@CultureID IS NULL, [CultureID], @CultureID);
END
GO

-- Cleanup
DROP PROCEDURE [dbo].[p_get_product_info];
GO

/*
* Create a scalar function that accepts a single tinyint parameter named @Status.
* The function should return the following:
* When a status of 1 is passed, return the unicode string 'Pending Approval' 
* When a status of 2 is passed, return the unicode string 'Approved'
* When a status of 3 is passed, return the unicode string that 'Obsolete'
* Else, the function should return the unicode string '** Invalid **'
*
* Test
* SELECT [dbo].[f_get_document_status_text](0);
* SELECT [dbo].[f_get_document_status_text](1);
* SELECT [dbo].[f_get_document_status_text](2);
* SELECT [dbo].[f_get_document_status_text](3);
*/

CREATE OR ALTER FUNCTION [dbo].[f_get_document_status_text] (@Status TINYINT) RETURNS NVARCHAR(16)
-- Do not call the function on a NULL input (WITH RETURNS NULL ON NULL INPUT).
-- Because no data manipulation is being performed, tell the optimizer not to build a spool table (SCHEMABINDING).
WITH RETURNS NULL ON NULL INPUT, SCHEMABINDING
AS
BEGIN
    RETURN CASE @Status
    WHEN 1 THEN 'Pending Approval'
    WHEN 2 THEN 'Approved'
    WHEN 3 THEN 'Obsolete'
    ELSE '** Invalid **'
    END;
END
GO

-- Cleanup
DROP FUNCTION [dbo].[f_get_document_status_text];
GO

/*
* Create a inline table valued function that accepts from 1 to 6 CustomerIDs.
* The function should return a table that contains the following columns from the SalesOrderHeader table:
* [CustomerID]
* [SalesOrderID]
* [OrderDate]
* [SubTotal]
* [TaxAmt]
*
* Test
*
    SELECT *
    FROM [dbo].[f_get_customer_sales](11000, 11001, 11002, 11003, 11004, 1100);
*
* Result Key
*
* CustomerID    SalesOrderID    OrderDate                   SubTotal        TaxAmt
* 11000         43793           2011-06-21  00:00:00.000    3399.99         271.9992
* 11000         51522           2013-06-20  00:00:00.000    2341.97         187.3576
* 11000         57418           2013-10-03  00:00:00.000    2507.03         200.5624
* 11001         43767           2011-06-17  00:00:00.000    3374.99         269.9992
* 11001         51493           2013-06-18  00:00:00.000    2419.93         193.5944
* 11001         72773           2014-05-12  00:00:00.000    588.96          47.1168
* 11002         43736           2011-06-09  00:00:00.000    3399.99         271.9992
* 11002         51238           2013-06-02  00:00:00.000    2294.99         183.5992
* 11002         53237           2013-07-26  00:00:00.000    2419.06         193.5248
* 11003         43701           2011-05-31  00:00:00.000    3399.99         271.9992
* 11003         51315           2013-06-07  00:00:00.000    2318.96         185.5168
* 11003         57783           2013-10-10  00:00:00.000    2420.34         193.6272
* 11004         43810           2011-06-25  00:00:00.000    3399.99         271.9992
* 11004         51595           2013-06-24  00:00:00.000    2376.96         190.1568
* 11004         57293           2013-10-01  00:00:00.000    2419.06         193.5248
*/

CREATE OR ALTER FUNCTION [dbo].[f_get_customer_sales] (@CustomerId1 INT = 0, @CustomerId2 INT = 0, @CustomerId3 INT = 0, @CustomerId4 INT = 0, @CustomerId5 INT = 0, @CustomerId6 INT = 0)
RETURNS TABLE
AS
RETURN (
    SELECT [CustomerID], [SalesOrderID], [OrderDate], [SubTotal], [TaxAmt]
    FROM [Sales].[SalesOrderHeader]
    WHERE [CustomerID] IN (@CustomerId1, @CustomerId2, @CustomerId3, @CustomerId4, @CustomerId5, @CustomerId6)
)
GO

-- Cleanup
DROP FUNCTION [dbo].[f_get_customer_sales];
GO

/*
* Create a multi-statement table valued function that accepts a single integer parameter @ScrapCompareLevel.
* The function should return a table that contains the following columns:
* [Product Name], [Scrap Quantity], [Scrap Reason], [Scrap Status]
*
* The function should test the Production.WorkOrder ScrapReasonID. If it is not null, the row should be included in the result set.
* For each row in the result set, if the ScrapQty is greater than the @ScrapCompareLevel the status should be set to Critical, otherwise it should be set to Normal.
*
* Test
    SELECT ProductName AS [Product Name], ScrapQty AS [Scrap Quantity], ScrapReasonDef AS [Scrap Reason], ScrapStatus AS [Scrap Status]
    FROM dbo.f_get_products_scrap_status(20)
*
* Result Key - limited to the first 10 rows
* Product Name                      Scrap Quantity  Scrap Reason                    Scrap Status
* BB Ball Bearing                   35              Brake assembly not as ordered   Critical
* Blade                             206             Brake assembly not as ordered   Critical
* Chain Stays                       3               Brake assembly not as ordered   Normal
* Down Tube                         2               Brake assembly not as ordered   Normal
* Front Derailleur                  53              Brake assembly not as ordered   Critical
* Head Tube                         26              Brake assembly not as ordered   Critical
* HL Fork                           26              Brake assembly not as ordered   Critical
* HL Mountain Frame - Silver, 38    2               Brake assembly not as ordered   Normal
* HL Mountain Seat Assembly         6               Brake assembly not as ordered   Normal
* HL Road Frame - Black, 48         1               Brake assembly not as ordered   Normal
*/

CREATE OR ALTER FUNCTION [dbo].[f_get_products_scrap_status] (@ScrapCompareLevel INT)
RETURNS @ScrapStats TABLE ([ProductName] NVARCHAR(50), [ScrapQty] SMALLINT, [ScrapReasonDef] NVARCHAR(50), [ScrapStatus] NVARCHAR(8))
AS
BEGIN
    INSERT INTO @ScrapStats ([ProductName], [ScrapQty], [ScrapReasonDef], [ScrapStatus])
    SELECT TOP(10) p.[Name]
        , wo.[ScrappedQty]
        , sr.[Name]
        , CASE WHEN wo.[ScrappedQty] > @ScrapCompareLevel THEN 'Critical' ELSE 'Normal' END AS [ScrapStatus]
    FROM [Production].[WorkOrder] AS wo, [Production].[ScrapReason] AS sr, [Production].[Product] AS p
    WHERE wo.[ProductID] = p.[ProductID]
        AND wo.[ScrapReasonID] = sr.[ScrapReasonID]
        AND wo.[ScrapReasonID] IS NOT NULL
    RETURN
END
GO

-- Cleanup
DROP FUNCTION [dbo].[f_get_products_scrap_status];
GO

/*
*   Select the total for Subtotal, Tax, and Freight for all orders.
*   Show results: Sales, Taxes, Freight, Total Due.
*
*   Result Key:
*
*       Sales                 Taxes                 Freight               Total Due
*       --------------------- --------------------- --------------------- ---------------------
*       109846381.4039        10186974.4602         3183430.2518          123216786.1159
*/

SELECT [Sales] = SUM([SubTotal])
    , [Taxes] = SUM([TaxAmt])
    , [Freight] = SUM([Freight])
    , [Total Due] = SUM([TotalDue])
FROM [Sales].[SalesOrderHeader];
GO

/*
*   Select the Tax pct for all orders. Estimate the pct relative to sales.
*   Show results: Tax, Sales, Tax pct.
*
*   Result Key:
*
*       TaxAmt                SubTotal              Tax pct
*       --------------------- --------------------- ---------------------
*       1.6149                20.1865               7.99
*       ...
*       (31465 rows affected)
*/

SELECT [TaxAmt]
    , [SubTotal]
    , [Tax pct] = ([TaxAmt] / [SubTotal]) * 100
FROM [Sales].[SalesOrderHeader]
ORDER BY [Tax pct];
GO

/*
*   Select the Freight pct for all orders. Estimate the pct relative to sales.
*   Show results: Freight, Sales, Freight pct
*
*   Result Key:
*
*       Freight               SubTotal              Freight pct
*       --------------------- --------------------- ---------------------
*       25.0109               1000.4375             2.49
*       ...
*       (31465 rows affected)
*/

SELECT [Freight]
    , [SubTotal]
    , [Freight pct] = ([Freight] / [SubTotal]) * 100
FROM [Sales].[SalesOrderHeader]
ORDER BY [Freight pct];
GO

/*
*   Select the average value of an order by year and month.
*   Show results: Year, Month, Avg Value of Orders
*
*   Result Key:
*
*       Year        Month       Order Avg Value
*       ----------- ----------- ---------------------
*       2011        5           11716.4166
*       ...
*       (38 rows affected)
*/

SELECT [Year] = YEAR([OrderDate])
    , [Month] = MONTH([OrderDate])
    , [Order Avg Value] = AVG([SubTotal])
FROM [Sales].[SalesOrderHeader]
GROUP BY YEAR([OrderDate]), MONTH([OrderDate])
ORDER BY YEAR([OrderDate]), MONTH([OrderDate]);
GO

/*
*   Select all products that have a color value.
*   Show results: Product Name
*
*   Result Key:
*
*       Name
*       --------------------------------------------------
*       LL Crankarm
*       ...
*       (256 rows affected)
*/

SELECT [Name]
FROM [Production].[Product]
WHERE [Color] IS NOT NULL;
GO

/*
*   Get the summary of product lines with the number of products in each product line.
*
*   Result Key:
*
*       ProductLine Product Count
*       ----------- -------------
*       NULL        226
*       M           91
*       R           100
*       S           35
*       T           52
*       ...
*       (5 rows affected)
*/

SELECT [ProductLine], [Product Count] = COUNT(ISNULL([ProductLine],0))
FROM [Production].[Product]
GROUP BY [ProductLine]
ORDER BY [ProductLine];
GO

/*
*   Select all product names that end in wheel.
*
*   Result Key:
*
*       Name
*       --------------------------------------------------
*       Freewheel
*       HL Mountain Front Wheel
*       HL Mountain Rear Wheel
*       HL Road Front Wheel
*       HL Road Rear Wheel
*       LL Mountain Front Wheel
*       LL Mountain Rear Wheel
*       LL Road Front Wheel
*       LL Road Rear Wheel
*       ML Mountain Front Wheel
*       ML Mountain Rear Wheel
*       ML Road Front Wheel
*       ML Road Rear Wheel
*       Touring Front Wheel
*       Touring Rear Wheel
*       ...
*       (15 rows affected)
*/

SELECT [Name]
FROM [Production].[Product]
WHERE [Name] LIKE '%wheel';
GO

/*
*   Find if there are any products with a list price less than the standard cost. Show product id and name for those products.
*
*   Result Key:
*
*       ProductID   Name
*       ----------- --------------------------------------------------
*       ...
*       (0 rows affected)
*/

SELECT [ProductID], [Name]
FROM [Production].[Product]
WHERE [ListPrice] < [StandardCost];
GO

/*
*   Select the year summary with rollup of sales by sales person id. Handle the case when there is no sales person associated to the sale.
*   Show results: Year, Sales Person Id, Sales.
*
*   Result Key:
*
*       Year        Sales Person ID Sales
*       ----------- --------------- ---------------------
*       NULL        NULL            109846381.4039
*       2011        NULL            12641672.2129
*       2011        0               3863120.2134
*       2011        274             28926.2465
*       ...
*       (67 rows affected)
*/

SELECT [Year] = YEAR([OrderDate])
    , [Sales Person ID] = COALESCE([SalesPersonID],0)
    , [Sales] = SUM([SubTotal])
FROM [Sales].[SalesOrderHeader]
GROUP BY ROLLUP (YEAR([OrderDate]), COALESCE([SalesPersonID],0))
ORDER BY YEAR([OrderDate]), COALESCE([SalesPersonID],0);
GO

/*
*   Select all order details with a negative margin.
*   Show Results: SalesOrderID, SalesOrderDetailID, Margin.
*   Define Margin: Sales - Total Cost
*
*   Result Key:
*
*       SalesOrderID SalesOrderDetailID Margin
*       ------------ ------------------ ----------
*       43659        8                  -28.955700
*       ...
*/

SELECT sd.[SalesOrderID], sd.[SalesOrderDetailID], [Margin] = sd.[LineTotal] - sd.[OrderQty] * p.[StandardCost]
FROM [Sales].[SalesOrderDetail] AS sd, [Production].[Product] AS p
WHERE p.[ProductID] = sd.[ProductID]
    AND sd.[LineTotal] - sd.[OrderQty] * p.[StandardCost] < 0;
GO

/*
*   Select all orders where one or more details have a negative margin.
*   Show Sesults: SalesOrderID, Total Negative Margin, Total Order Margin.
*
*   Result Key:
*
*       SalesOrderID Total Negative Margin Total Order Margin
*       ------------ --------------------- ------------------
*       51739        -518.420316           10731.007367
*       ...
*/

SELECT sod.[SalesOrderID]
    , [Total Negative Margin] = SUM(IIF(sod.[LineTotal] - sod.[OrderQty] * p.[StandardCost] < 0, sod.[LineTotal] - sod.[OrderQty] * p.[StandardCost], NULL))
    , [Total Order Margin] = SUM(sod.[LineTotal] - sod.[OrderQty] * p.[StandardCost])
FROM [Sales].[SalesOrderDetail] AS sod, [Production].[Product] AS p
WHERE p.[ProductID] = sod.[ProductID]
    AND sod.[SalesOrderID] IN (
        SELECT sod.[SalesOrderID]
        FROM [Sales].[SalesOrderDetail] AS sod, [Production].[Product] AS p
        WHERE p.[ProductID] = sod.[ProductID]
            AND sod.[LineTotal] - sod.[OrderQty] * p.[StandardCost] < 0
    )
GROUP BY sod.[SalesOrderID]
ORDER BY 3 DESC;
GO

/*
*   Select the count of all rows, "customer ids" and "sales person ids" in the SalesOrderHeader table.
*   Show Results: Rows, Count of Customer Ids, Count of SalesPerson Ids.
*
*   Result Key:
*
*       Rows        CustomerID  SalesPersonID
*       ----------- ----------- -------------
*       31465       31465       3806
*/

SELECT [Rows] = COUNT(*)
    , [CustomerID] = COUNT([CustomerID])
    , [SalesPersonID] = COUNT([SalesPersonID])
FROM [Sales].[SalesOrderHeader];
GO

/*
*   Select the sales total value and number of items per year, month.
*   Show Results: Year, Month, Sales total, Items total.
*
*   Result Key:
*
*       YEAR        MONTH       SALES TOTAL                             ITEMS TOTAL
*       ----------- ----------- --------------------------------------- -----------
*       2011        5           503805.916900                           825
*/

SELECT [YEAR] = YEAR(soh.[OrderDate])
    , [MONTH] = MONTH(soh.[OrderDate])
    , [SALES TOTAL] = SUM(sod.[LineTotal])
    , [ITEMS TOTAL] = SUM(sod.[OrderQty])
FROM [Sales].[SalesOrderHeader] AS soh
    , [Sales].[SalesOrderDetail] AS sod
WHERE soh.[SalesOrderID] = sod.[SalesOrderID]
GROUP BY YEAR(soh.[OrderDate]), MONTH(soh.[OrderDate])
ORDER BY 1, 2;
GO

/*
*   Select the average value of an order by year, month.
*   Include the average number of lines and the average number of items per order.
*   Show Results: Year, Month, Avg Value of Orders, Avg Number of Items, Avg Number of Lines.
*
*   Result Key:
*
*       YEAR        MONTH       Avg Value of Orders   Avg Number of Items Avg Number of Lines
*       ----------- ----------- --------------------- ------------------- -------------------
*       2011        5           11716.4166            19                  8
*       ...
*/

;WITH SalesOrdersSummary AS (
    SELECT [YEAR] = YEAR(soh.[OrderDate])
        , [MONTH] = MONTH(soh.[OrderDate])
        , soh.[SalesOrderID]
        , soh.[SubTotal]
        , [Number of Items] = SUM(sod.[OrderQty])
        , [Number of lines] = COUNT(soh.[SalesOrderID])
    FROM [Sales].[SalesOrderHeader] AS soh, [Sales].[SalesOrderDetail] AS sod
    WHERE soh.[SalesOrderID] = sod.[SalesOrderID]
    GROUP BY soh.[OrderDate], soh.[SalesOrderID], soh.[SubTotal]
)
SELECT [YEAR]
    , [MONTH]
    , [Avg Value of Orders] = AVG([SubTotal])
    , [Avg Number of Items] = AVG([Number of Items])
    , [Avg Number of Lines] = AVG([Number of lines])
FROM SalesOrdersSummary
GROUP BY [YEAR], [MONTH]
ORDER BY 1, 2;
GO

/*
*   Select the total sales, cost, margin and margin percent per country.
*   Define Margin: Sales Value - Cost Value
*   Define Margin %: (1 - Cost/Sales) * 100
*
*   Result Key:
*
*       Country   Total           Cost         Margin         Margin Pct
*       --------- --------------- ------------ -------------- ----------
*       Australia 10655335.959317 7221080.5803 3434255.379017 32.230300
*       ...
*/

SELECT [Country] = cr.[Name]
    , [Total] = SUM(sod.[LineTotal])
    , [Cost] = SUM(p.[StandardCost] * sod.[OrderQty])
    , [Margin] = SUM(sod.[LineTotal]) - SUM(p.[StandardCost] * sod.[OrderQty])
    , [MarginPct] = ((SUM(sod.[LineTotal]) - SUM(p.[StandardCost] * sod.[OrderQty])) / SUM(sod.[LineTotal])) * 100
FROM [Sales].[SalesOrderHeader] AS soh
    , [Sales].[SalesTerritory] AS st
    , [Person].[CountryRegion] AS cr
    , [Sales].[SalesOrderDetail] AS sod
    , [Production].[Product] AS p
WHERE soh.[TerritoryID] = st.[TerritoryID]
    AND st.[CountryRegionCode] = cr.[CountryRegionCode]
    AND soh.[SalesOrderID] = sod.[SalesOrderID]
    AND p.[ProductID] = sod.[ProductID]
GROUP BY cr.[Name]
ORDER BY cr.[Name];
GO

/*
*   Select the top 5 salespersons by margin per year.
*   Show information as: Year, Employee ID, Employee Name (Last, First), Margin.
*   For every year, show the top 5
*
*   Result Key:
*
*       Sales Year  Sales Person ID Employee             Margin
*       ----------- --------------- -------------------- ------------
*       2011        279             Reiter, TsviMichael  36183.911168
*       ...
*/

;WITH SalesPersonIDs AS (
    SELECT [Sales Person ID] = SP.[BusinessEntityID]
        , PR.[LastName] + ', ' + PR.[FirstName] + CASE WHEN PR.[MiddleName] IS NULL THEN '' ELSE PR.[MiddleName] END AS [Employee]
    FROM [Sales].[SalesPerson] AS SP, [Person].[Person] AS PR
    WHERE PR.[BusinessEntityID] = SP.[BusinessEntityID]
), AnnualSalePersonMargin AS (
    SELECT [Sales Year] = YEAR(H.[OrderDate])
        , H.[SalesPersonID]
        , [Margin] = SUM(D.[LineTotal]) - SUM(P.[StandardCost] * D.[OrderQty])
        , [RowNum] = ROW_NUMBER() OVER (PARTITION BY YEAR(H.[OrderDate]) ORDER BY YEAR(H.[OrderDate]), SUM(D.[LineTotal]) - SUM(P.[StandardCost] * D.[OrderQty]) DESC)
    FROM SalesPersonIDs AS ID
        , [Sales].[SalesOrderHeader] AS H
        , [Sales].[SalesOrderDetail] AS D
        , [Production].[Product] AS P
    WHERE H.[SalesPersonID] = ID.[Sales Person ID]
        AND H.[SalesOrderID] = D.[SalesOrderID]
        AND P.[ProductID] = D.[ProductID]
    GROUP BY H.[SalesPersonID], YEAR(H.[OrderDate])
)
SELECT T2.[Sales Year], T2.[SalesPersonID], T1.[Employee], T2.[Margin]
FROM SalesPersonIDs AS T1, AnnualSalePersonMargin AS T2
WHERE T1.[Sales Person ID] = T2.[SalesPersonID]
    AND T2.[RowNum] <= 5;
GO

/*
*   Select all 2012 customers that did not return in 2013.
*
*   Result Key:
*
*       Customer Id
*       -----------
*       20561
*       ...
*/

SELECT [Customer Id] = O.[CustomerID]
FROM [Sales].[SalesOrderHeader] AS O
WHERE YEAR(O.[OrderDate]) = 2012
EXCEPT
SELECT [Customer Id] = O.[CustomerID]
FROM [Sales].[SalesOrderHeader] AS O
WHERE YEAR(O.[OrderDate]) = 2013;
GO

/*
*   Select the Quarterly percent of Total Sales change (quarter over quarter) for 2011, 2012, 2013, 2014.
*
*   Result Key:
*
*       Current Quarter Year Current Quarter Current Quarter Sales Previous Quarter Year Previous Quarter Previous Quarter Sales Performance Pct
*       -------------------- --------------- --------------------- --------------------- ---------------- ---------------------- ---------------------
*       2011                 2               962716.7417           NULL                  NULL             NULL                   NULL
*       2011                 3               5042490.5827          2011                  2                962716.7417            523.77
*       ...
*       2014                 2               7212854.7323          2014                  1                12845074.079           56.15
*/

;WITH [QuaterSales] AS (
    SELECT [Year] = YEAR([OrderDate])
        , [Quarter] = DATEPART(QUARTER, [OrderDate])
        , [Quarter Id] = (YEAR([OrderDate]) - 2010) * 4 + (DATEPART(QUARTER, [OrderDate]) - 1)
        , [Sales] = SUM([SubTotal])
    FROM [Sales].[SalesOrderHeader]
    GROUP BY YEAR([OrderDate]), DATEPART(QUARTER, [OrderDate])
)
SELECT [Current Quarter Year] = CQ.[Year]
    , [Current Quarter] = CQ.[Quarter]
    , [Current Quarter Sales] = CQ.[Sales]
    , [Previous Quarter Year] = PQ.[Year]
    , [Previous Quarter] = PQ.[Quarter]
    , [Previous Quarter Sales] = PQ.[Sales]
    , [Performance Pct] = (CQ.[Sales] / PQ.[Sales]) * 100
FROM [QuaterSales] AS CQ
LEFT JOIN [QuaterSales] AS PQ
    ON CQ.[Quarter Id] - 1 = PQ.[Quarter Id]
ORDER BY 1, 2;
GO

/*
*   Select SalesPerson monthly quota achievement pct for 2012.
*   Define achievement as: Total Sales / Quota
*   Assume Quota value is the monthly quota, and doesn't change over month
*   Show results: [Last Name, First Name], Employee ID, Year, Month, SalesQuota, QuotaPct
*
*   Result Key:
*
*       Employee    BusinessEntityID Year        Month       SalesQuota            Month Total           PCT QUOTA
*       ----------- ---------------- ----------- ----------- --------------------- --------------------- ---------------------
*       Amy Alberts 287              2012        6           NULL                  73732.4685            NULL
*       ...
*/

SELECT [Employee] = T2.[FirstName] + ', ' + T2.[LastName]
    , [BusinessEntityID] = T1.[BusinessEntityID]
    , [Year] = YEAR(T3.[OrderDate])
    , [Month] = MONTH(T3.[OrderDate])
    , T1.[SalesQuota]
    , [Month Total] = SUM(T3.[SubTotal])
    , [PCT QUOTA] = (SUM(T3.[SubTotal]) / T1.[SalesQuota]) * 100
FROM [Sales].[SalesPerson] AS T1, [Person].[Person] AS T2, [Sales].[SalesOrderHeader] AS T3
WHERE T1.[BusinessEntityID] = T3.[SalesPersonID]
    AND T1.[BusinessEntityID] = T2.[BusinessEntityID]
    AND YEAR(T3.[OrderDate]) = 2012
GROUP BY T2.[FirstName] + ', ' + T2.[LastName], T1.[BusinessEntityID], YEAR(T3.[OrderDate]), MONTH(T3.[OrderDate]), T1.[SalesQuota]
ORDER BY 1, 2, 3, 4;
GO

-- Write a query that will display 'Undefined color' when no color is defined in the [Production].[Product] table, otherwise report the color.
-- Option #1
SELECT [ProductID], [Color] = IIF([Color] IS NULL, 'Undefined color', [Color])
FROM [Production].[Product];
GO

-- Option #2
SELECT [ProductID], [Color] = COALESCE([Color], 'Undefined color')
FROM [Production].[Product];
GO

-- Find the average value of a Sales Order and return those orders that are less than the average.
-- Option #1
DROP TABLE IF EXISTS #LineTotals;
SELECT [SalesOrderID], [LineTotals] = SUM([LineTotal])
INTO #LineTotals
FROM [Sales].[SalesOrderDetail]
GROUP BY [SalesOrderID];
GO

DECLARE @AverageValue FLOAT = (SELECT AVG([LineTotals]) FROM #LineTotals);
SELECT [SalesOrderID], [SubTotal] = FORMAT([LineTotals], 'g8')
FROM #LineTotals
WHERE [LineTotals] < @AverageValue
ORDER BY [SalesOrderID];
GO

-- Option #2
DECLARE @SalesOrderAverageValue REAL = (SELECT AVG([SubTotal]) FROM [Sales].[SalesOrderHeader]);
SELECT [SalesOrderID] ,[SubTotal]
FROM [Sales].[SalesOrderHeader]
WHERE [SubTotal] < @SalesOrderAverageValue;
GO

/*
* Find the percentage of Sales that are less than the average value of a sale.
* Result Key:
* Total Sales   Sales below Average Pct Sales below Average
* ------------- ------------------- ---------------------------------------
* 31465         27458               87.265215318607
*/

-- Option #1
DROP TABLE IF EXISTS #LineTotals;
DROP TABLE IF EXISTS #BelowAverage;
GO

SELECT [SalesOrderID], [LineTotals] = SUM([LineTotal])
INTO #LineTotals
FROM [Sales].[SalesOrderDetail]
GROUP BY [SalesOrderID];
GO

SELECT [SalesOrderID], [SubTotal] = FORMAT([LineTotals], 'g8')
INTO #BelowAverage
FROM #LineTotals
WHERE [LineTotals] < (SELECT AVG([LineTotals])
FROM #LineTotals)
ORDER BY [SalesOrderID];
GO

DECLARE @TotalSalesCount FLOAT = (SELECT TOP(1) COUNT(*)FROM #LineTotals);
DECLARE @CountBelowAvg FLOAT = (SELECT TOP(1) COUNT(*) FROM #BelowAverage);
DECLARE @Avg DECIMAL(17,16) = (@CountBelowAvg / @TotalSalesCount);
DECLARE @AvgFormat VARCHAR(100) = (FORMAT(@Avg, 'P14'));
SELECT [Total Sales Sales] = @TotalSalesCount, [Sales below Average] = @CountBelowAvg, [Pct Sales below Average] = LEFT(@AvgFormat, NULLIF(LEN(@AvgFormat)-3,-3));
GO

/*
* Write a script that creates index [SalesOrderDetail_CarrierTracking] on [Sales].[SalesOrderDetail].
* For [CarrierTrackingNumber], [SalesOrderID], [SalesOrderDetailID] make sure the index does not exist before attempting to create it.
*/

-- Option #1
DECLARE @index_id INT = (
    SELECT DISTINCT ([object_id])
    FROM sys.dm_db_index_operational_stats(DB_ID(N'AdventureWorks2019'), OBJECT_ID(N'AdventureWorks2019.Sales.SalesOrderDetail'), NULL, NULL)
);
IF (SELECT [Name] FROM [sys].[indexes] WHERE object_id = @index_id AND [Name] = 'SalesOrderDetail_CarrierTracking') IS NOT NULL
BEGIN
    DROP INDEX [SalesOrderDetail_CarrierTracking] ON [Sales].[SalesOrderDetail];
END
CREATE NONCLUSTERED INDEX [SalesOrderDetail_CarrierTracking] ON [Sales].[SalesOrderDetail] ([SalesOrderID] ASC, [SalesOrderDetailID] ASC, [CarrierTrackingNumber] ASC);
GO

-- Option #2
DECLARE @SalesOrderDetail_Id INT = OBJECT_ID('Sales.SalesOrderDetail', 'U');
IF EXISTS(SELECT 1 FROM sys.indexes WHERE [name] = 'SalesOrderDetail_CarrierTracking' AND [object_id] = @SalesOrderDetail_Id)
BEGIN
    DROP INDEX SalesOrderDetail_CarrierTracking ON Sales.SalesOrderDetail;
END
CREATE NONCLUSTERED INDEX SalesOrderDetail_CarrierTracking ON Sales.SalesOrderDetail ([CarrierTrackingNumber], [SalesOrderID], [SalesOrderDetailID]);
GO

-- Check which numbers between 101 and 200 are primes.
-- Option #1
DECLARE @LowerLimit INT = 100, @UpperLimit INT = 200, @N INT, @P INT;
DECLARE @Numbers TABLE([Number] INT NULL);
DECLARE @Composite TABLE([Number] INT NULL);
SET @P = @UpperLimit;
WHILE @P > @LowerLimit
BEGIN
    INSERT INTO @Numbers([Number])
    VALUES (@P);
    SET @N = 2;
    WHILE @N <= @UpperLimit/2
    BEGIN
        IF ((@P % @N = 0 AND @P <> @N) OR (@P IN (0, 1)))
        BEGIN
            INSERT INTO @Composite([Number])
            VALUES(@P);
            BREAK
        END
        
        SET @N = @N + 1;
    END
    SET @P = @P - 1;
END
SELECT [Primes 100~200] = [Number]
FROM @Numbers
WHERE [Number] NOT IN (SELECT [Number] FROM @Composite)
ORDER BY [Number];
GO

-- Option #2
DECLARE @FirstPrimes TABLE([P] INT);
DECLARE @Primes TABLE([P] INT);
INSERT INTO @FirstPrimes
VALUES (2);
DECLARE @LastCheck INT = ROUND(SQRT(200), 0, 1) + 1;
DECLARE @I INT = 3;
WHILE @I < @LastCheck
BEGIN
    IF NOT EXISTS(SELECT 1 FROM @FirstPrimes WHERE @I % [P] = 0)
    INSERT INTO @FirstPrimes
    VALUES (@I);
    
    SET @I += 1;
END
SET @LastCheck = 200;
SET @I = 101;
WHILE @I <= @LastCheck
BEGIN
    IF NOT EXISTS(SELECT 1 FROM @FirstPrimes WHERE @I % [P] = 0) INSERT INTO @Primes
    VALUES (@I);
    
    SET @I += 1;
END
SELECT [Primes 100~200] = [P]
FROM @Primes;
GO

/*
* Write the Fibonacci sequence for a given value of N = 25.
* Make the script flexible enough that N can be changed to any arbitrary number and the script should still work.
*/
-- Option #1
DECLARE @N INT = 25;
;WITH [Fibonacci]([Counter], [F0] ,[F1]) AS (
    SELECT CAST(0 AS FLOAT), CAST(0 AS FLOAT), CAST(1 AS FLOAT)
    UNION ALL
    SELECT F.[Counter] + 1, F.[F1], F.[F0] + F.[F1]
    FROM [Fibonacci] AS F
    WHERE F.[Counter] < @N
)
SELECT [N] = F.[Counter], [Fibonacci Sequence] = F.[F0]
FROM [Fibonacci] F OPTION (MAXRECURSION 0);
GO

-- Option #2
DECLARE @N INT = 25, @F0 BIGINT = 0, @F1 BIGINT = 1, @F2 BIGINT = 0, @I INT = 0;
WHILE @I <= @N
BEGIN
    IF @I = 0
    BEGIN
        PRINT RIGHT('   ' + CAST(@I AS NVARCHAR(2)), 3) + ' | ' + RIGHT('         ' + CAST(0 AS NVARCHAR(9)), 9);
    END
    ELSE IF @I = 1
    BEGIN
        PRINT RIGHT('   ' + CAST(@I AS NVARCHAR(2)), 3) + ' | ' + RIGHT('         ' + CAST(1 AS NVARCHAR(9)), 9);
    END
    ELSE
    BEGIN
        SET @F0 = @F1 + @F2;
        PRINT RIGHT('   ' + CAST(@I AS NVARCHAR(2)), 3) + ' | ' + RIGHT('         ' + CAST(@F0 AS NVARCHAR(9)), 9);
        SET @F2 = @F1;
        SET @F1 = @F0;
    END
    SET @I += 1
END
PRINT ' ';
GO

/*
* Using master..spt_values as a numbers table
* select * from master..spt_values WHERE [type] = 'P'
* References:
* https://docs.microsoft.com/en-us/sql/t-sql/functions/floor-transact-sql?view=sql-server-ver15
* http://infocenter-archive.sybase.com/help/index.jsp
* spt_value is used often to generate large tables i.e. if you CROSS JOIN spt_value with itself it produces about 6.25 M rows.
* Often used by Itzak Ben-Gan to create his infamous NUMBER table.
*/

DECLARE @N INT = 25, @F INT = 0;
SELECT [I'm a Fibonacci number!] = FLOOR(POWER((1 + SQRT(5)) / 2.0, [number]) / SQRT(5) + 0.5)
FROM [master]..[spt_values]
WHERE [type] = 'P'
    AND [number] BETWEEN @F AND @N;
GO

/*
* Generate a list of 1000 random numbers between 10 and 19, both ends inclusive.
* Show the frequency table.
* Note: The frequency table values should be different from one run to the next one.
*/
-- Option #1
DROP TABLE IF EXISTS #FrequencyTable;
GO
CREATE TABLE #FrequencyTable([RandomNumber] INT);
GO
DECLARE @StartN INT = 10, @StopN INT = 19, @ListSize INT = 1000, @Count INT = 1;
WHILE (@Count <= @ListSize)
BEGIN
    INSERT INTO #FrequencyTable([RandomNumber])
    SELECT [RandomNumber] = FLOOR(RAND() * (@StopN - @StartN + 1)) + @StartN;
    SET @Count += 1;
END
SELECT [R] = [RandomNumber], [ROWS] = COUNT(*)
FROM #FrequencyTable
GROUP BY [RandomNumber]
ORDER BY 1;
GO

-- Option #2
DECLARE @I INT = 0;
DECLARE @RandNumbers TABLE([N] INT, [R] INT);
WHILE @I < 1000
BEGIN
    INSERT INTO @RandNumbers
    VALUES (@I ,CAST(ROUND(RAND() * 1000000, 0, 1) AS INT) % 10 + 10);
    SET @I += 1;
END
SELECT [R], [ROWS] = COUNT(*)
FROM @RandNumbers
GROUP BY [R]
ORDER BY [R];
GO

/*
* Without using the STRING_SPLIT() function, given a comma separated list of numbers as a string, create a table with the numbers and the running sum.
* Input: '1, 2, 3, 4, 316, 323, 324, 325, 326, 327, 328, 329'
*/

DECLARE @textlist NVARCHAR(MAX) = ' 1, 2, 3, 4, 316, 323, 324, 325, 326, 327, 328, 329';
DECLARE @textvalue NVARCHAR(MAX), @N INT, @RS INT = 0, @FirstComma INT;
DECLARE @Numbers TABLE([N] INT, [RunningSum] INT);
WHILE LEN(@textlist) > 0
BEGIN
    SET @FirstComma = CHARINDEX(',', @textlist);
    IF @FirstComma = 0
    BEGIN
        SET @textvalue = RTRIM(LTRIM(@textlist));
        SET @textlist = '';
    END
    ELSE
    BEGIN
        SET @textvalue = RTRIM(LTRIM(SUBSTRING(@textlist, 1, @FirstComma - 1)));
        SET @textlist = SUBSTRING(@textlist, @FirstComma + 1, LEN(@textlist));
    END
    IF LEN(@textvalue) > 0
    BEGIN
        SET @N = CAST(@textvalue AS INT);
        SET @RS += @N;
        INSERT INTO @Numbers
        VALUES (@N ,@RS);
    END
END
SELECT *
FROM @Numbers;
GO

-- Using the Employee-Manager table, generated by the following script list the company org-chart.
DECLARE @EmployeeManager TABLE([EmployeeId] INT NOT NULL, [ManagerId] INT NULL);
;WITH EmpHierarchy AS (
        SELECT [EmpId] = [BusinessEntityID], [NodeId] = COALESCE([OrganizationNode], hierarchyid::GetRoot())
        FROM [HumanResources].[Employee]
)
INSERT INTO @EmployeeManager([EmployeeId],[ManagerId])
SELECT [EmpId] = E.[EmpId], [MgrId] = M.[EmpId]
FROM [EmpHierarchy] AS E
LEFT JOIN [EmpHierarchy] AS M
    ON E.[NodeId].GetAncestor(1) = M.[NodeId];
DECLARE @EmployeeHierarchy TABLE([EmployeeId] INT NOT NULL, [ManagerId] INT NULL, [OrgLevel] INT NOT NULL, [HierarchyPath] NVARCHAR(MAX) NOT NULL);
DECLARE @CurrentLevel INT = 0;
INSERT INTO @EmployeeHierarchy([EmployeeId],[ManagerId],[OrgLevel],[HierarchyPath])
SELECT [EmployeeId], [ManagerId], [OrgLevel] = @CurrentLevel, [Path] = FORMAT(EmployeeId, '00000')
FROM @EmployeeManager
WHERE [ManagerId] IS NULL;
WHILE (@@ROWCOUNT > 0)
BEGIN
    SET @CurrentLevel += 1;
    INSERT INTO @EmployeeHierarchy([EmployeeId],[ManagerId],[OrgLevel],[HierarchyPath])
    SELECT E.[EmployeeId], E.[ManagerId], @CurrentLevel, H.[HierarchyPath] + '.' + FORMAT(E.EmployeeId, '00000')
    FROM @EmployeeManager AS E
    JOIN @EmployeeHierarchy AS H
        ON E.[ManagerId] = H.[EmployeeId]
            AND H.[OrgLevel] = (@CurrentLevel -1);
END
SELECT [Employee OrgChart] = REPLICATE('|   ', [OrgLevel]) + P.[FirstName] + ' ' + P.[LastName] + ', ' + E.[JobTitle]
FROM @EmployeeHierarchy AS H
JOIN [Person].[Person] AS P
    ON H.EmployeeId = P.BusinessEntityID
JOIN [HumanResources].[Employee] AS E
    ON H.EmployeeId = E.BusinessEntityID
ORDER BY HierarchyPath;
GO

/*
* Write a function to calculate the margin of an order.
* The function takes SalesOrderId as the single argument.
* The function returns the calculated margin as a MONEY type value.
* Assume cost doesn't change, and use the StandardCost value in Production.Product.
* Margin expression: SUM([LineTotal]) - SUM([OrderQty]*[StandardCost])
* If there is no order that matches the argument, return NULL.
* If the argument is NULL, return NULL.
*
* Test
    DECLARE @TestOrders TABLE([SalesOrderID] INT);
    INSERT INTO @TestOrders([SalesOrderID])
    VALUES (NULL), (0), (43659), (43660);
    SELECT [SalesOrderID], [dbo].[OrderMargin]([SalesOrderID]) AS [OrderMargin]
    FROM @TestOrders;
*
* Result Key
*
*   SalesOrderID    OrderMargin
*   ------------    -----------
*   NULL            NULL
*   0               NULL
*   43659           1273.8398
*   43660           -77.162
*/

IF OBJECT_ID(N'dbo.OrderMargin') IS NOT NULL
BEGIN
    DROP FUNCTION [dbo].[OrderMargin];
END
GO

CREATE FUNCTION [dbo].[OrderMargin] (@SalesOrderId INT) RETURNS MONEY WITH RETURNS NULL ON NULL INPUT AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM [Sales].[SalesOrderHeader] WHERE [SalesOrderID] = @SalesOrderId) RETURN NULL
    DECLARE @Profit MONEY = (
        SELECT CAST(SUM(T2.[LineTotal]) - SUM(T2.[OrderQty] * T1.[StandardCost]) AS MONEY)
        FROM [Production].[Product] AS T1, [Sales].[SalesOrderDetail] AS T2
        WHERE T1.[ProductID] = T2.[ProductID]
            AND T2.[SalesOrderID] = @SalesOrderId
    );
    RETURN @Profit;
END
GO

/*
* Create a function that returns the DATEPART of a date from a string that matches all or part of the DATEPART argument.
* For the valid DATEPARTs see: https://docs.microsoft.com/en-us/sql/t-sql/functions/datepart-transact-sql
* NOTE: Implement: Year; Quarter; Month; Week; Day.
* If any argument is NULL, return NULL.
* Returns an integer value that represents the date part according to the DATEPART function.
* The DATEPART function cannot take a variable as first argument.
* The need for this function comes from the following code snippet:
    DECLARE @Part NVARCHAR(12) = 'MONTH'
    SELECT DATEPART(@Part, sysdatetime());
*   Msg 1023, Level 15, State 1, Line 3
*   Invalid parameter 1 specified for datepart.
*
* Test
    DECLARE @TestDates TABLE([D] DATE);
    DECLARE @DateParts TABLE([DatePart] NVARCHAR(12));
    INSERT INTO @TestDates([D])
    VALUES ('3141-5-9'), ('1011-12-13');
    
    INSERT INTO @DateParts([DatePart])
    VALUES ('Y'), ('Q'), ('M'), ('W'), ('D');
    SELECT [D], [DatePart] AS [Date part string], [dbo].DatePartFromString([DatePart], [D]) AS [Date part number]
    FROM @TestDates CROSS JOIN @DateParts
    ORDER BY D, [DatePart];
* Result Key
*   D           Date part string    Date part number
*   ----------  ----------------    ----------------
*   1011-12-13  D                   13
*   1011-12-13  M                   12
*   1011-12-13  Q                   4
*   1011-12-13  W                   50
*   1011-12-13  Y                   1011
*   3141-05-09  D                   9
*   3141-05-09  M                   5
*   3141-05-09  Q                   2
*   3141-05-09  W                   19
*   3141-05-09  Y                   3141
*/

IF OBJECT_ID(N'dbo.DatePartFromString') IS NOT NULL
BEGIN
    DROP FUNCTION [dbo].[DatePartFromString];
END
GO
CREATE FUNCTION [dbo].[DatePartFromString] (@DatePart NVARCHAR(12), @Date DATE) RETURNS INT AS
BEGIN
    IF @DatePart IS NULL OR @Date IS NULL
    BEGIN
        RETURN NULL
    END
    DECLARE @Part INT = (
        CASE WHEN 'Year' LIKE @DatePart + '%' THEN DATEPART(YEAR, @Date)
        WHEN 'Quarter' LIKE @DatePart + '%' THEN DATEPART(QUARTER, @Date)
        WHEN 'Month' LIKE @DatePart + '%' THEN DATEPART(MONTH, @Date)
        WHEN 'Week' LIKE @DatePart + '%' THEN DATEPART(WEEK, @Date)
        WHEN 'Day' LIKE @DatePart + '%' THEN DATEPART(DAY, @Date)
        ELSE NULL
        END
    );
    RETURN @Part;
END
GO

/*
* Create a function that returns the start and end dates of a period for a given date.
* Period argument is a string that matches all or part of: Year, Quarter, Month, Week, Day.
* If any argument is NULL, return NULL for both StartDate and EndDate columns.
*
* Test
*
*   -- DECLARE @Date DATE = '1752-01-01' -- Microsoft does not assume adoption of Gregorian calendar in the U.S. on this date.
*   -- DECLARE @Date DATE = '1753-01-01' -- Microsoft assumes adoption of Gregorian calendar in the U.S. on and after this date.
    DECLARE @TestDates TABLE ([D] DATE);
    DECLARE @DateParts TABLE ([DatePart] NVARCHAR(12));
    INSERT INTO @TestDates ([D])
    VALUES ('3141-5-9'), ('1011-12-13');
    
    INSERT INTO @DateParts ([DatePart])
    VALUES ('Y'), ('Q'), ('M'), ('W'), ('D');
    SELECT [D], [DatePart] AS [Date part string], P.[StartDate], P.[EndDate]
    FROM @TestDates
    CROSS JOIN @DateParts
    CROSS APPLY [dbo].[GetPeriodRange]([Datepart], [D]) AS P
    ORDER BY [D], [DatePart];
    GO
* Result Key
*   D           Date part string    StartDate   EndDate
*   ----------  ----------------    ----------  -------
*   1011-12-13  D                   1011-12-13  1011-12-13
*   1011-12-13  M                   1011-12-01  1011-12-31
*   1011-12-13  Q                   1011-10-01  1011-12-31
*   1011-12-13  W                   1011-12-08  1011-12-14
*   1011-12-13  Y                   1011-01-01  1011-12-31
*   3141-05-09  D                   3141-05-09  3141-05-09
*   3141-05-09  M                   3141-05-01  3141-05-31
*   3141-05-09  Q                   3141-04-01  3141-06-30
*   3141-05-09  W                   3141-05-04  3141-05-10
*   3141-05-09  Y                   3141-01-01  3141-12-31
*/

IF OBJECT_ID(N'dbo.GetPeriodRange') IS NOT NULL
    DROP FUNCTION [dbo].[GetPeriodRange];
GO
CREATE FUNCTION [dbo].[GetPeriodRange] (@DatePart NVARCHAR(12), @Date DATE) RETURNS @PeriodRange TABLE (StartDate DATE, EndDate DATE) AS
BEGIN
    IF @DatePart IS NULL OR @Date IS NULL
    BEGIN
        INSERT INTO @PeriodRange
        VALUES (NULL, NULL);
    END
    ELSE
        INSERT INTO @PeriodRange
        SELECT CASE WHEN 'YEAR' LIKE @DatePart + '%' THEN DATEFROMPARTS(DATEPART(YEAR, @Date), 1, 1)
            WHEN 'Quarter' LIKE @DatePart + '%' THEN DATEFROMPARTS(DATEPART(YEAR, @Date), (DATEPART(Quarter, @Date) - 1) * 3 + 1, 1)
            WHEN 'Month' LIKE @DatePart + '%' THEN DATEFROMPARTS(DATEPART(YEAR, @Date), DATEPART(Month, @Date), 1)
            WHEN 'Week' LIKE @DatePart + '%' THEN DATEADD(DAY, - DATEPART(WEEKDAY, @Date) + 1, @Date)
            WHEN 'Day' LIKE @DatePart + '%' THEN @Date
            ELSE NULL
            END AS [StartDate]
            , CASE WHEN 'YEAR' LIKE @DatePart + '%' THEN DATEFROMPARTS(DATEPART(YEAR, @Date), 12, 31)
            WHEN 'Quarter' LIKE @DatePart + '%' THEN EOMONTH(DATEFROMPARTS(DATEPART(YEAR, @Date), (DATEPART(Quarter, @Date) - 1) * 3 + 3, 1))
            WHEN 'Month' LIKE @DatePart + '%' THEN EOMONTH(@Date)
            WHEN 'Week' LIKE @DatePart + '%' THEN DATEADD(DAY, 7 - DATEPART(WEEKDAY, @Date), @Date)
            WHEN 'Day' LIKE @DatePart + '%' THEN @Date
            ELSE NULL
            END AS [EndDate]
        RETURN
END
GO

/*
* Create a function that checks if there are enough items of a ProductId to fulfill an order of N items (quantity).
* If any argument is NULL, return NULL.
* If the ProductId doesn't exist, return NULL.
* If the requested quantity is negative, return NULL.
* If there are enough items to fulfill order return 1; otherwise, return 0.
*
* Test
*
    DECLARE @RequestedProducts TABLE ([P] INT);
    DECLARE @RequestedQuantity TABLE ([Q] INT);
    INSERT INTO @RequestedProducts (P)
    VALUES (5), (7), (680), (717), (853), (882), (860), (842);
    INSERT INTO @RequestedQuantity (Q)
    VALUES (-1), (5), (50), (500);
    WITH InventorySummary AS (
        SELECT P.[ProductID], SUM([Quantity]) AS [Available Qty]
        FROM [Production].[Product] P
        INNER JOIN [Production].[ProductInventory] I
            ON P.[ProductID] = I.[ProductID]
        GROUP BY P.[ProductID]
    )
    SELECT T.[P] AS [Requested Product]
        , I.[ProductID]
        , Q.[Q] AS [Requested Quantity]
        , I.[Available Qty]
        , [dbo].[TestInventory](T.[P], Q.[Q]) AS [Enough Inventory]
    FROM @RequestedQuantity Q
    CROSS JOIN @RequestedProducts T
    LEFT JOIN [InventorySummary] I
        ON T.[P] = I.[ProductID]
    ORDER BY T.[P], Q.[Q];
    GO
*   Requested Product   ProductID   Requested Quantity  Available Qty   Enough Inventory
*   -----------------   ----------- ------------------  -------------   ----------------
*   5                   NULL        -1                  NULL            NULL
*   5                   NULL        5                   NULL            NULL
*   5                   NULL        50                  NULL            NULL
*   5                   NULL        500                 NULL            NULL
*   7                   NULL        -1                  NULL            NULL
*   7                   NULL        5                   NULL            NULL
*   7                   NULL        50                  NULL            NULL
*   7                   NULL        500                 NULL            NULL
*   680                 NULL        -1                  NULL            NULL
*   680                 NULL        5                   NULL            0
*   680                 NULL        50                  NULL            0
*   680                 NULL        500                 NULL            0
*   717                 NULL        -1                  NULL            NULL
*   717                 NULL        5                   NULL            0
*   717                 NULL        50                  NULL            0
*   717                 NULL        500                 NULL            0
*   842                 842         -1                  72              NULL
*   842                 842         5                   72              1
*   842                 842         50                  72              1
*   842                 842         500                 72              0
*   853                 853         -1                  0               NULL
*   853                 853         5                   0               0
*   853                 853         50                  0               0
*   853                 853         500                 0               0
*   860                 860         -1                  36              NULL
*   860                 860         5                   36              1
*   860                 860         50                  36              0
*   860                 860         500                 36              0
*   882                 882         -1                  0               NULL
*   882                 882         5                   0               0
*   882                 882         50                  0               0
*   882                 882         500                 0               0
*/

IF OBJECT_ID(N'dbo.TestInventory') IS NOT NULL
    DROP FUNCTION [dbo].[TestInventory];
GO
CREATE FUNCTION [dbo].[TestInventory] (@ProductID INT, @Quality INT) RETURNS BIT AS
BEGIN
    IF (@ProductID IS NULL OR @Quality IS NULL OR NOT EXISTS (SELECT 1 FROM [Production].[Product] WHERE [ProductID] = @ProductID) OR @Quality < 0) RETURN NULL
    BEGIN
        DECLARE @Available INT = (SELECT SUM([Quantity]) FROM [Production].[ProductInventory] WHERE [ProductID] = @ProductID);
        RETURN CASE WHEN @Available = @Quality THEN 1 ELSE 0 END
    END
END
GO

/*
* Create a stored procedure that returns the top N products sold during the specified period of time, around given date.
* Periods of time are: All, Year, Quarter, Month, Week, Day.
*
* Test
    EXECUTE [dbo].[TopNProductsInPeriod] @TopN=7, @Period='Y', @Date='2012-5-9';
*/

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_SCHEMA = N'dbo' AND SPECIFIC_NAME = N'TopNProductsInPeriod')
BEGIN
    DROP PROCEDURE [dbo].[TopNProductsInPeriod];
END
GO
CREATE PROCEDURE [dbo].[TopNProductsInPeriod] @TopN INT, @Period NVARCHAR(12), @Date DATE AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON;
    DECLARE @StartDate DATE, @EndDate DATE;
    SELECT @StartDate = R.[StartDate], @EndDate = R.[EndDate]
    FROM [dbo].[GetPeriodRange](@Period, @Date) AS R;
    ;WITH [TopNProducts] AS (
        SELECT TOP (@TopN) T1.[ProductID], SUM(T1.[LineTotal]) AS [Sales Total]
        FROM [Sales].[SalesOrderDetail] AS T1, [Sales].[SalesOrderHeader] AS T2
        WHERE T1.[SalesOrderID] = T2.[SalesOrderID]
            AND CAST(T2.[OrderDate] AS DATE) BETWEEN @StartDate
            AND @EndDate
        GROUP BY T1.[ProductID]
        ORDER BY SUM(T1.[LineTotal]) DESC
    )
    SELECT *
    FROM [Production].[Product] AS P, [TopNProducts] AS T
    WHERE P.[ProductID] = T.[ProductID];
END
GO

/*
* Create a stored procedure to insert a detail line in [dbo].[SalesOrderDetail], for a given order.
* Validate the requested quantity of product is available in inventory.
* Use list price value, in product information, as the unit price.
* Use return code -1 to indicate not enough inventory
* Use return code 0 to indicate detail inserted; there is enough inventory.
*
* Test
    DECLARE @RC INT
    DECLARE @ReturnValues TABLE (RC INT, Meaning NVARCHAR(120))
    INSERT INTO @ReturnValues (RC, Meaning)
    VALUES (0, 'Success'), (- 1, 'No enough inventory'), (- 2, 'Product doesn''t exist'), (- 3, 'Order doesn''t exist'), (- 4, 'Duplicate product detail')
    BEGIN TRANSACTION
    EXEC @RC = [dbo].[InsertSalesOrderDetail] @OrderID = 43663
        , @ProductID = 860
        , @OrderQty = 20
    SELECT [Meaning] [ResultCode]
    FROM @ReturnValues
    WHERE RC = @RC
    EXEC @RC = [dbo].[InsertSalesOrderDetail] @OrderID = 43669
        , @ProductID = 860
        , @OrderQty = 20
    SELECT [Meaning] [ResultCode]
    FROM @ReturnValues
    WHERE RC = @RC
    EXEC @RC = [dbo].[InsertSalesOrderDetail] @OrderID = 43674
        , @ProductID = 101
        , @OrderQty = 20
    SELECT [Meaning] [ResultCode]
    FROM @ReturnValues
    WHERE RC = @RC
    EXEC @RC = [dbo].[InsertSalesOrderDetail] @OrderID = 43658
        , @ProductID = 379
        , @OrderQty = 20
    SELECT [Meaning] [ResultCode]
    FROM @ReturnValues
    WHERE RC = @RC
    ROLLBACK
*/

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_SCHEMA = N'dbo' AND SPECIFIC_NAME = N'InsertSalesOrderDetail')
BEGIN
    DROP PROCEDURE [dbo].[InsertSalesOrderDetail];
END 
GO

CREATE PROCEDURE [dbo].[InsertSalesOrderDetail] @OrderID INT
        , @ProductID INT
        , @OrderQty INT
        , @UnitPriceDiscount MONEY = 0.00
        , @CarrierTrackingNumber NVARCHAR(25) = NULL
        , @SpecialOfferID INT = 1 AS
    DECLARE @ModifiedDate DATETIME = GETDATE()
        , @QunatityAtLocation INT
        , @LocationID SMALLINT
        , @UnitPrice MONEY = (SELECT [ListPrice] FROM [Production].[Product] WHERE [ProductID] = @ProductID)
        , @Availability INT = (SELECT SUM([Quantity]) FROM [Production].[ProductInventory] WHERE [ProductID] = @ProductID);
    IF @Availability < @OrderQty
        RETURN - 1
    IF @UnitPrice IS NULL
        RETURN - 2
    IF NOT EXISTS (SELECT 1 FROM [Sales].[SalesOrderHeader] WHERE [SalesOrderID] = @OrderID)
        RETURN - 3
    IF EXISTS (SELECT 1 FROM [Sales].[SalesOrderDetail] WHERE [SalesOrderID] = @OrderID AND [ProductID] = @ProductID)
        RETURN - 4
    BEGIN TRANSACTION
        INSERT INTO [Sales].[SalesOrderDetail] (
            [SalesOrderID]
            , [CarrierTrackingNumber]
            , [OrderQty]
            , [ProductID]
            , [SpecialOfferID]
            , [UnitPrice]
            , [UnitPriceDiscount]
            , [rowguid]
            , [ModifiedDate]
        )
        VALUES (
            @OrderID
            , @CarrierTrackingNumber
            , @OrderQty
            , @ProductID
            , @SpecialOfferID
            , @UnitPrice
            , @UnitPriceDiscount
            , NEWID()
            , @ModifiedDate
        )
        WHILE @OrderQty > 0
        BEGIN
            SELECT TOP 1 @QunatityAtLocation = [Quantity], @LocationID = [LocationID]
            FROM [Production].[ProductInventory]
            WHERE [ProductID] = @ProductID
            ORDER BY [Quantity] DESC;
            IF @QunatityAtLocation >= @OrderQty
            BEGIN
                UPDATE [Production].[ProductInventory]
                SET [Quantity] -= @OrderQty
                WHERE [ProductID] = @ProductID
                    AND [LocationID] = @LocationID;
                SET @OrderQty = 0;
            END
            ELSE
            BEGIN
                UPDATE [Production].[ProductInventory]
                SET [Quantity] = 0
                WHERE [ProductID] = @ProductID
                    AND [LocationID] = @LocationID;
                SET @OrderQty -= @QunatityAtLocation;
            END
        END
    COMMIT
    RETURN 0
    GO
    SET NOCOUNT, XACT_ABORT ON
    GO

/*
* Write a stored procedure that updates the cost value of a product, as a percental change, when you are given:
* > The cost change as a percent of increment
* > a table variable with Product Ids
* > a table variable with Product Sub-Category Ids (understanding that all products under those Sub-Categories are to be updated)
* > a table variable with Category Ids (understanding that all products under those Categories are to be updated)
*
* !! Business Rules !!
* + Existing cost information must be archived in ProductCostHIstory table
* + Existing open cost history needs to be properly closed
* + All records need to be stamped with modified date
* > Handle the case when all table variables are correctly defined, but might not have rows in them 
* > Make the stored precedure in such way that it can recover from errors; no changes are final, until the entire operation is successful.
*
* Test
    DECLARE @ProductIdInput [IdsType];
    DECLARE @ProductSubcategoryIdInput [IdsType];
    DECLARE @ProductCategoryIdInput [IdsType];
    DECLARE @CostChange decimal(5,2);
    --! Assume the user is giving you the all of following input
    --! [ProductID]s: 1, 3, 317
    --! [ProductSubcategoryID]s: 7, 11, 13
    --! [ProductCategoryID]s: 1, 4
    --! Cost Change: 5.5 (as percent)
    INSERT INTO @ProductIdInput(Id)
    VALUES (1), (3), (317);
    INSERT INTO @ProductSubcategoryIDInput (Id)
    VALUES (7), (11);
    INSERT INTO @ProductCategoryIDInput (Id)
    VALUES (4);
    SET @CostChange = 5.5;
    BEGIN TRAN
    EXECUTE [dbo].[UpdateCost] @ProductIdInput, @ProductSubcategoryIdInput, @ProductCategoryIdInput, @CostChange
    ROLLBACK
    GO
*/

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_SCHEMA = N'dbo' AND SPECIFIC_NAME = N'UpdateCost')
BEGIN
    DROP PROCEDURE [dbo].[UpdateCost];
END 
GO
    
DROP TYPE IF EXISTS [dbo].[IdsType];
GO
    
CREATE TYPE [dbo].[IdsType] AS TABLE ([Id] INT NOT NULL);
GO
CREATE PROCEDURE [dbo].[UpdateCost]
    @ProductIdInput [IdsType] READONLY
    , @ProductSubcategoryIdInput [IdsType] READONLY
    , @ProductCategoryIdInput [IdsType] READONLY
    , @CostChange DECIMAL(5, 2) AS
BEGIN
    DECLARE @ModifiedDate DATETIME = GETDATE();
    DECLARE @LastProductCostHistory TABLE ([ProductID] INT NOT NULL, [StartDate] DATETIME NULL);
    DECLARE @ProductIdToUpdate TABLE ([ProductID] INT NOT NULL, [OldStartDate] DATETIME NULL, [OldStandardCost] MONEY NULL);
    -- Last entry in Cost History
    INSERT INTO @LastProductCostHistory ([ProductID], [StartDate])
    SELECT [ProductID], MAX([StartDate]) AS [LatestStartDate]
    FROM [Production].[ProductCostHistory]
    GROUP BY [ProductID];
    -- Update Transaction
    INSERT INTO @ProductIdToUpdate ([ProductID], [OldStartDate], [OldStandardCost])
    SELECT [PI].[Id], CH.[StartDate], P.[StandardCost]
    FROM @ProductIdInput AS [PI]
    INNER JOIN [Production].[Product] AS P
        ON [PI].[Id] = P.[ProductID]
    LEFT JOIN @LastProductCostHistory AS CH
        ON CH.[ProductID] = [PI].[Id];
    INSERT INTO @ProductIdToUpdate ([ProductID], [OldStartDate], [OldStandardCost])
    SELECT [PI].[ProductID], CH.[StartDate], P.[StandardCost]
    FROM (SELECT P1.[ProductID]
        FROM @ProductSubcategoryIdInput AS SC, [Production].[Product] AS P1
        WHERE SC.[Id] = P1.[ProductSubcategoryID]) AS [PI]
        INNER JOIN [Production].[Product] AS P
            ON [PI].ProductID = P.[ProductID]
        LEFT JOIN @LastProductCostHistory AS CH
            ON CH.[ProductID] = [PI].[ProductID];
        INSERT INTO @ProductIdToUpdate ([ProductID], [OldStartDate], [OldStandardCost]
    )
        SELECT [PI].[ProductID], CH.[StartDate], P.[StandardCost]
        FROM (SELECT P1.[ProductID]
            FROM @ProductCategoryIdInput AS C, [Production].[ProductSubcategory] AS SC, [Production].[Product] AS P1
            WHERE SC.[ProductSubcategoryID] = C.[Id]
                AND SC.[ProductSubcategoryID] = P1.[ProductSubcategoryID]
        ) AS [PI]
        INNER JOIN [Production].[Product] AS P
            ON [PI].[ProductID] = P.[ProductID]
        LEFT JOIN @LastProductCostHistory AS CH
            ON CH.[ProductID] = [PI].[ProductID];
        BEGIN TRANSACTION
        UPDATE [H]
        SET [H].[EndDate] = @ModifiedDate, [H].[ModifiedDate] = @ModifiedDate
        FROM [Production].[ProductCostHistory] AS [H], @ProductIdToUpdate AS [U]
        WHERE U.[ProductID] = H.[ProductID]
            AND U.[OldStartDate] = H.[StartDate];
        INSERT INTO [Production].[ProductCostHistory] ([ProductID], [StartDate], [EndDate], [StandardCost], [ModifiedDate])
        SELECT [ProductID], @ModifiedDate, NULL, (1 + @CostChange / 100.0) * [OldStandardCost], @ModifiedDate
        FROM @ProductIdToUpdate;
        UPDATE [P]
        SET P.[StandardCost] *= (1 + @CostChange / 100.0), P.[ModifiedDate] = @ModifiedDate
        FROM [Production].[Product] AS P, @ProductIdToUpdate AS U
        WHERE U.[ProductID] = P.[ProductID];
        COMMIT
        SELECT C.[ProductCategoryID]
            , S.[ProductSubcategoryID]
            , P.[ProductID]
            , P.[StandardCost]
            , U.[OldStandardCost]
            , @ModifiedDate AS [CostStartDate]
            , U.[OldStartDate] AS [CostOldStartDate]
            , P.[ModifiedDate]
        FROM [Production].[Product] AS P
        INNER JOIN @ProductIdToUpdate AS U
            ON U.[ProductID] = P.[ProductID]
        LEFT JOIN [Production].[ProductSubcategory] AS S
            ON S.[ProductSubCategoryID] = P.[ProductSubcategoryID]
        LEFT JOIN [Production].[ProductCategory] AS C
            ON C.[ProductCategoryID] = S.[ProductCategoryID]
        ORDER BY C.[ProductCategoryID]
            , S.[ProductSubcategoryID]
            , P.[ProductID];
END
GO
