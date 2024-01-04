/*
* The following is a demonstration of a relational database: Create; Insert; Update; Delete; Secure.
* Edgar F. Codd https://www.ibm.com/ibm/history/exhibits/builders/builders_codd.html
* https://www.sqlservercentral.com/blogs/oltp-star-snowflake-and-galaxy-schemas
*/

-- Drop demo logins
USE [master]
GO

BEGIN TRY
	DROP LOGIN test_user_01;
	DROP LOGIN test_user_02;
	DROP USER test_user_01;
	DROP USER test_user_02;
END TRY
BEGIN CATCH
    PRINT 'Test login and user accounts not found. No cleanup needed.';
END CATCH
GO

/*
* Create database relational_demo
* This step requires membership in the sysadmin fixed server role
* https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-delete-database-backuphistory-transact-sql?view=sql-server-ver15
*/

USE [master]
GO

BEGIN TRY
    CREATE DATABASE [relational_demo]
END TRY
BEGIN CATCH
    DROP DATABASE [relational_demo];
    CREATE DATABASE [relational_demo];
END CATCH
GO

-- Create demo tables
USE [relational_demo]
GO

CREATE TABLE [dbo].[person_types] (
	[person_type_id] INT IDENTITY(1, 1) NOT NULL
	, [person_type_description] VARCHAR(50) NOT NULL
	, CONSTRAINT [pk_person_types] PRIMARY KEY CLUSTERED ([person_type_id] ASC)
);
GO

CREATE TABLE [dbo].[persons] (
	[person_id] INT IDENTITY(1, 1) NOT NULL
	, [person_type_id] INT NOT NULL
	, [first_name] VARCHAR(50) NOT NULL
	, [last_name] VARCHAR(50) NOT NULL
	, CONSTRAINT [pk_persons] PRIMARY KEY CLUSTERED ([person_id] ASC)
	, CONSTRAINT [fk_person_types_persons] FOREIGN KEY ([person_type_id]) REFERENCES [dbo].[person_types]([person_type_id])
);

CREATE NONCLUSTERED INDEX [ix_person_last_name] ON [dbo].[persons]([last_name] DESC);
GO

CREATE TABLE [dbo].[employee_types] (
	[employee_type_id] INT IDENTITY(1, 1) NOT NULL
	, [employee_type_description] VARCHAR(50) NOT NULL
	, CONSTRAINT [pk_employee_types] PRIMARY KEY CLUSTERED ([employee_type_id] ASC)
);
GO

CREATE TABLE [dbo].[employees] (
	[employee_id] INT IDENTITY(1, 1) NOT NULL
	, [employee_type_id] INT NOT NULL
	, [person_id] INT NOT NULL
	, CONSTRAINT [pk_employees] PRIMARY KEY CLUSTERED ([employee_id] ASC)
	, CONSTRAINT [fk_employee_types_employees] FOREIGN KEY ([employee_type_id]) REFERENCES [dbo].[employee_types]([employee_type_id])
	, CONSTRAINT [fk_persons_employees] FOREIGN KEY ([person_id]) REFERENCES [dbo].[persons]([person_id])
);
GO

CREATE TABLE [dbo].[clients] (
	[client_id] INT IDENTITY(1, 1) NOT NULL
	, [person_id] INT NOT NULL
	, [client_name] VARCHAR(150) NOT NULL
	, CONSTRAINT [pk_clients] PRIMARY KEY CLUSTERED ([client_id] ASC)
	, CONSTRAINT [fk_persons_clients] FOREIGN KEY ([person_id]) REFERENCES [dbo].[persons]([person_id])
);
GO

CREATE TABLE [dbo].[address_types] (
	[address_type_id] INT IDENTITY(1, 1) NOT NULL
	, [address_type_description] VARCHAR(50) NOT NULL
	, CONSTRAINT [pk_address_types] PRIMARY KEY CLUSTERED ([address_type_id] ASC)
);
GO

