CREATE OR ALTER PROCEDURE FTNET_ABAFSS_RPT5 @division VARCHAR(15), @supplier VARCHAR(255)
AS
BEGIN

	--Outer SELECT query, 
	--to hide some columns : ItemID, CatID 
	--format dates 
	--derive some columns from other columns present inside inner SELECT sub-query 
	--through their ALIAS : APSS_TAT = DATEDIFF(D,Document_Date,Banking) and HO_TAT = DATEDIFF(D,Banking,HO_Finance)
	SELECT 

		OuterQuery.itemID AS ItemID, 
		OuterQuery.Category AS Category,
		OuterQuery.Media AS Media, 
		OuterQuery.Document_# AS Document_#, 
		OuterQuery.Barcode AS Barcode, 
		
		CASE WHEN OuterQuery.Creation_Date IS NOT NULL THEN CONCAT_WS('/',DAY(OuterQuery.Creation_Date),MONTH(OuterQuery.Creation_Date),YEAR(OuterQuery.Creation_Date)) ELSE 'N.A.' END AS Creation_Date, 
		CASE WHEN OuterQuery.Accounting IS NOT NULL THEN CONCAT_WS('/',DAY(OuterQuery.Accounting),MONTH(OuterQuery.Accounting),YEAR(OuterQuery.Accounting)) ELSE 'N.A.' END AS Accounting,
		CASE WHEN OuterQuery.Payment IS NOT NULL THEN CONCAT_WS('/',DAY(OuterQuery.Payment),MONTH(OuterQuery.Payment),YEAR(OuterQuery.Payment)) ELSE 'N.A.' END AS Payment,
		CASE WHEN OuterQuery.Banking IS NOT NULL THEN CONCAT_WS('/',DAY(OuterQuery.Banking),MONTH(OuterQuery.Banking),YEAR(OuterQuery.Banking)) ELSE 'N.A.' END AS Banking,
		CASE WHEN OuterQuery.HO_Finance IS NOT NULL THEN CONCAT_WS('/',DAY(OuterQuery.HO_Finance),MONTH(OuterQuery.HO_Finance),YEAR(OuterQuery.HO_Finance)) ELSE 'N.A.' END AS HO_Finance,

		(CASE 
			WHEN OuterQuery.Creation_Date IS NOT NULL AND OuterQuery.Banking IS NOT NULL 
			THEN DATEDIFF(D,OuterQuery.Creation_Date,OuterQuery.Banking)
			ELSE 0
		END) AS APSS_TAT,

		(CASE 
			WHEN OuterQuery.Banking IS NOT NULL AND OuterQuery.HO_Finance IS NOT NULL 
			THEN DATEDIFF(D,OuterQuery.Banking,OuterQuery.HO_Finance)
			ELSE 0
		END) AS HO_TAT,

		(CASE
			WHEN OuterQuery.Creation_Date IS NOT NULL AND OuterQuery.Banking IS NOT NULL AND OuterQuery.HO_Finance IS NOT NULL 
			THEN (DATEDIFF(D,OuterQuery.Creation_Date,OuterQuery.Banking) + DATEDIFF(D,OuterQuery.Banking,OuterQuery.HO_Finance))
			WHEN OuterQuery.Creation_Date IS NOT NULL AND OuterQuery.Banking IS NOT NULL AND OuterQuery.HO_Finance IS NULL THEN DATEDIFF(D,OuterQuery.Creation_Date,OuterQuery.Banking)
			WHEN OuterQuery.Creation_Date IS NULL AND OuterQuery.Banking IS NOT NULL AND OuterQuery.HO_Finance IS NOT NULL THEN DATEDIFF(D,OuterQuery.Banking,OuterQuery.HO_Finance)
			ELSE 0
		END) AS Total_TAT

	FROM

		(SELECT 

			--This ItemID and CatID will be available to refer hereafter
			BaseQuery.ItemID AS ItemID, 
			
			(SELECT lv.ValueName FROM Lookup_Value lv WHERE lv.ValueID = BaseQuery.CatID) AS Category,
			(SELECT lv.ValueName FROM Lookup_Value lv WHERE lv.ValueID = BaseQuery.MediaID) AS Media,

			--Finding Document_# according to CatID & ItemID
			(CASE 
				WHEN BaseQuery.CatID = 18 THEN (SELECT vText FROM Item_Data WHERE FieldID = 67 AND ItemID = BaseQuery.ItemID)
				WHEN BaseQuery.CatID = 17 THEN (SELECT vText FROM Item_Data WHERE FieldID = 69 AND ItemID = BaseQuery.ItemID)
				WHEN BaseQuery.CatID = 4 THEN (SELECT vText FROM Item_Data WHERE FieldID = 56 AND ItemID = BaseQuery.ItemID)
				WHEN BaseQuery.CatID = 21 THEN (SELECT vText FROM Item_Data WHERE FieldID = 56 AND ItemID = BaseQuery.ItemID)
				WHEN BaseQuery.CatID = 22 THEN (SELECT vText FROM Item_Data WHERE FieldID = 97 AND ItemID = BaseQuery.ItemID)
				ELSE 'N.A.'
			END) AS Document_#,

			--Finding Barcode according to CatID & ItemID
			(CASE 
				WHEN BaseQuery.CatID = 18 THEN (SELECT vText FROM Item_Data WHERE FieldID = 64 AND ItemID = BaseQuery.ItemID)
				WHEN BaseQuery.CatID = 17 THEN (SELECT vText FROM Item_Data WHERE FieldID = 68 AND ItemID = BaseQuery.ItemID)
				WHEN BaseQuery.CatID = 4 THEN (SELECT vText FROM Item_Data WHERE FieldID = 35 AND ItemID = BaseQuery.ItemID)
				WHEN BaseQuery.CatID = 21 THEN (SELECT vText FROM Item_Data WHERE FieldID = 76 AND ItemID = BaseQuery.ItemID)
				WHEN BaseQuery.CatID = 22 THEN (SELECT vText FROM Item_Data WHERE FieldID = 90 AND ItemID = BaseQuery.ItemID)
			END) AS Barcode,

			--Finding Document Creation Date 
			(SELECT i.CreatedDate FROM Item i WHERE i.ItemID = BaseQuery.ItemID) AS Creation_Date,

			--Finding check-out date at Accounting Team
			--In some cases a location has more than 1 check-out date, then it is taking only the recent one
			--Also, some items are part of container where ItemID gets changed after that item is moved into container
			--This new ItemID of container will give next check-out transaction details
			ISNULL(
				(SELECT Current_Date_FT 
					FROM Hist_Item 
					WHERE ItemID = BaseQuery.ItemID 
					AND TransactionType = 1 
					AND Current_Loc = 2
					ORDER BY Current_Date_FT DESC
					OFFSET 0 ROW
					FETCH NEXT 1 ROW ONLY),
				ISNULL(
					(SELECT Current_Date_FT 
						FROM Hist_Item 
						WHERE ItemID = (SELECT Current_Loc 
										FROM Hist_Item 
										WHERE ItemID = BaseQuery.ItemID AND TransactionType = 33 
										ORDER BY Current_Loc
										OFFSET 0 ROW
										FETCH NEXT 1 ROW ONLY)
						AND TransactionType = 1 
						AND Current_Loc = 2
						ORDER BY Current_Date_FT DESC
						OFFSET 0 ROW
						FETCH NEXT 1 ROW ONLY), NULL
				)
			) AS Accounting,

			--Finding check-out date at Payment Team
			ISNULL(
				(SELECT Current_Date_FT 
					FROM Hist_Item 
					WHERE ItemID = BaseQuery.ItemID 
					AND TransactionType = 1 
					AND Current_Loc = 3
					ORDER BY Current_Date_FT DESC
					OFFSET 0 ROW
					FETCH NEXT 1 ROW ONLY),
					ISNULL(
						(SELECT Current_Date_FT 
							FROM Hist_Item 
							WHERE ItemID = (SELECT Current_Loc 
											FROM Hist_Item 
											WHERE ItemID = BaseQuery.ItemID AND TransactionType = 33
											ORDER BY Current_Loc
											OFFSET 0 ROW
											FETCH NEXT 1 ROW ONLY)
							AND TransactionType = 1 
							AND Current_Loc = 3
							ORDER BY Current_Date_FT DESC
							OFFSET 0 ROW
							FETCH NEXT 1 ROW ONLY), NULL
					)
			) AS Payment,

			--Finding check-out date at Banking Team
			ISNULL(
				(SELECT Current_Date_FT 
					FROM Hist_Item 
					WHERE ItemID = BaseQuery.ItemID 
					AND TransactionType = 1 
					AND Current_Loc = 4
					ORDER BY Current_Date_FT DESC
					OFFSET 0 ROW
					FETCH NEXT 1 ROW ONLY),
					ISNULL(
						(SELECT Current_Date_FT 
							FROM Hist_Item 
							WHERE ItemID = (SELECT Current_Loc 
											FROM Hist_Item 
											WHERE ItemID = BaseQuery.ItemID AND TransactionType = 33
											ORDER BY Current_Loc
											OFFSET 0 ROW
											FETCH NEXT 1 ROW ONLY)
							AND TransactionType = 1 
							AND Current_Loc = 4
							ORDER BY Current_Date_FT DESC
							OFFSET 0 ROW
							FETCH NEXT 1 ROW ONLY), NULL
					)
			) AS Banking,

			--Finding check-out date at HO Finance
			ISNULL(
				(SELECT Current_Date_FT 
					FROM Hist_Item 
					WHERE ItemID = BaseQuery.ItemID 
					AND TransactionType = 1 
					AND Current_Loc = 7
					ORDER BY Current_Date_FT DESC
					OFFSET 0 ROW
					FETCH NEXT 1 ROW ONLY),
					ISNULL(
						(SELECT Current_Date_FT 
						FROM Hist_Item 
						WHERE ItemID = (SELECT Current_Loc 
										FROM Hist_Item 
										WHERE ItemID = BaseQuery.ItemID AND TransactionType = 33
										ORDER BY Current_Loc
										OFFSET 0 ROW
										FETCH NEXT 1 ROW ONLY)
						AND TransactionType = 1 
						AND Current_Loc = 7
						ORDER BY Current_Date_FT DESC
						OFFSET 0 ROW
						FETCH NEXT 1 ROW ONLY), NULL
					)
			) AS HO_Finance

		FROM

			(SELECT 
				DISTINCT id.ItemID AS ItemID, i.CatID AS CatID, i.MediaID AS MediaID
				FROM Item_Data id
				INNER JOIN MasterList ml ON ml.Level1ID = id.vNumber
				INNER JOIN Item i ON i.ItemID = id.ItemID
				WHERE  
					--Various media items have different FieldID's for Division as well as Supplier Code/Name
					--Therefore using appropriate condition check
					--CatID(4,17,18) = Invoice, Debit Note, Credit Note respectively
					--CatID(21) = Others
					--CatID(22) = Payment Voucher
					(i.CatID IN (4,17,18) AND id.FieldID = 54 AND ml.Level1Name = @division AND ml.Level2Code = @supplier) OR
					(i.CatID = 21 AND id.FieldID = 54 AND ml.Level1Name = @division AND id.vText = @supplier) OR
					(i.CatID = 22 AND id.FieldID = 54 AND ml.Level1Name = @division AND id.vText = @supplier)
			) AS BaseQuery) AS OuterQuery

END
GO

--1st argument is division and the 2nd needs to be a supplier code -> This will list down Invoice, Debit Note, Credit Note
--If you want to see documents under 'Others' media category then you should pass supplier name instead of a code
--For the payment vouchers, only division is sufficient and supplier argument can be blank 
EXEC FTNET_ABAFSS_RPT5 'ABAL', '10168';