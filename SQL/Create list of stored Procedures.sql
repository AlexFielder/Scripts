--DROP TABLE #ListOfSPs
CREATE TABLE #ListOfSPs 
    (
        DBName varchar(100), 
        [OBJECT_ID] INT,
        SPName varchar(100),
		modify_date Date
    )

    EXEC sp_msforeachdb 'USE [?]; INSERT INTO #ListOfSPs Select ''?'', Object_Id, Name, modify_date FROM sys.procedures'

    SELECT 
        * 
    FROM #ListOfSPs
	WHERE year(modify_date) = 2019
	ORDER BY [modify_date]--[DBName], [SPName]