CREATE TABLE [dbo].[states] (
	[state_id] INT IDENTITY(1, 1) NOT NULL
	, [state_code] CHAR(2) NOT NULL
	, [state_description] VARCHAR(15) NOT NULL
	, CONSTRAINT [pk_states] PRIMARY KEY CLUSTERED ([state_id] ASC)
);
GO

CREATE TABLE [dbo].[email_types] (
	[email_type_id] INT IDENTITY(1, 1) NOT NULL
	, [email_type_description] VARCHAR(50) NOT NULL
	, CONSTRAINT [pk_email_types] PRIMARY KEY CLUSTERED ([email_type_id] ASC)
);
GO

CREATE TABLE [dbo].[emails] (
	[email_id] INT IDENTITY(1, 1) NOT NULL
	, [email_type_id] INT NOT NULL
	, [person_id] INT NOT NULL
	, [email] [varchar](125) NOT NULL
	, CONSTRAINT [pk_emails] PRIMARY KEY CLUSTERED ([email_id] ASC)
	, CONSTRAINT [fk_email_types_emails] FOREIGN KEY ([email_type_id]) REFERENCES [dbo].[email_types]([email_type_id])
	, CONSTRAINT [fk_persons_emails] FOREIGN KEY ([person_id]) REFERENCES [dbo].[persons]([person_id])
);
GO

CREATE TABLE [dbo].[phone_types] (
	[phone_type_id] INT IDENTITY(1, 1) NOT NULL
	, [phone_type_description] VARCHAR(50) NOT NULL
	, CONSTRAINT [pk_phone_types] PRIMARY KEY CLUSTERED ([phone_type_id] ASC)
);
GO

CREATE TABLE [dbo].[phone_numbers] (
	[phone_id] INT IDENTITY(1, 1) NOT NULL
	, [phone_type_id] INT NOT NULL
	, [person_id] INT NOT NULL
	, [phone_number] VARCHAR(25) NOT NULL
	, CONSTRAINT [pk_phone_numbers] PRIMARY KEY CLUSTERED ([phone_id] ASC)
	, CONSTRAINT [fk_persons_phone_numbers] FOREIGN KEY ([person_id]) REFERENCES [dbo].[persons]([person_id])
	, CONSTRAINT [fk_phone_types_phone_numbers] FOREIGN KEY ([phone_type_id]) REFERENCES [dbo].[phone_types]([phone_type_id])
);
GO

CREATE TABLE [dbo].[rate_types] (
	[rate_type_id] INT IDENTITY(1, 1) NOT NULL
	, [rate_type_description] VARCHAR(150) NOT NULL
	, CONSTRAINT [pk_rate_types] PRIMARY KEY CLUSTERED ([rate_type_id] ASC)
);
GO

CREATE TABLE [dbo].[rates] (
	[rate_id] INT IDENTITY(1, 1) NOT NULL
	, [rate_type_id] INT NOT NULL
	, [rate_description] VARCHAR(150) NOT NULL
	, [start_date] DATE NOT NULL
	, [end_date] DATE NOT NULL
	, CONSTRAINT [pk_rates] PRIMARY KEY CLUSTERED ([rate_id] ASC)
	, CONSTRAINT [fk_rate_types_rates] FOREIGN KEY ([rate_type_id]) REFERENCES [dbo].[rate_types]([rate_type_id])
);
GO

CREATE TABLE [dbo].[software_versions] (
	[software_version_id] INT IDENTITY(1, 1) NOT NULL
	, [major_version] INT NOT NULL
	, [minor_version] INT NOT NULL
	, CONSTRAINT [pk_software_versions] PRIMARY KEY CLUSTERED ([software_version_id] ASC)
);
GO

