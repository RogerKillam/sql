/*
* "You don’t need to be a sysadmin"
* Reference: https://sqlstudies.com/2016/03/10/you-dont-need-to-be-a-sysadmin/
* https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak
*
* "Hey, I need sysadmin access to ServerA."
* "Ok. Why do you need sysadmin?"
* "Well I need to be able to read and write to all of the tables on DatabaseA."
* "No problem. I’m going to add you to the db_datareader and db_datawriter roles on DatabaseA. Done."
*/

USE [master]
GO

CREATE LOGIN [BENE-GESSERIT\sqluser] FROM WINDOWS WITH DEFAULT_DATABASE = [master];
GO

USE [AdventureWorks2019]
GO

CREATE USER [BENE-GESSERIT\sqluser] FOR LOGIN [BENE-GESSERIT\sqluser];
GO

ALTER ROLE [db_datareader] ADD MEMBER [BENE-GESSERIT\sqluser];
GO

ALTER ROLE [db_datawriter] ADD MEMBER [BENE-GESSERIT\sqluser];
GO
-- Test login
EXEC AS user = 'BENE-GESSERIT\sqluser';
GO

USE [AdventureWorks2019]
GO

SELECT * FROM [AdventureWorks2019].[Sales].[Store];
GO

REVERT;

/*
* "I also need to be able to see the code behind any object. And not just DatabaseA but any database."
* "Ahh, ok. So that would be VIEW ANY DEFINITION at the instance level. Done."
*/

USE [master]
GO

EXEC [dbo].[sp_MsForEachDB] 'USE [?]; GRANT VIEW DEFINITION TO [BENE-GESSERIT\sqluser];'

-- Test permissions
EXEC AS user = 'BENE-GESSERIT\sqluser';
SELECT * FROM [master]..fn_my_permissions(null,'SERVER');
GO

SELECT * FROM [master]..fn_my_permissions(null,'DATABASE');
GO

REVERT;

/*
* "I need to be able to access the DMOs (Database Management Object) related to performance."
* "Not a problem. Do you need to be able to access them at a server level as well as a database level?"
* "Yes"
* "Ok, so we will grant you VIEW SERVER STATE at the instance level. If you didn’t need the server level DMOs we could just grant VIEW DATABASE STATE on the databases, but this will cover both. Done."
*/

USE [master]
GO

GRANT VIEW SERVER STATE TO [BENE-GESSERIT\sqluser];
GO

/*
* "I really need to be able to create new databases."
* "Ok, so now we have something interesting. This is a development environment so I’ll grant the permission to you by adding you to the server level role dbcreator but with some warnings...
*/

USE [master]
GO

ALTER SERVER ROLE [dbcreator] ADD MEMBER [BENE-GESSERIT\sqluser];
GO

/*
* ...Had it been a production environment that’s probably not something you would have gotten."
* "Why?"
* "If nothing else because I don’t get paged out when something gets broken in development. The ability to create new databases (and alter, drop, or restore them) is pretty powerful. You could easily create a database that’s too large for the drive, causing it to fill it up unexpectedly. Or accidentally put tempdb on the C drive."
* "Is that bad?"
* "Yes"
*/

-- Demo cleanup
USE [AdventureWorks2019]
GO

DROP USER [BENE-GESSERIT\sqluser];
GO

USE [master]
GO

DROP LOGIN [BENE-GESSERIT\sqluser];
GO
