-- Using Extended Events to Capture SQL Server Stored Procedure Usage
-- Reference: https://www.mssqltips.com/sqlservertip/3259/several-methods-to-collect-sql-server-stored-procedure-execution-history/
-- https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak
USE [AdventureWorks2019] -- use tager database
GO

-- Note the target database's id
SELECT DB_ID();
GO

-- Create and start a new event session
-- Note: Multiple event sessions can write to the target files (asynchronous\_file\_target)
CREATE EVENT SESSION exec_sp_AdventureWorks2019 ON SERVER
ADD EVENT sqlserver.sp_statement_completed (SET collect_object_name = (1), collect_statement = (0) ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.database_name, sqlserver.username)
WHERE ((object_type = (8272))
    AND (source_database_id = (9)))) -- edit to match the traget database id
    ADD TARGET package0.asynchronous_file_target (SET FILENAME = N'C:\db_sproc_audit\', METADATAFILE = N'C:\db_sproc_audit\'); -- edit folder path
GO

ALTER EVENT SESSION exec_sp_AdventureWorks2019 ON SERVER STATE = START
GO

SELECT * FROM sys.server_event_sessions;
GO

-- test
EXEC [dbo].[uspSearchCandidateResumes] 'test',1,1,1;
GO

;WITH ee_data AS (
    SELECT [data] = CONVERT(XML,[event_data])
    FROM sys.fn_xe_file_target_read_file('C:\db_sproc_audit\*.xel', 'C:\db_sproc_audit\*.xem', NULL, NULL) -- edit folder path
), tab AS (
    SELECT [database_name] = data.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(400)')
        , [client_hostname] = data.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(400)')
        , [client_app_name] = data.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(400)')
        , [username] = data.value('(event/action[@name="username"]/value)[1]', 'nvarchar(400)')
        , [object_name] = data.value('(event/data[@name="object_name"]/value)[1]', 'nvarchar(250)')
        , [timestamp] = data.value('(event/@timestamp)[1]', 'datetime2')
    FROM ee_data
)
SELECT DISTINCT [database_name], [client_hostname], [client_app_name], [username], [last_executed] = MAX([timestamp]), [number_of_executions] = COUNT([object_name]), [object_name]
FROM tab
GROUP BY [database_name], [client_hostname], [client_app_name], [username], [object_name];
GO

-- cleanup
ALTER EVENT SESSION exec_sp_AdventureWorks2019 ON SERVER STATE = STOP
GO

DROP EVENT SESSION exec_sp_AdventureWorks2019 ON SERVER
GO

SELECT * FROM sys.server_event_sessions;
GO

-- Return the last time that a stored procedure was executed.
USE [AdventureWorks2019] -- use tager database
GO

SELECT o.[name], s.[last_execution_time], s.[type_desc], s.[execution_count]
FROM [sys].[dm_exec_procedure_stats] AS s, [sys].[objects] AS o
WHERE s.[object_id] = o.[object_id]
    AND DB_NAME(s.database_ID) = 'AdventureWorks2019'
    AND o.[name] = 'uspSearchCandidateResumes';
GO