CREATE TABLE [dbo].[addresses] (
	[address_id] INT IDENTITY(1, 1) NOT NULL
	, [address_type_id] INT NOT NULL
	, [person_id] INT NOT NULL
	, [address_line_1] VARCHAR(250) NOT NULL
	, [address_line_2] VARCHAR(250) NOT NULL
	, [city] VARCHAR(100) NOT NULL
	, [state_id] INT NOT NULL
	, [postal_code] VARCHAR(10) NOT NULL
	, CONSTRAINT [pk_addresses] PRIMARY KEY CLUSTERED ([address_id] ASC)
	, CONSTRAINT [fk_address_types_addresses] FOREIGN KEY ([address_type_id]) REFERENCES [dbo].[address_types]([address_type_id])
	, CONSTRAINT [fk_persons_addresses] FOREIGN KEY ([person_id]) REFERENCES [dbo].[persons]([person_id])
	, CONSTRAINT [fk_states_addresses] FOREIGN KEY ([state_id]) REFERENCES [dbo].[states]([state_id])
);
GO

CREATE TABLE [dbo].[training] (
	[training_id] INT IDENTITY(1, 1) NOT NULL
	, [person_id] INT NOT NULL
	, [client_id] INT NOT NULL
	, [software_version_id] INT NOT NULL
	, [date_delivered] DATE NULL
	, [rate_id] INT NOT NULL
	, CONSTRAINT [pk_training] PRIMARY KEY CLUSTERED ([training_id] ASC)
	, CONSTRAINT [fk_clients_training] FOREIGN KEY ([client_id]) REFERENCES [dbo].[clients]([client_id])
	, CONSTRAINT [fk_persons_training] FOREIGN KEY ([person_id]) REFERENCES [dbo].[persons]([person_id])
	, CONSTRAINT [fk_rates_training] FOREIGN KEY ([rate_id]) REFERENCES [dbo].[rates]([rate_id])
	, CONSTRAINT [fk_software_versions_training] FOREIGN KEY ([software_version_id]) REFERENCES [dbo].[software_versions]([software_version_id])
);

CREATE NONCLUSTERED INDEX [ix_training_date_delivered] ON [dbo].[training]([date_delivered] DESC);
GO

-- Populate tables
USE [relational_demo]
GO

INSERT INTO [dbo].[person_types]([person_type_description])
VALUES ('Employee'), ('Customer');
GO

	SELECT * FROM [dbo].[person_types];
	GO

INSERT INTO [dbo].[persons]([person_type_id], [first_name], [last_name])
VALUES ('1','Jean','Trenary')
    , ('1','Reuben','Dsa')
    , ('1','Deborah','Poe')
    , ('1','Matthias','Berndt')
    , ('1','Garrett','Vargas')
    , ('1','Mindy','Martin')
    , ('2','John','Chen')
    , ('2','Benjamin','Martin')
    , ('2','Tete','Mensa-Annan')
    , ('2','Hazem','Abolrous')
    , ('2','Angela','Barbariol')
    , ('2','David','Liu')
    , ('2','Dylan','Miller');
GO

	SELECT * FROM [dbo].[persons];
	GO

INSERT INTO [dbo].[employee_types]([employee_type_description])
VALUES ('Consultant'),('Engineering'),('Administration'),('Manager');
GO

	SELECT * FROM [dbo].[employee_types];
	GO

INSERT INTO [dbo].[employees]([employee_type_id], [person_id])
VALUES ('1','1'), ('1','2'), ('1','3'), ('2','4'), ('3','5'), ('4','6');
GO

	SELECT * FROM [dbo].[employees];
	GO

INSERT INTO [dbo].[clients]([person_id], [client_name])
SELECT p.[person_id], p.[last_name] + ' LLC'
FROM [dbo].[persons] p;
GO

	SELECT * FROM [dbo].[clients];
	GO

INSERT INTO [dbo].[address_types]([address_type_description])
VALUES ('Residential'), ('Business'), ('P.O. Box');
GO

	SELECT * FROM [dbo].[address_types];
	GO

