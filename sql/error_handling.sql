/*
* "Let’s say we have two tables, Parent and Child, and we need to guarantee that they both get populated at once."
* Reference: https://www.brentozar.com/archive/2022/01/error-handling-quiz-week-tryin-try-catch/
*/

-- create a test table
DROP TABLE IF EXISTS dbo.parent;
DROP TABLE IF EXISTS dbo.child;
CREATE TABLE dbo.parent (ID INT IDENTITY(1,1), date_added DATETIME2);
CREATE TABLE dbo.child (ID INT IDENTITY(1,1), date_added DATETIME2);
GO

-- create a basic insert procedure
CREATE OR ALTER PROCEDURE dbo.p_insert_two AS
BEGIN
    INSERT INTO dbo.parent(date_added) VALUES (GETDATE());
    WAITFOR DELAY '00:00:30';
    INSERT INTO dbo.child(date_added) VALUES (GETDATE());
END
GO

-- Run p_insert_two, canceling it before the 30 second waitfor delay expires.
EXEC dbo.p_insert_two;
-- then:
SELECT * FROM dbo.parent;
SELECT * FROM dbo.child;
GO

-- reset for the next test
TRUNCATE TABLE dbo.parent;
TRUNCATE TABLE dbo.child;
GO

-- add a try-catch
CREATE OR ALTER PROCEDURE dbo.p_insert_try_catch AS
BEGIN
    BEGIN TRY
        INSERT INTO dbo.parent(date_added) VALUES (GETDATE());
        WAITFOR DELAY '00:00:30';
        INSERT INTO dbo.child(date_added) VALUES (GETDATE());
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO

-- Run p_insert_try_catch, canceling it before the 30 second waitfor delay expires.
EXEC dbo.p_insert_try_catch;
-- then:
SELECT * FROM dbo.parent;
SELECT * FROM dbo.child;
GO

/*
* TRY…CATCH constructs do not trap the following conditions:
* Warnings or informational messages that have a severity of 10 or lower.
* Errors that have a severity of 20 or higher that stop the SQL Server Database Engine task processing for the session.
* If an error occurs that has severity of 20 or higher and the database connection is not disrupted, TRY…CATCH will handle the error.
* Attentions, such as client-interrupt requests or broken client connections.
* When the session is ended by a system administrator by using the KILL statement.
* For additional information on this topic, see:
* https://docs.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-error-severities?redirectedfrom=MSDN&view=sql-server-ver15
* https://www.sommarskog.se/error_handling/Part2.html
*/

--reset for the next test
TRUNCATE TABLE dbo.parent;
TRUNCATE TABLE dbo.child;
GO

-- test using a transaction
CREATE OR ALTER PROCEDURE dbo.p_insert_transaction AS
BEGIN
    BEGIN TRANSACTION;
        INSERT INTO dbo.parent(date_added) VALUES (GETDATE());
        WAITFOR DELAY '00:00:30';
        INSERT INTO dbo.child(date_added) VALUES (GETDATE());
    COMMIT TRANSACTION;
END
GO

-- Run p_insert_transaction, canceling it before the 30 second waitfor delay expires.
EXEC dbo.p_insert_transaction;
-- In this eaxmple the execution of the waitfor is canceled but the !!! transaction !!! is left open, and it will remain open!
SELECT * FROM dbo.parent;
SELECT * FROM dbo.child;
GO

-- reset for the next test
TRUNCATE TABLE dbo.parent;
TRUNCATE TABLE dbo.child;
GO

-- try-catch transaction
CREATE OR ALTER PROCEDURE dbo.p_insert_transaction AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            INSERT INTO dbo.parent(date_added) VALUES (GETDATE());
            WAITFOR DELAY '00:00:30';
            INSERT INTO dbo.child(date_added) VALUES (GETDATE());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO

-- Run p_insert_transaction, canceling it before the 30 second waitfor delay expires.
EXEC dbo.p_insert_transaction;
-- TRY…CATCH constructs do not trap the following conditions: Attentions, such as client-interrupt requests or broken client connections.
SELECT * FROM dbo.parent;
SELECT * FROM dbo.child;
GO

-- reset for the final test
TRUNCATE TABLE dbo.parent;
TRUNCATE TABLE dbo.child;
GO

-- SET XACT_ABORT ON;
CREATE OR ALTER PROC dbo.p_insert_transaction AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON; -- When SET XACT_ABORT is ON, if a Transact-SQL statement raises a run-time error, the entire transaction is terminated and rolled back.
    BEGIN TRY
        BEGIN TRANSACTION;
            INSERT INTO dbo.parent(date_added) VALUES (GETDATE());
            WAITFOR DELAY '00:00:30';
            INSERT INTO dbo.child(date_added) VALUES (GETDATE());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH -- See https://www.sommarskog.se/error_handling/Part1.html for additional information on error handling catch blocks.
        IF @@trancount > 0 ROLLBACK TRANSACTION;
    END CATCH
END
GO

-- Run p_insert_transaction, canceling it before the 30 second waitfor delay expires.
EXEC dbo.p_insert_transaction;
-- then:
SELECT * FROM dbo.parent;
SELECT * FROM dbo.child;
GO

-- Allow p_insert_transaction to run without interruption.
EXEC dbo.p_insert_transaction;
-- then:
SELECT * FROM dbo.parent;
SELECT * FROM dbo.child;
GO

/*
* Additional References:
* https://www.sommarskog.se/error_handling/Part1.html
* https://www.sommarskog.se/error_handling/Part2.html
* https://www.sommarskog.se/error_handling/Part3.html
*/

-- Extra Credit: Erland Sommarskog's error_handler_sp
CREATE PROCEDURE dbo.error_handler_sp AS
BEGIN
    DECLARE @errmsg NVARCHAR(2048), @severity TINYINT, @state TINYINT, @errno INT, @proc SYSNAME, @lineno INT;
    SELECT @errmsg = error_message(), @severity = error_severity(), @state = error_state(), @errno = error_number(), @proc = error_procedure(), @lineno = error_line();
    IF @errmsg NOT LIKE '***%'
    BEGIN
        SELECT @errmsg = '*** ' + COALESCE(quotename(@proc), '<dynamic SQL>') + ', Line ' + ltrim(str(@lineno)) + '. Errno ' + ltrim(str(@errno)) + ': ' + @errmsg;
        
    END
    RAISERROR('%s', @severity, @state, @errmsg);
END
GO

-- test error_handler_sp
CREATE OR ALTER PROC dbo.p_insert_transaction AS
BEGIN
    SET NOCOUNT, XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            INSERT INTO dbo.parent(date_added) VALUES ('ERROR'); -- !!! ERROR !!!
            WAITFOR DELAY '00:00:30';
            INSERT INTO dbo.child(date_added) VALUES (GETDATE());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0 ROLLBACK TRANSACTION;
        EXEC error_handler_sp;
        RETURN 55555;
    END CATCH
END
GO

-- reset test tables
TRUNCATE TABLE dbo.parent;
TRUNCATE TABLE dbo.child;
GO

-- Run p_insert_transaction. Note the error message returned by error_handler_sp.
EXEC dbo.p_insert_transaction;

-- cleanup
DROP TABLE IF EXISTS dbo.parent;
DROP TABLE IF EXISTS dbo.child;
DROP PROCEDURE dbo.p_insert_two;
DROP PROCEDURE dbo.p_insert_try_catch;
DROP PROCEDURE dbo.p_insert_transaction;
DROP PROCEDURE dbo.error_handler_sp;
