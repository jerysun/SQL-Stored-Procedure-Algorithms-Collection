/*
 * filename: genericPagination.sql
 * describe: A generic but powerful stored procedure that
 *           meets all kinds of pagination requirements.
 * author:   Jerry Sun <jerysun007@hotmail.com>
 * date:     April 07, 2018
 * profile:  http://nl.linkedin.com/in/jerysun
 * website:  https://github.com/jerysun
 */

USE [your_db_name]
GO

IF EXISTS ( SELECT * 
            FROM   sysobjects 
            WHERE  id = object_id(N'[dbo].[spGeneralPaging]') 
            AND OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
  DROP PROCEDURE [dbo].[spGeneralPaging]
END
GO

CREATE PROCEDURE [dbo].[spGeneralPaging]
(
  @TableName NVARCHAR(128),
  @ColumnNames NVARCHAR(1024) = '*',    --the default is all
  @OrderClause NVARCHAR(1024) = '',
  @WhereClause NVARCHAR(1024) = N' 1 = 1 ',
  @PageSize INT = 0,                    --number of records per page, 0 means NO paging
  @PageIndex INT = 1,                   --starting from 1 instead of 0
  @TotalRecords INT OUTPUT
)
AS

BEGIN
  IF @TableName IS NULL OR @TableName ='' OR NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TableName)
	RETURN

  IF (@ColumnNames IS NULL OR @ColumnNames = '') SET @ColumnNames = N' * '
  IF (@WhereClause IS NULL OR @WhereClause = '') SET @WhereClause = N' 1 = 1 '

  DECLARE @StartRecord INT;
  DECLARE @EndRecord INT; 
  DECLARE @TotalCountQuery NVARCHAR(2048); 
  DECLARE @SqlString NVARCHAR(4000);    

  --calculate the records
  IF(@TotalRecords IS NULL OR @TotalRecords <= 0)
  BEGIN
    SET @TotalCountQuery = N'SELECT @TotalRecords = COUNT(*) FROM ' + @TableName + N' WHERE ' + @WhereClause; 
    EXECUTE sp_executesql @TotalCountQuery, N'@TotalRecords INT OUT', @TotalRecords OUT;
  END

  DECLARE @Idt NVARCHAR(32) = '';
  DECLARE @IdQuery NVARCHAR(512) = N'select @Idt = (select COLUMN_NAME ' +
                   N'from INFORMATION_SCHEMA.COLUMNS ' +
                   N'where COLUMNPROPERTY(object_id(TABLE_SCHEMA + ''.'' + TABLE_NAME), COLUMN_NAME, ''IsIdentity'') = 1 ' +
                   N'AND TABLE_NAME = ''codingResult'')';
  EXEC sp_executesql  @IdQuery, N'@Idt NVARCHAR(32) OUT',  @Idt OUT

  IF (@OrderClause IS NULL OR @OrderClause = '') SET @OrderClause = N' ' + @Idt + N' DESC '

  IF @PageSize > 0
  BEGIN    
    IF @PageIndex < 1 SET @PageIndex = 1

    SET @StartRecord = (@PageIndex - 1) * @PageSize + 1    
    SET @EndRecord = @StartRecord + @PageSize - 1 
    SET @SqlString = N'SELECT row_number() over (ORDER BY ' + @OrderClause + ') AS rowId,' + @ColumnNames + ' FROM '+ @TableName + ' WHERE ' + @WhereClause;
    SET @SqlString = N'SELECT * FROM (' + @SqlString + N') AS t WHERE rowId between ' + LTRIM(str(@StartRecord)) + N' AND ' + LTRIM(str(@EndRecord));
  END
  ELSE 
  BEGIN
    SET @SqlString = N'SELECT ' + @ColumnNames + N' FROM ' + @TableName + N' WHERE ' + @WhereClause + N' ORDER BY ' + @OrderClause
  END

  EXECUTE (@SqlString)
END
GO

--- Call this SP ---
DECLARE @TableName NVARCHAR(128) = N'your_table_name' --need neither db nor schema prefix
DECLARE @ColumnNames NVARCHAR(1024) = ''
DECLARE @OrderClause NVARCHAR(1024) = ''
DECLARE @WhereClause NVARCHAR(1024) = ''
DECLARE @PageSize INT = 30
DECLARE @PageIndex INT = 18
DECLARE @TotalRecords INT = 0
EXEC dbo.spGeneralPaging @TableName, @ColumnNames, @OrderClause, @WhereClause, @PageSize, @PageIndex, @TotalRecords
GO

