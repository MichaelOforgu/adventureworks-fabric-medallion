/* ---------------------------------------------------------------------
   DimEmployee  (all employees; IsSalesPerson flags sales staff)
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimEmployee
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimEmployee', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimEmployee;

        INSERT INTO gold.DimEmployee
            (EmployeeKey, FullName, JobTitle, Department, IsSalesPerson,
             IsCurrentEmployee, TerritoryName, LoadRunId)
        VALUES (-1, 'Online / No Salesperson', 'Unknown', 'Unknown', 0, 0, 'Unknown', @RunId);

        INSERT INTO gold.DimEmployee
            (EmployeeKey, FullName, JobTitle, Department, HireDate, IsSalesPerson,
             IsCurrentEmployee, TerritoryName, LoadRunId)
        SELECT  e.BusinessEntityID,
                CONCAT_WS(' ', p.FirstName, p.MiddleName, p.LastName),
                e.JobTitle,
                ISNULL(dept.DepartmentName, 'Unknown'),
                CAST(e.HireDate AS DATE),
                CASE WHEN sp.BusinessEntityID IS NOT NULL THEN 1 ELSE 0 END,
                e.CurrentFlag,
                CASE WHEN sp.BusinessEntityID IS NULL THEN 'Not Applicable'
                     ELSE ISNULL(st.Name, 'Unassigned') END,
                @RunId
        FROM lh_silver.silver.HumanResources_Employee e
        JOIN lh_silver.silver.Person_Person p
          ON e.BusinessEntityID = p.BusinessEntityID
        LEFT JOIN (     -- current department (latest open history row)
            SELECT  edh.BusinessEntityID, d.Name AS DepartmentName,
                    ROW_NUMBER() OVER (PARTITION BY edh.BusinessEntityID
                                       ORDER BY edh.StartDate DESC) AS rn
            FROM lh_silver.silver.HumanResources_EmployeeDepartmentHistory edh
            JOIN lh_silver.silver.HumanResources_Department d
              ON edh.DepartmentID = d.DepartmentID
            WHERE edh.EndDate IS NULL
        ) dept ON dept.BusinessEntityID = e.BusinessEntityID AND dept.rn = 1
        LEFT JOIN lh_silver.silver.Sales_SalesPerson sp
               ON sp.BusinessEntityID = e.BusinessEntityID
        LEFT JOIN lh_silver.silver.Sales_SalesTerritory st
               ON sp.TerritoryID = st.TerritoryID;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;

GO