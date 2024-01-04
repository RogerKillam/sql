DECLARE @JSON NVARCHAR(MAX);

SET @JSON = N'{
                "isUnitLimitExceeded": false,
                   "maximumAllowedUnits": 100,
                   "aggregation": "Day",
                   "categoryLabels": [
                       {
                           "index": 20210225,
                           "indexLabel": "20210225",
                           "displayLabel": "2021-02-25"
                       }
                   ],
                   "dataSets": [
                       {
                           "name": "TRIP_DISTANCE",
                           "unit": "m",
                           "data": [ 
                               22.36
                            ]
                    }
                   ]
               }
           ';

--INSERT INTO [TestDB].[dbo].[sampleTable]
SELECT test.*
FROM OPENJSON(@JSON, N'$') WITH (
	[Date] DATE '$.categoryLabels[0].displayLabel'
     , [TripDistanceMiles] VARCHAR(50) '$.dataSets[0].data[0]'
) AS test;
GO
