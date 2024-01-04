DECLARE @id varchar(255) -- used to store the table name to drop
DECLARE @dropCommand varchar(255) -- used to store the T-SQL command to drop the table
DECLARE @namingPattern varchar(255) -- user to define the naming pattern of the tables to drop

SET @namingPattern = 'drop_me%' -- edit me

DECLARE tableCursor CURSOR FOR SELECT name FROM sys.tables WHERE name like @namingPattern 
OPEN tableCursor 
FETCH next FROM tableCursor INTO @id 
WHILE @@fetch_status=0 
BEGIN 
    -- Prepare the SQL statement
    SET @dropcommand = N'drop external table ' + @id -- external table
    -- print @dropCommand -- debug check
    
-- Execute the drop
EXECUTE(@dropcommand) 
    
-- move to next record
FETCH next FROM tableCursor INTO @id 
END 

CLOSE tableCursor 
DEALLOCATE tableCursor
