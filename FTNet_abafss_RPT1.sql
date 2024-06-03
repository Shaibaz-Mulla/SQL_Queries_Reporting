CREATE OR ALTER PROCEDURE FTNET_ABAFSS_RPT1 @division VARCHAR(15), @month INT, @year INT
AS
BEGIN

            (SELECT 

                BaseQuery.ItemID,

                (CASE
                    WHEN BaseQuery.CatID IN (4,17,18)
                    THEN (SELECT ml.Level2Name
                          FROM Item_Data id 
                          INNER JOIN MasterList ml ON id.vNumber = ml.Level2id
                          WHERE id.FieldID = 55 AND id.ItemID = BaseQuery.ItemID)
                    WHEN BaseQuery.CatID = 21
                    THEN (SELECT ml.Level2Name
                          FROM Item_Data id 
                          INNER JOIN MasterList ml ON id.vNumber = ml.Level2id
                          WHERE id.FieldID = 77 AND id.ItemID = BaseQuery.ItemID)
                    WHEN BaseQuery.CatID = 22
                    THEN (SELECT ml.Level2Name
                          FROM Item_Data id 
                          INNER JOIN MasterList ml ON id.vNumber = ml.Level2id
                          WHERE id.FieldID = 119 AND id.ItemID = BaseQuery.ItemID)
                END) AS Supplier,

                (SELECT lv.ValueName FROM Lookup_Value lv 
                 INNER JOIN Item i ON i.MediaID = lv.ValueID 
                 WHERE i.ItemID = BaseQuery.ItemID) AS Media,

                (SELECT i.CreatedDate FROM Item i 
                 WHERE i.ItemID = BaseQuery.ItemID) AS Created_Date,

                (SELECT 
                    (CASE
                        WHEN THIS.CurrentType = 6 
                        THEN (SELECT pl.PlaceName FROM Place pl WHERE pl.PlaceId = THIS.CurrentLoc)
                                
                        WHEN THIS.CurrentType = 1 --container nesting
                        THEN
                            (SELECT 
                                (CASE
                                    WHEN Container.CurrentType = 6 
                                    THEN (SELECT pl.PlaceName FROM Place pl WHERE pl.PlaceId = Container.CurrentLoc)
                                    WHEN Container.CurrentType = 1
                                    THEN 'Inside Container'
                                    WHEN Container.CurrentType = 2
                                    THEN (SELECT u.FirstName FROM Users u WHERE u.UserID = Container.CurrentLoc)
                                    WHEN Container.CurrentType = 4
                                    THEN (SELECT lv.ValueName FROM Lookup_Value lv WHERE lv.ValueID = Container.CurrentLoc)
                                    WHEN Container.CurrentType = 120 
                                    THEN 'Permanently Removed'
                                END)
                            FROM
                                (SELECT i.Current_Type AS CurrentType, i.Current_Loc AS CurrentLoc FROM Item i WHERE i.ItemID = THIS.CurrentLoc) AS Container)
                                
                        WHEN THIS.CurrentType = 2
                        THEN (SELECT u.FirstName FROM Users u WHERE u.UserID = THIS.CurrentType)
                        WHEN THIS.CurrentType = 4
                        THEN (SELECT lv.ValueName FROM Lookup_Value lv WHERE lv.ValueID = THIS.CurrentType)
                        WHEN THIS.CurrentType = 120 
                        THEN 'Permanently Removed'
                    END) AS Received_AT
                FROM
                    (SELECT
                    hi.Current_Date_FT, 
                    hi.Current_Loc AS CurrentLoc, 
                    hi.Current_Type AS CurrentType
                    FROM Hist_Item hi 
                    -- WHERE EXISTS
                    --         (SELECT * FROM Hist_Item hi
                            WHERE hi.ItemID = BaseQuery.ItemID
                            AND hi.TransactionType = 1
                    ORDER BY hi.Current_Date_FT DESC
                    OFFSET 0 ROW
                    FETCH NEXT 1 ROW ONLY) AS THIS)  AS Received_At,

                (SELECT 
                    (SELECT u.FirstName FROM Users u 
                     WHERE u.UserID = THIS.ModifiedBy)
                FROM
                    (SELECT 
                    hi.Current_Date_FT, 
                    hi.ModifiedBy
                    FROM Hist_Item hi 
                    -- WHERE EXISTS
                    --         (SELECT * FROM Hist_Item hi
                            WHERE hi.ItemID = BaseQuery.ItemID
                            AND hi.TransactionType = 1
                    ORDER BY hi.Current_Date_FT DESC
                    OFFSET 0 ROW
                    FETCH NEXT 1 ROW ONLY) AS THIS)  AS Received_By,

                    (SELECT 
                    hi.Current_Date_FT
                    FROM Hist_Item hi 
                    -- WHERE EXISTS
                    --         (SELECT * FROM Hist_Item hi
                            WHERE hi.ItemID = BaseQuery.ItemID
                            AND hi.TransactionType = 1
                    ORDER BY hi.Current_Date_FT DESC
                    OFFSET 0 ROW
                    FETCH NEXT 1 ROW ONLY) AS Received_Date

		FROM

			(SELECT 
				DISTINCT id.ItemID AS ItemID, i.CatID AS CatID, i.MediaID AS MediaID
				FROM Item_Data id
				INNER JOIN MasterList ml ON ml.Level1ID = id.vNumber
				INNER JOIN Item i ON i.ItemID = id.ItemID
				WHERE id.FieldID = 54 
			    AND id.vNumber = (SELECT DISTINCT Level1ID FROM MasterList ml WHERE ml.Level1Name = @division)
                AND MONTH(i.CreatedDate) = @month AND YEAR(i.CreatedDate) = @year) AS BaseQuery) 
                -- AS OuterQuery

END
GO


EXEC FTNET_ABAFSS_RPT1 'ABAL', 03, 2023;