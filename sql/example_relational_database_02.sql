-- 1. Create and use database TSTDB
-- 2. Create table [dbo].People, PK PeopleID
-- 3. Create table [dbo].Address, PK AddressID
-- 4. Create table [dbo].Phone, PK PhoneID
-- 5. Create table [dbo].[Email], PK EmailID
-- 6. Create table [dbo].ClassType, PK ClassTypeID
-- 7. Create table [dbo].Consulting, PK ConsultantIDID, FK Name, FK Address, FK Email, FK Phone
-- 8. Create table [dbo].[Engineering], PK EngineeringID, FK Name, FK Address, FK Email, FK Phone
-- 9. Create table [dbo].Administration, PK AdministrationID, FK Name, FK Address, FK Email, FK Phone
-- 10. Create table [dbo].Customer, PK CustomerID, FK Type, FK Customer, FK Consultant
-- 11. Create table [dbo].Class, PK ClassID

-- Create TSTDB Database
USE [master]
GO

BEGIN TRY
	CREATE DATABASE [TSTDB]
END TRY
BEGIN CATCH
	-- EXEC msdb.[dbo].sp_delete_database_backuphistory @database_name = N'TSTDB'
	ALTER DATABASE [TSTDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE [TSTDB]
	CREATE DATABASE [TSTDB]
END CATCH
GO

USE [TSTDB];
GO

-- 2. Create People Table
CREATE TABLE [dbo].[People] (
    [PeopleID] int IDENTITY (1, 1) NOT NULL
    ,[FirstName] varchar(50) NOT NULL
    ,[LastName] varchar(50) NOT NULL

    CONSTRAINT [PK_PeopleID] PRIMARY KEY CLUSTERED ([PeopleID] ASC)
);
GO

-- 3. Create Address Table
CREATE TABLE [dbo].[Address] (
    [AddressID] int IDENTITY (1000, 1) NOT NULL
    ,[street] varchar(50) NOT NULL
    ,[city] varchar(50) NOT NULL
    ,[state] varchar(50) NOT NULL
    ,[zip] int NOT NULL

    CONSTRAINT [PK_AddressID] PRIMARY KEY CLUSTERED ([AddressID] ASC)
);
GO

-- 4. Create Phone Table
CREATE TABLE [dbo].[Phone] (
    [PhoneID] int IDENTITY (1000, 1) NOT NULL
    ,[PhoneNumber] varchar(50) NOT NULL

    CONSTRAINT [PK_PhoneID] PRIMARY KEY CLUSTERED ([PhoneID] ASC)
);
GO

-- 5. Create Email Table
CREATE TABLE [dbo].[Email] (
    [EmailID] int IDENTITY (1000, 1) NOT NULL
    ,[EmailAddress] varchar(50) NOT NULL

    CONSTRAINT [PK_EmailID] PRIMARY KEY CLUSTERED ([EmailID] ASC)
);
GO

-- 6. Create ClassType Table
CREATE TABLE [dbo].[ClassType] (
    [ClassTypeID] int IDENTITY (1, 1) NOT NULL
    ,[Type] varchar(50) NOT NULL

    CONSTRAINT [PK_ClassTypeID] PRIMARY KEY CLUSTERED ([ClassTypeID] ASC)
);
GO

-- 7. Create Consulting Table
CREATE TABLE [dbo].[Consulting] (
    [ConsultantID] int IDENTITY (1, 1) NOT NULL
    ,[EmployeeID] varchar(50) NOT NULL
    ,[Name] int NOT NULL
    ,[Address] int NOT NULL
    ,[Email] int NOT NULL
    ,[Phone] int NOT NULL

    CONSTRAINT [PK_ConsultantID] PRIMARY KEY CLUSTERED ([ConsultantID] ASC)
    ,CONSTRAINT [FK_Consulting_People] FOREIGN KEY ([Name]) REFERENCES [dbo].[People]([PeopleID])
    ,CONSTRAINT [FK_Consulting_Address] FOREIGN KEY ([Address]) REFERENCES [dbo].[Address]([AddressID])
    ,CONSTRAINT [FK_Consulting_Email] FOREIGN KEY ([Email]) REFERENCES [dbo].[Email]([EmailID])
    ,CONSTRAINT [FK_Consulting_Phone] FOREIGN KEY ([Phone]) REFERENCES [dbo].[Phone]([PhoneID])
);
GO

-- 7.1 Create Consultant Table Index
CREATE NONCLUSTERED INDEX [fkIdx_Consultant_Name] ON [dbo].[Consulting]([Name] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Consultant_Address] ON [dbo].[Consulting]([Address] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Consultant_Email] ON [dbo].[Consulting]([Email] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Consultant_Phone] ON [dbo].[Consulting]([Phone] ASC);
GO

-- 8. Create Engineering Table
CREATE TABLE [dbo].[Engineering] (
    [EngineeringID] int IDENTITY (1, 1) NOT NULL
    ,[EmployeeID] varchar(50) NOT NULL
    ,[Name] int NOT NULL
    ,[Address] int NOT NULL
    ,[Email] int NOT NULL
    ,[Phone] int NOT NULL

    CONSTRAINT [PK_EngineeringID] PRIMARY KEY CLUSTERED ([EngineeringID] ASC)
    ,CONSTRAINT [FK_Engineering_People] FOREIGN KEY ([Name]) REFERENCES [dbo].[People]([PeopleID])
    ,CONSTRAINT [FK_Engineering_Address] FOREIGN KEY ([Address]) REFERENCES [dbo].[Address]([AddressID])
    ,CONSTRAINT [FK_Engineering_Email] FOREIGN KEY ([Email]) REFERENCES [dbo].[Email]([EmailID])
    ,CONSTRAINT [FK_Engineering_Phone] FOREIGN KEY ([Phone]) REFERENCES [dbo].[Phone]([PhoneID])
);
GO

-- 8.1 Create Engineering Table Index
CREATE NONCLUSTERED INDEX [fkIdx_Engineering_Name] ON [dbo].[Engineering]([Name] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Engineering_Address] ON [dbo].[Engineering]([Address] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Engineering_Email] ON [dbo].[Engineering]([Email] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Engineering_Phone] ON [dbo].[Engineering]([Phone] ASC);
GO

-- 9. Create Administration Table
CREATE TABLE [dbo].[Administration] (
    [AdministrationID] int IDENTITY (1, 1) NOT NULL
    ,[EmployeeID] varchar(50) NOT NULL
    ,[Name] int NOT NULL
    ,[Address] int NOT NULL
    ,[Email] int NOT NULL
    ,[Phone] int NOT NULL
    ,[isManager] bit NOT NULL

    CONSTRAINT [PK_AdministrationID] PRIMARY KEY CLUSTERED ([AdministrationID] ASC)
    ,CONSTRAINT [FK_Administration_People] FOREIGN KEY ([Name]) REFERENCES [dbo].[People]([PeopleID])
    ,CONSTRAINT [FK_Administration_Address] FOREIGN KEY ([Address]) REFERENCES [dbo].[Address]([AddressID])
    ,CONSTRAINT [FK_Administration_Email] FOREIGN KEY ([Email]) REFERENCES [dbo].[Email]([EmailID])
    ,CONSTRAINT [FK_Administration_Phone] FOREIGN KEY ([Phone]) REFERENCES [dbo].[Phone]([PhoneID])
);
GO

-- 9.1 Create Administration Table Index
CREATE NONCLUSTERED INDEX [fkIdx_Administration_Name] ON [dbo].[Administration]([Name] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Administration_Address] ON [dbo].[Administration]([Address] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Administration_Email] ON [dbo].[Administration]([Email] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Administration_Phone] ON [dbo].[Administration]([Phone] ASC);
GO

-- 10. Create Customer Table
CREATE TABLE [dbo].[Customer] (
    [CustomerID] int IDENTITY (1, 1) NOT NULL
    ,[Organization] varchar(50) NOT NULL
    ,[POC] int NOT NULL
    ,[Address] int NOT NULL
    ,[Email] int NOT NULL
    ,[Phone] int NOT NULL

    CONSTRAINT [PK_CustomerID] PRIMARY KEY CLUSTERED ([CustomerID] ASC)
    ,CONSTRAINT [FK_Customer_People] FOREIGN KEY ([POC]) REFERENCES [dbo].[People]([PeopleID])
    ,CONSTRAINT [FK_Customer_Address] FOREIGN KEY ([Address]) REFERENCES [dbo].[Address]([AddressID])
    ,CONSTRAINT [FK_Customer_Email] FOREIGN KEY ([Email]) REFERENCES [dbo].[Email]([EmailID])
    ,CONSTRAINT [FK_Customer_Phone] FOREIGN KEY ([Phone]) REFERENCES [dbo].[Phone]([PhoneID])
);
GO

-- 10.1 Create Customer Table Index
CREATE NONCLUSTERED INDEX [fkIdx_Customer_POC] ON [dbo].[Customer]([POC] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Customer_Address] ON [dbo].[Customer]([Address] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Customer_Email] ON [dbo].[Customer]([Email] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Customer_Phone] ON [dbo].[Customer]([Phone] ASC);
GO

-- 11. Create Class Table
CREATE TABLE [dbo].[Class] (
    [ClassID] int IDENTITY (1, 1) NOT NULL
    ,[Name] varchar(50) NOT NULL
    ,[Type] int NOT NULL
    ,[Rate] smallmoney NOT NULL
    ,[Customer] int NOT NULL
    ,[Consultant] int NOT NULL
    ,[Start] date NOT NULL
    ,[End] date NOT NULL

    CONSTRAINT [PK_ClassID] PRIMARY KEY CLUSTERED ([ClassID] ASC)
    ,CONSTRAINT [FK_Class_ClassType] FOREIGN KEY ([Type]) REFERENCES [dbo].[ClassType]([ClassTypeID])
    ,CONSTRAINT [FK_Class_Customer] FOREIGN KEY ([Customer]) REFERENCES [dbo].[Customer]([CustomerID])
    ,CONSTRAINT [FK_Class_Consultant] FOREIGN KEY ([Consultant]) REFERENCES [dbo].[Consulting]([ConsultantID])
);
GO

-- 11.1 Create Class Table Index
CREATE NONCLUSTERED INDEX [fkIdx_Class_Type] ON [dbo].[Class]([Type] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Class_Customer] ON [dbo].[Class]([Customer] ASC);
GO

CREATE NONCLUSTERED INDEX [fkIdx_Class_Consultant] ON [dbo].[Class]([Consultant] ASC);
GO

/*
    Test 1 INSERT 6 rows of data into every table
    Test 2 UPDATE 3 values in the [dbo].[Administration] table
    Test 3 DELETE 2 values in the [dbo].[Class] table
    Test 4 JOIN tables
*/

USE [TSTDB];
GO

--  1.1 INSERT INTO [dbo].[Address] 
    INSERT INTO [dbo].[Address]([Street],[City],[State],[Zip])
    VALUES('2383 Pepper Drive','Redmond','Washington','98052')
        , ('1064 Slow Creek Road','Seattle','Washington','98104')
        , ('7640 First Ave.','Everett','Washington','98201')
        , ('4312 Cambridge Drive','Renton','Washington','98055')
        , ('10203 Acorn Avenue','Calgary','Washington','98055')
        , ('9687 Shakespeare Drive','Newport Hills','Washington','98006')
        , ('3977 Central Avenue','Duvall','Washington','98019')
        , ('7166 Brock Lane','Seattle','Washington','98104')
        , ('4231 Spar Court','Snohomish','Washington','98296')
        , ('3997 Via De Luna','Cambridge','Massachusetts','02139')
        , ('5050 Mt Wilson Way','Kenmore','Washington','98028')
        , ('2687 Ridge Road','Edmonds','Washington','98020')
        , ('9605 Pheasant Circle','Gold Bar','Washington','98251')
        , ('7048 Laurel','Kenmore','Washington','98028')
        , ('9297 Kenston Dr.','Newport Hills','Washington','98006')
        , ('2425 Notre Dame Ave','Gold Bar','Washington','98251')
        , ('636 Vine Hill Way','Portland','Oregon','97205')
        , ('5009 Orange Street','Renton','Washington','98055')
        , ('5734 Ashford Court','Monroe','Washington','98272')
        , ('4350 Minute Dr.','Newport Hills','Washington','98006')
        , ('5423 Champion Rd.','Edmonds','Washington','98020')
        , ('9530 Vine Lane','Issaquah','Washington','98027')
        , ('7842 Ygnacio Valley Road','Seattle','Washington','98104')
        , ('4852 Chaparral Court','Snohomish','Washington','98296')
        , ('4909 Poco Lane','Redmond','Washington','98052');
    GO

--  1.2 INSERT INTO [dbo].[ClassType]
    INSERT INTO [dbo].[ClassType]([Type])
    VALUES('In-Person')
        , ('Virtual')
        , ('E-Learning')
        , ('Instructor-Led E-Learning')
        , ('Split Sessions')
        , ('Half Session');
    GO

--  1.3 INSERT INTO [dbo].[Email]
    INSERT INTO [dbo].[Email]([EmailAddress])
    VALUES('jean0@adventure-works.com')
        , ('reuben0@adventure-works.com')
        , ('deborah0@adventure-works.com')
        , ('matthias0@adventure-works.com')
        , ('garrett1@adventure-works.com')
        , ('mindy0@adventure-works.com')
        , ('john2@adventure-works.com')
        , ('cristian0@adventure-works.com')
        , ('benjamin0@adventure-works.com')
        , ('tete0@adventure-works.com')
        , ('hazem0@adventure-works.com')
        , ('angela0@adventure-works.com')
        , ('david6@adventure-works.com')
        , ('dylan0@adventure-works.com')
        , ('ascott0@adventure-works.com')
        , ('pat0@adventure-works.com')
        , ('pamela0@adventure-works.com')
        , ('amy0@adventure-works.com')
        , ('jeffrey0@adventure-works.com')
        , ('ken0@adventure-works.com')
        , ('rajesh0@adventure-works.com')
        , ('peter1@adventure-works.com')
        , ('annik0@adventure-works.com')
        , ('linda0@adventure-works.com');
    GO

--  1.4 INSERT INTO [dbo].[People]
    INSERT INTO [dbo].[People]([FirstName],[LastName])
    VALUES('Jean','Trenary')
        , ('Reuben','Dsa')
        , ('Deborah','Poe')
        , ('Matthias','Berndt')
        , ('Garrett','Vargas')
        , ('Mindy','Martin')
        , ('John','Chen')
        , ('Cristian','Petculescu')
        , ('Benjamin','Martin')
        , ('Tete','Mensa-Annan')
        , ('Hazem','Abolrous')
        , ('Angela','Barbariol')
        , ('David','Liu')
        , ('Dylan','Miller')
        , ('A. Scott','Wright')
        , ('Pat','Coleman')
        , ('Pamela','Ansman-Wolfe')
        , ('Amy','Alberts')
        , ('Jeffrey','Ford')
        , ('Ken','Sanchez')
        , ('Rajesh','Patel')
        , ('Peter','Connelly')
        , ('Annik','Stahl')
        , ('Linda','Moschell');
    GO

--  1.5 INSERT INTO [dbo].[Phone]
    INSERT INTO [dbo].[Phone]([PhoneNumber])
    VALUES('685-555-0120')
        , ('191-555-0112')
        , ('602-555-0194')
        , ('139-555-0120')
        , ('922-555-0165')
        , ('522-555-0147')
        , ('201-555-0163')
        , ('434-555-0133')
        , ('533-555-0111')
        , ('615-555-0153')
        , ('869-555-0125')
        , ('150-555-0194')
        , ('646-555-0185')
        , ('181-555-0156')
        , ('992-555-0194')
        , ('720-555-0158')
        , ('340-555-0193')
        , ('775-555-0164')
        , ('984-555-0185')
        , ('697-555-0142')
        , ('373-555-0137')
        , ('310-555-0133')
        , ('499-555-0125')
        , ('612-555-0171');
    GO

--  1.6 INSERT INTO [dbo].[Administration]
    INSERT INTO [dbo].[Administration]([EmployeeID],[Name],[Address],[Email],[Phone],[isManager])
    VALUES('TS132-INC','1','1000','1000','1000','1')
        , ('TS134-INC','2','1001','1001','1001','1')
        , ('TS136-INC','3','1002','1002','1002','1')
        , ('TS138-INC','4','1003','1003','1003','0')
        , ('TS140-INC','5','1004','1004','1004','0')
        , ('TS142-INC','6','1005','1005','1005','0');
    GO

--  1.7 INSERT INTO [dbo].[Consulting]
    INSERT INTO [dbo].[Consulting]([EmployeeID],[Name],[Address],[Email],[Phone])
    VALUES('TS144-INC','7','1006','1006','1006')
        , ('TS146-INC','8','1007','1007','1007')
        , ('TS148-INC','9','1008','1008','1008')
        , ('TS150-INC','10','1009','1009','1009')
        , ('TS152-INC','11','1010','1010','1010')
        , ('TS153-INC','12','1011','1011','1011');
    GO

--  1.8 INSERT INTO [dbo].[Engineering]
    INSERT INTO [dbo].[Engineering]([EmployeeID],[Name],[Address],[Email],[Phone])
    VALUES('TS144-INC','13','1012','1012','1012')
        , ('TS146-INC','14','1013','1013','1013')
        , ('TS148-INC','15','1014','1014','1014')
        , ('TS150-INC','16','1015','1015','1015')
        , ('TS152-INC','17','1016','1016','1016')
        , ('TS153-INC','18','1017','1017','1017');
    GO

--  1.9 INSERT INTO [dbo].[Customer]
    INSERT INTO [dbo].[Customer]([Organization],[POC],[Address],[Email],[Phone])
    VALUES('First National Sport Co.','19','1018','1018','1018')
        , ('Recreation Place','20','1019','1019','1019')
        , ('International Bicycles','21','1020','1020','1020')
        , ('Comfort Road Bicycles','22','1021','1021','1021')
        , ('Knopfler Cycles','23','1022','1022','1022')
        , ('Vista Road Bikes','24','1023','1023','1023');
    GO

--  1.10 INSERT INTO [dbo].[Class]
    INSERT INTO [dbo].[Class]([Name],[Type],[Rate],[Customer],[Consultant],[Start],[End])
    VALUES('Intro Training','2','34.00','1','1','2021-01-04','2021-01-07')
        , ('Refresher Training','3','28.00','2','2','2021-02-08','2021-02-10')
        , ('Session #1 Training','4','34.00','3','3','2021-03-01','2021-03-05')
        , ('Session #2 Training','4','34.00','4','4','2021-03-08','2021-03-12')
        , ('Session #3 Training','4','34.00','5','5','2021-03-15','2021-03-19')
        , ('Function Training','1','34.00','6','6','2021-05-06','2021-05-07');
    GO

--  2 UPDATE 3 values in [dbo].[Administration]
	UPDATE [dbo].[Address]
	SET [Street]='2383 Salt Drive', [city]='Bellevue', [zip]='98004'
    FROM [dbo].[Address]
    INNER JOIN [dbo].[Administration]
        ON [dbo].[Address].[AddressID] = [dbo].[Administration].[Address]
    WHERE [EmployeeID] = 'TS132-INC';
    GO

--  3 DELETE 2 values in [dbo].[Class]
    DELETE FROM [dbo].[Class]
    WHERE [ClassID] = 1 OR [ClassID] = 2;
    GO

--  4.1 JOIN Administration
    -- https://www.sqlservercentral.com/articles/ansi-joins
    SELECT a.[EmployeeID], p.[FirstName], p.[LastName], s.[street], s.[city], s.[state], s.[zip], e.[EmailAddress], t.[PhoneNumber]
    FROM [dbo].[Administration] AS a, [dbo].[People] AS p, [dbo].[Address] AS s, [dbo].[Email] AS e, [dbo].[Phone] AS t
    WHERE p.[PeopleID] = a.[Name]
        AND s.[AddressID] = a.[Address]
        AND e.[EmailID] = a.[Email]
        AND t.[PhoneID] = a.[Phone];
    GO

    SELECT [dbo].[Administration].[EmployeeID]
    , [dbo].[People].[FirstName]
    , [dbo].[People].[LastName]
    , [dbo].[Address].[Street]
    , [dbo].[Address].[city]
    , [dbo].[Address].[state]
    , [dbo].[Address].[zip]
    , [dbo].[Email].[EmailAddress]
    , [dbo].[Phone].[PhoneNumber]
    , [dbo].[Administration].[isManager]
    FROM [dbo].[Address]
    INNER JOIN [dbo].[Administration]
        ON [dbo].[Address].[AddressID] = [dbo].[Administration].[Address]
    INNER JOIN [dbo].[Email]
        ON [dbo].[Administration].[Email] = [dbo].[Email.[EmailID]
    INNER JOIN [dbo].[People]
        ON [dbo].[Administration].[Name] = [dbo].[People].[PeopleID]
    INNER JOIN [dbo].[Phone]
        ON [dbo].[Administration].[Phone] = [dbo].[Phone].[PhoneID];
    GO

--  4.2 JOIN Consulting
    SELECT [dbo].[Consulting].[EmployeeID]
    , [dbo].[People].[FirstName]
    , [dbo].[People].[LastName]
    , [dbo].[Address].[Street]
    , [dbo].[Address].[city]
    , [dbo].[Address].[state]
    , [dbo].[Address].[zip]
    , [dbo].[Email].[EmailAddress]
    , [dbo].[Phone].[PhoneNumber]
    FROM [dbo].[Address]
    INNER JOIN [dbo].[Consulting]
        ON [dbo].[Address].[AddressID] = [dbo].[Consulting].[Address]
    INNER JOIN [dbo].[Email]
        ON [dbo].[Consulting].[Email] = [dbo].[Email].[EmailID]
    INNER JOIN [dbo].[People]
        ON [dbo].[Consulting].[Name] = [dbo].[People].[PeopleID]
    INNER JOIN [dbo].[Phone]
        ON [dbo].[Consulting].[Phone] = [dbo].[Phone].[PhoneID];
    GO

--  4.3 JOIN Engineering
    SELECT [dbo].[Engineering].[EmployeeID]
    , [dbo].[People].[FirstName]
    , [dbo].[People].[LastName]
    , [dbo].[Address].[Street]
    , [dbo].[Address].[city]
    , [dbo].[Address].[state]
    , [dbo].[Address].[zip]
    , [dbo].[Email].[EmailAddress]
    , [dbo].[Phone].[PhoneNumber]
    FROM [dbo].[Address]
    INNER JOIN [dbo].[Engineering]
        ON [dbo].[Address].[AddressID] = [dbo].[Engineering].[Address]
    INNER JOIN [dbo].[Email]
        ON [dbo].[Engineering].[Email] = [dbo].[Email].[EmailID]
    INNER JOIN [dbo].People
        ON [dbo].[Engineering].[Name] = [dbo].[People].[PeopleID]
    INNER JOIN [dbo].[Phone]
        ON [dbo].[Engineering].[Phone] = [dbo].[Phone].[PhoneID];
    GO

--  4.4 JOIN Customer
    SELECT [dbo].[Customer].[Organization]
    , [dbo].[People].[FirstName] AS [POC First Name]
    , [dbo].[People].[LastName] AS [POC Last Name]
    , [dbo].[Address].[Street]
    , [dbo].[Address].[city]
    , [dbo].[Address].[state]
    , [dbo].[Address].[zip]
    , [dbo].[Email].[EmailAddress] AS [POC Email]
    , [dbo].[Phone].[PhoneNumber] AS [POC Phone]
    FROM [dbo].[Address]
    INNER JOIN [dbo].[Customer]
        ON [dbo].[Address].[AddressID] = [dbo].[Customer].[Address]
    INNER JOIN [dbo].[Email]
        ON [dbo].[Customer].[Email] = [dbo].[Email].[EmailID]
    INNER JOIN [dbo].[People]
        ON [dbo].[Customer].[POC] = [dbo].[People].[PeopleID]
    INNER JOIN [dbo].Phone
        ON [dbo].[Customer].[Phone] = [dbo].[Phone].[PhoneID];
    GO

--  4.5 JOIN Class
    SELECT [dbo].[Class].[ClassID]
    , [dbo].[Class].[Name]
    , [dbo].[ClassType].[Type]
    , [dbo].[Class].[Rate]
    , [dbo].[Class].[Customer]
    , [dbo].[Class].[Consultant]
    , [dbo].[Class].[Start]
    , [dbo].[Class].[End]
    FROM [dbo].[Class]
    INNER JOIN [dbo].[ClassType]
        ON [dbo].[Class].[Type] = [dbo].[ClassType].[ClassTypeID];
    GO
