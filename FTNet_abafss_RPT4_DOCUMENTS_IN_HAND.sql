CREATE OR ALTER PROCEDURE FTNET_ABAFSS_RPT4_DOCUMENTS_IN_HAND @division VARCHAR(15)
AS

BEGIN

	SELECT 

		OuterQuery.Division AS Division,
		OuterQuery.APSS_ACCOUNTING_TEAM AS APSS_Accounting_Team,
		OuterQuery.PAYMENT_DONE AS Payment_Done,
		OuterQuery.WIP AS WIP,
		(OuterQuery.APSS_ACCOUNTING_TEAM + OuterQuery.PAYMENT_DONE + OuterQuery.WIP) AS Total

	FROM
		(SELECT 

			BaseQuery.Division AS Division,

			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.Current_Loc = 2) AS APSS_ACCOUNTING_TEAM,

			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.Current_Loc = 24) AS PAYMENT_DONE,

			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.Current_Loc NOT IN (2,24)) AS WIP,

			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.Current_Loc = 7) AS HOF,

			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.Current_Loc = 8) AS CMO,

			(SELECT COUNT(i.ItemID) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND i.MediaID IN (32,33,34)) AS Debit_Note
		
		FROM
			(SELECT DISTINCT Level1Name AS Division, Level1ID AS DivisionID
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			INNER JOIN MasterList ml ON ml.Level1ID = id.vNumber
			WHERE id.FieldID = 54 
			AND id.vNumber = (SELECT DISTINCT Level1ID FROM MasterList ml WHERE ml.Level1Name = @division)) AS BaseQuery) AS OuterQuery;

END
GO

EXEC FTNET_ABAFSS_RPT4_DOCUMENTS_IN_HAND 'ABAL';