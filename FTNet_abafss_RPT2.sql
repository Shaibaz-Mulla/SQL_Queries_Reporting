CREATE OR ALTER PROCEDURE FTNET_ABAFSS_RPT2 @month INT, @year INT
AS

BEGIN

		(SELECT 

			BaseQuery.Division AS Division,

			(SELECT COUNT(*) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND MONTH(i.CreatedDate) = @month
            AND YEAR(i.CreatedDate) = @year) AS Documents_Created,

            (SELECT DISTINCT COUNT(*) 
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
            INNER JOIN Hist_Item hi ON hi.ItemID = id.ItemID
			WHERE id.FieldID = 54
			AND id.vNumber = BaseQuery.DivisionID
			AND MONTH(hi.Current_Date_FT) = @month
            AND YEAR(hi.Current_Date_FT) = @year
            AND hi.TransactionType = 1 
            AND hi.Current_Loc IN (2)) AS Documents_Received

		FROM
			(SELECT DISTINCT Level1Name AS Division, Level1ID AS DivisionID
			FROM Item i 
			INNER JOIN Item_Data id ON id.ItemID = i.ItemID
			INNER JOIN MasterList ml ON ml.Level1ID = id.vNumber
			WHERE id.FieldID = 54 
			AND id.vNumber IN (SELECT DISTINCT Level1ID FROM MasterList)) AS BaseQuery) 

END
GO

EXEC FTNET_ABAFSS_RPT2 3, 2023;