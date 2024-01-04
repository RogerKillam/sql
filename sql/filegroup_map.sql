USE database_target
GO

SELECT table_name = tbl.name
	, CASE WHEN dsidx.type = 'FG' THEN dsidx.name ELSE '(Partitioned)' END AS file_group
FROM sys.tables AS tbl
INNER JOIN sys.indexes AS idx
	ON idx.object_id = tbl.object_id
        AND idx.index_id <= 1
LEFT JOIN sys.data_spaces AS dsidx
    ON dsidx.data_space_id = idx.data_space_id
ORDER BY file_group, table_name;
GO