INSERT INTO [dbo].[states]([state_code], [state_description])
VALUES ('AK','Alaska')
	, ('AL','Alabama')
	, ('AR','Arkansas')
	, ('AZ','Arizona')
	, ('CA','California')
	, ('CO','Colorado')
	, ('CT','Connecticut')
	, ('DE','Delaware')
	, ('FL','Florida')
	, ('GA','Georgia')
	, ('HI','Hawaii')
	, ('IA','Iowa')
	, ('ID','Idaho')
	, ('IL','Illinois')
	, ('IN','Indiana')
	, ('KS','Kansas')
	, ('KY','Kentucky')
	, ('LA','Louisiana')
	, ('MA','Massachusetts')
	, ('MD','Maryland')
	, ('ME','Maine')
	, ('MN','Minnesota')
	, ('MO','Missouri')
	, ('MS','Mississippi')
	, ('MT','Montana')
	, ('NC','North Carolina')
	, ('ND','North Dakota')
	, ('NE','Nebraska')
	, ('NH','New Hampshire')
	, ('NJ','New Jersey')
	, ('NM','New Mexico')
	, ('NV','Nevada')
	, ('NY','New York')
	, ('OH','Ohio')
	, ('OK','Oklahoma')
	, ('OR','Oregon')
	, ('PA','Pennsylvania')
	, ('PR','Puerto Rico')
	, ('RI','Rhode Island')
	, ('SC','South Carolina')
	, ('SD','South Dakota')
	, ('TN','Tennessee')
	, ('TX','Texas')
	, ('UT','Utah')
	, ('VA','Virginia')
	, ('VT','Vermont')
	, ('WA','Washington')
	, ('WI','Wisconsin')
	, ('WV','West Virginia')
	, ('WY','Wyoming');
GO

	SELECT * FROM [dbo].[states];
	GO

INSERT INTO [dbo].[email_types]([email_type_description])
VALUES ('POC'), ('Organization');
GO

	SELECT * FROM [dbo].[email_types];
	GO

INSERT INTO [dbo].[emails]([email_type_id], [person_id], [Email])
SELECT et.[email_type_id], p.[person_id], p.[first_name] + '.' + p.[last_name] + '@email.com'
FROM [dbo].[persons] AS p
CROSS JOIN [dbo].[email_types] AS et;
GO

	SELECT * FROM [dbo].[emails];
	GO

INSERT INTO [dbo].[phone_types]([phone_type_description])
VALUES ('Office'), ('Mobile');
GO

	SELECT * FROM [dbo].[phone_types];
	GO

INSERT INTO [dbo].[phone_numbers]([phone_type_id], [person_id], [phone_number])
SELECT [dbo].[phone_types].[phone_type_id], [dbo].[persons].[person_id], 'Pending Update'
FROM [dbo].[persons]
CROSS JOIN [dbo].[phone_types];
GO

	SELECT * FROM [dbo].[phone_numbers];
	GO

DROP TABLE IF EXISTS ##phoneNumbers;
CREATE TABLE ##phoneNumbers([ID] INT IDENTITY(1,1) NOT NULL, [numbers] VARCHAR(25));
GO

INSERT INTO ##phoneNumbers([numbers])
VALUES ('191-555-0112')
	, ('230-555-0144')
	, ('447-555-0186')
	, ('669-555-0150')
	, ('727-555-0112')
	, ('142-555-0139')
	, ('172-555-0130')
	, ('822-555-0145')
	, ('265-555-0195')
	, ('712-555-0170')
	, ('896-555-0168')
	, ('587-555-0114')
	, ('181-555-0124')
	, ('476-555-0119')
	, ('927-555-0168')
	, ('539-555-0149')
	, ('740-555-0182')
	, ('283-555-0185')
	, ('110-555-0112')
	, ('435-555-0113')
	, ('943-555-0196')
	, ('842-555-0158')
	, ('200-555-0117')
	, ('413-555-0124')
	, ('314-555-0113')
	, ('508-555-0129')
	, ('612-555-0171');
GO

DECLARE @i INT = 1;
DECLARE @p VARCHAR(25);

