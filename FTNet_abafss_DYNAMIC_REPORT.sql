CREATE OR ALTER PROCEDURE FTNet_abafss_DYNAMIC_REPORT @division VARCHAR(15), @month INT, @year INT
AS
BEGIN

SELECT 
		BaseQuery.ItemID,

		--Media type
		(SELECT ValueName FROM Lookup_Value lv INNER JOIN Item i ON i.MediaID = lv.ValueID WHERE i.ItemID = BaseQuery.ItemID) AS Media,

		--Barcode of document
		(CASE 
			WHEN BaseQuery.MediaID IN (29,30,31) THEN (SELECT vText FROM Item_Data WHERE FieldID = 64 AND ItemID = BaseQuery.ItemID)
			WHEN BaseQuery.MediaID IN (32,33,34) THEN (SELECT vText FROM Item_Data WHERE FieldID = 68 AND ItemID = BaseQuery.ItemID)
			WHEN BaseQuery.MediaID IN (5,24,25) THEN (SELECT vText FROM Item_Data WHERE FieldID = 35 AND ItemID = BaseQuery.ItemID)
			WHEN BaseQuery.MediaID IN (35) THEN (SELECT vText FROM Item_Data WHERE FieldID = 76 AND ItemID = BaseQuery.ItemID)
			WHEN BaseQuery.MediaID IN (28,6) THEN (SELECT vText FROM Item_Data WHERE FieldID = 90 AND ItemID = BaseQuery.ItemID)
		END) AS Barcode,

		--Current location of each document differs according to the Current_Type field
		--Location of -> (Item)
		--Here also container is treated as a location so query will only check for one level of container nesting
		--e.g. Location of -> (Container(Item)) 
		(CASE
			WHEN BaseQuery.CurrentType = 6 
			THEN (SELECT pl.PlaceName FROM Place pl WHERE pl.PlaceId = BaseQuery.CurrentLoc)
			
			WHEN BaseQuery.CurrentType = 1 --container nesting
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
					(SELECT i.Current_Type AS CurrentType, i.Current_Loc AS CurrentLoc FROM Item i WHERE i.ItemID = BaseQuery.CurrentLoc) AS Container)
			
			WHEN BaseQuery.CurrentType = 2
			THEN (SELECT u.FirstName FROM Users u WHERE u.UserID = BaseQuery.CurrentLoc)
			WHEN BaseQuery.CurrentType = 4
			THEN (SELECT lv.ValueName FROM Lookup_Value lv WHERE lv.ValueID = BaseQuery.CurrentLoc)
			WHEN BaseQuery.CurrentType = 120 
			THEN 'Permanently Removed'
		END) AS CurrentLocation,
		
		--Creation Date
		(SELECT CAST(DAY(CreatedDate) AS VARCHAR) + '/' + 
		 CAST(Month(CreatedDate) AS VARCHAR) + '/' +
		 CAST(Year(CreatedDate) AS VARCHAR)
		 FROM Item WHERE ItemID = BaseQuery.ItemID) AS CreationDate,

		--Checkout dates of an document
		ISNULL((SELECT 
			STRING_AGG(
				CAST(DAY(hi.Current_Date_FT) AS VARCHAR) + '/' + 
				CAST(MONTH(hi.Current_Date_FT) AS VARCHAR) + '/' +
				CAST(YEAR(hi.Current_Date_FT) AS VARCHAR), '->') AS Dates
		 FROM Hist_Item hi 
		 WHERE hi.ItemID = BaseQuery.ItemID AND hi.TransactionType = 1
		), 'N.A.') AS CheckOut_Dates,

		--Checking if container has been changed, if so then fetching checkout dates afterwards
		--Some documents have changed container more than once
		--Query is considering only first container change event so will show only it's checkout dates 
		(CASE 
			WHEN 
				 EXISTS (SELECT Current_Loc, Current_Date_FT 
				 FROM Hist_Item 
				 WHERE ItemID = BaseQuery.ItemID AND TransactionType = 33 
				 ORDER BY Current_Date_FT ASC
				 OFFSET 0 ROW
				 FETCH NEXT 1 ROW ONLY) 
			THEN 
				(SELECT
					 STRING_AGG(
						CAST(DAY(hi.Current_Date_FT) AS VARCHAR) + '/' + 
						CAST(MONTH(hi.Current_Date_FT) AS VARCHAR) + '/' +
						CAST(YEAR(hi.Current_Date_FT) AS VARCHAR), '->') AS Dates
					 FROM Hist_Item hi 
					 WHERE hi.ItemID = 
						 (SELECT Current_Loc 
						  FROM 
							(SELECT Current_Loc, Current_Date_FT 
							 FROM Hist_Item 
							 WHERE ItemID = BaseQuery.ItemID AND TransactionType = 33 
							 ORDER BY Current_Date_FT ASC
							 OFFSET 0 ROW
							 FETCH NEXT 1 ROW ONLY) 
						  AS Container))
			ELSE 'N.A.'
			END) AS CheckOut_Dates_Container_Change
FROM
	--This is base query which filters items based on primary criteria
	--The data fetched by this select will be used by the outer query
	--to get necessary columns one by one
	(SELECT 
	 DISTINCT id.ItemID AS ItemID, i.MediaID AS MediaID, i.Current_Type AS CurrentType, i.Current_Loc AS CurrentLoc
	 FROM Item_Data id
	 INNER JOIN MasterList ml ON ml.Level1ID = id.vNumber
	 INNER JOIN Item i ON i.ItemID = id.ItemID
	 WHERE id.FieldID = 54 
	 AND id.vNumber = (SELECT DISTINCT Level1ID FROM MasterList WHERE Level1Name = @division)
	 AND MONTH(i.CreatedDate) = @month 
	 AND YEAR(i.CreatedDate) = @year) AS BaseQuery

END
GO

/*Arguments - Division,Month,Year*/
exec FTNet_abafss_DYNAMIC_REPORT 'abal', 03, 2023;
