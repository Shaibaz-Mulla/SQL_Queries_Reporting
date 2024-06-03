CREATE OR ALTER PROCEDURE FTNET_ABAFSS_RPT4_DIVISION_WISE
AS

BEGIN

	SELECT 

		OuterQuery.Division AS Division,
		OuterQuery.APSS_Accounting_Team AS APSS_Accounting_Team,
		OuterQuery.Payment_Done AS Payment_Done,
		OuterQuery.WIP AS Others,
		(OuterQuery.APSS_Accounting_Team + OuterQuery.Payment_Done + OuterQuery.WIP) AS Total

	FROM
		(SELECT 

			BaseQuery.Division AS Division,

			(SELECT COUNT(*) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.Current_Loc = 2) AS APSS_Accounting_Team,

			(SELECT COUNT(*) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.Current_Loc = 24) AS Payment_Done,

			(SELECT COUNT(*) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.Current_Loc NOT IN (2,24)) AS WIP
		
		FROM
			(SELECT DISTINCT Level1Name AS Division, Level1ID AS DivisionID
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			INNER JOIN MasterList ml ON ml.Level1ID = id.vNumber
			WHERE id.FieldID = 54 
			AND id.vNumber IN (SELECT DISTINCT Level1ID FROM MasterList)) AS BaseQuery) AS OuterQuery;

END
GO

EXEC FTNET_ABAFSS_RPT4_DIVISION_WISE;