WHILE (@i < 26)
BEGIN

	SET @p = (SELECT TOP(1) [numbers] FROM [##phoneNumbers] WHERE [ID] = @i);

	UPDATE [dbo].[phone_numbers]
	SET [phone_number] = @p
	WHERE [person_id] = @i

	SET @i += 1;

END

DROP TABLE ##phoneNumbers;
GO

	SELECT * FROM [dbo].[phone_numbers];
	GO

INSERT INTO [dbo].[rate_types]([rate_type_description])
VALUES ('Standard Class'), ('Hourly');
GO

	SELECT * FROM [dbo].[rate_types];
	GO

INSERT INTO [dbo].[rates]([rate_type_id], [rate_description], [start_date], [end_date])
VALUES ('1','Cutomer Site','3/14/2021','3/15/2021')
	, ('2','Online Consult','3/23/2021','3/25/2021')
	, ('1','Online Consult','5/11/2021','5/13/2021')
	, ('1','Online Consult','6/14/2021','6/18/2021')
	, ('2','Online Consult','6/3/2021','6/4/2021')
	, ('2','Online Consult = Cutomer Site','8/23/2021','8/24/2021');
GO

	SELECT * FROM [dbo].[rates];
	GO

INSERT INTO [dbo].[software_versions]([major_version], [minor_version])
VALUES ('10946','10945'), ('11946','11945'), ('126','125');
GO

	SELECT * FROM [dbo].[software_versions];
	GO

INSERT INTO [dbo].[address_types]([address_type_description])
VALUES ('Office'), ('Home');
GO

	SELECT * FROM [dbo].[address_types];
	GO

INSERT INTO [dbo].[training]([person_id], [client_id], [software_version_id], [date_delivered], [rate_id])
VALUES ('1','1','1','3/14/2021','1')
	, ('2','2','2','3/14/2021','2')
	, ('3','3','3','3/14/2021','1')
	, ('4','4','1','3/14/2021','2')
	, ('5','5','2','3/14/2021','1')
	, ('6','6','3','3/14/2021','2');
GO

	SELECT * FROM [dbo].[training];
	GO

-- Update and Delete
-- Update the [dbo].[Training] record wiht the ID 1 to [POC] = Tete Mensa-Annan [Client] = Mensa-Annan LLC
-- Update values
USE [relational_demo]
GO

DECLARE @training_id INT = '1';
DECLARE @person VARCHAR(50) = 'Mensa-Annan';
DECLARE @client_name VARCHAR(150) = 'Mensa-Annan LLC';
DECLARE @software_versions INT = '10946';
DECLARE @date_delivered DATETIME = '3/22/2021';
DECLARE @rate_description VARCHAR(150) = 'Cutomer Site';

-- Key values
DECLARE @person_id INT = (
	SELECT [person_id]
	FROM [dbo].[persons]
	WHERE [last_name] = @person
);

DECLARE @client_id INT = (
	SELECT [client_id]
	FROM [dbo].[clients]
	WHERE [client_name] = @client_name
);

DECLARE @software_version_id INT = (
	SELECT [software_version_id]
	FROM [dbo].[software_versions]
	WHERE [major_version] = @software_versions
);

DECLARE @rate_id INT = (
	SELECT [rate_id]
	FROM [dbo].[rates]
	WHERE [rate_description] = @rate_description
);

-- Update
UPDATE [dbo].[Training]
SET [person_id] = @person_id
	, [client_id] = @client_id
	, [software_version_id] = @software_version_id
	, [date_delivered] = @date_delivered
	, [rate_id] = @rate_id
WHERE [training_id] = @training_id;
GO

	SELECT * FROM [dbo].[Training];
	GO

-- Delete the [dbo].[Training] record with the training ID 4
USE [relational_demo]
GO

DELETE FROM [dbo].[training]
WHERE [training_id] = 4;
GO

	SELECT * FROM [dbo].[training];
	GO

-- Security
-- Create views for permissions demo
USE [relational_demo]
GO

CREATE VIEW [dbo].[view_Training] AS (
    SELECT [POC] = (p.[first_name] + ' ' + p.[last_name])
        , [Client] = c.[client_name]
        , [Major Version] = sv.[major_version]
        , [Minor Version] = sv.[minor_version]
        , [rate Description] = r.[rate_description]
        , [Date Delivered] = CONVERT(VARCHAR, t.[date_delivered], 101)
    FROM [dbo].[training] AS t
        , [dbo].[persons] AS p
        , [dbo].[clients] AS c
        , [dbo].[software_versions] AS sv
        , [dbo].[rates] AS r
    WHERE t.[person_id] = p.[person_id]
        AND t.[client_id] = c.[client_id]
        AND t.[software_version_id] = sv.[software_version_id]
        AND t.[rate_id] = r.[rate_id]
);
GO

	SELECT * FROM [dbo].[view_Training];
	GO

CREATE VIEW [dbo].[view_Employees] AS (
    SELECT [Person Type] = pt.[person_type_description]
        , [Employee ID] = e.[employee_id]
        , [Name] = (p.[first_name] + ' ' + p.[last_name])
        , [Group] = t.[employee_type_description]
    FROM [dbo].[employees] AS e
        , [dbo].[employee_types] AS t
        , [dbo].[persons] AS p
        , [dbo].[person_types] AS pt
    WHERE pt.[person_type_description] = 'Employee'
        AND e.[employee_type_id] = t.[employee_type_id]
        AND e.[person_id] = p.[person_id]
);
GO

	SELECT * FROM [dbo].[view_Employees];
	GO

-- Create Database Roles Consultants and Administration
CREATE ROLE [Consultants];
CREATE ROLE [Administration];

-- Assign SELECT permissions on view\_Training to the database role Consultants
GRANT SELECT ON OBJECT::[dbo].[view_Training] TO [Consultants];
GO

-- Assign SELECT permissions on view\_Employees to the database role Administration
GRANT SELECT ON OBJECT::[dbo].[view_Employees] TO [Administration];
GO

-- Create two SQL Server Logins
CREATE LOGIN JeanT WITH PASSWORD = 'Aquat33nHung3rF0rc3';
CREATE LOGIN GarrettV WITH PASSWORD = 'Aquat33nHung3rF0rc3';
GO

-- Create two Database Users, linking one user per SQL Server Login
CREATE USER JeanT FROM LOGIN JeanT;
CREATE USER GarrettV FROM LOGIN GarrettV;
GO

-- Assign the Database Users to Roles
ALTER ROLE Consultants ADD MEMBER JeanT;
ALTER ROLE Administration ADD MEMBER GarrettV;
GO

-- Test the permissions by selecting from the views by impersonating each user
-- Display the current execution context
SELECT SUSER_NAME(), USER_NAME();
GO

-- Set and verify the execution context to JeanT
EXECUTE AS LOGIN = 'JeanT';
SELECT SUSER_NAME(), USER_NAME();
GO

-- Verify grant select on view_Training
SELECT *
FROM [dbo].[view_Training];
GO

-- Verify deny select on view_Employees
BEGIN TRY
    SELECT *
    FROM [dbo].[view_Employees];
END TRY
BEGIN CATCH
    PRINT 'User JeanT does not have permission to view [dbo].[view_Employees]';
END CATCH;

-- Revert execution context
REVERT;
GO

-- Verify current execution context
SELECT SUSER_NAME(), USER_NAME();
GO

-- Set and verify the execution context to GarrettV
EXECUTE AS LOGIN = 'GarrettV';
SELECT SUSER_NAME(), USER_NAME();
GO

-- Verify grant select on view_Employees
SELECT *
FROM [dbo].[view_Employees];
GO

-- Verify deny select on view_Training
BEGIN TRY
    SELECT *
    FROM [dbo].[view_Training];
END TRY
BEGIN CATCH
    PRINT 'User GarrettV does not have permission to view [dbo].[view_Training]';
END CATCH;
GO

-- Revert execution context
REVERT;

-- Verify current execution context
SELECT SUSER_NAME(), USER_NAME();
GO
