CREATE OR ALTER PROCEDURE FTNET_ABAFSS_RPT4_TOTAL_APSS @year INT
AS

BEGIN

	SELECT 

		@year AS 'Year',
		'APSS' AS Division,
		BaseQuery.APSS_Accounting_Team AS APSS_Accounting_Team,
		BaseQuery.Payment_Done AS Payment_Done,
		BaseQuery.WIP AS WIP,
		(BaseQuery.APSS_Accounting_Team + BaseQuery.Payment_Done + BaseQuery.WIP) AS Total

	FROM
		(SELECT 	
			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			WHERE YEAR(i.CreatedDate) = @year AND i.Current_Loc = 2) AS APSS_Accounting_Team,

			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			WHERE YEAR(i.CreatedDate) = @year AND i.Current_Loc = 24) AS Payment_Done,

			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			WHERE YEAR(i.CreatedDate) = @year AND i.Current_Loc NOT IN (2,24)) AS WIP) AS BaseQuery
		
END
GO

EXEC FTNET_ABAFSS_RPT4_TOTAL_APSS 2023;