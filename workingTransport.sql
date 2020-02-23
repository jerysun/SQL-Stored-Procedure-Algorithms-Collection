/*
 * filename: workingTransport.sql
 * describe: A complicated but powerful store procedure that covers rich
 *           functions calling, inner left joins for the multi tables
 *           across multi databases...
 * author:   Jerry Sun <jerysun007@hotmail.com>
 * date:     Feburary 22, 2019
 * profile:  http://nl.linkedin.com/in/jerysun
 * website:  https://github.com/jerysun
 */

USE [webworking-trains]
GO

IF EXISTS ( SELECT * 
            FROM   sysobjects 
            WHERE  id = object_id(N'[dbo].[spGrafanaWorkingRequestResults]') 
            AND OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
  DROP PROCEDURE [dbo].[spGrafanaWorkingRequestResults]
END
GO

CREATE PROCEDURE [dbo].[spGrafanaWorkingRequestResults]
@db_customer NVARCHAR(64),
@location NVARCHAR(64),
@result NVARCHAR(64),
@machine NVARCHAR(16),
@workingTask NVARCHAR(64),
@start_datetime NVARCHAR(32),
@end_datetime NVARCHAR(32)
AS
BEGIN
  SET NOCOUNT ON

  DECLARE @AllTrans NVARCHAR(MAX);
  DECLARE @LocationClause NVARCHAR(255) = '';
  DECLARE @ResultClause NVARCHAR(255) = '';
  DECLARE @MachineClause NVARCHAR (255) = '';
  DECLARE @workingTaskClause NVARCHAR (255) = '';
  DECLARE @WhereClause NVARCHAR(MAX) = '';

  SET @start_datetime = TRIM(@start_datetime)
  SET @end_datetime = TRIM(@end_datetime) 

  IF NULLIF(@start_datetime, '') IS NOT NULL AND NULLIF(@end_datetime, '') IS NOT NULL
  BEGIN
    SET @WhereClause = ' WHERE (SELECT CONVERT(NVARCHAR(200), CRQ.crqTimestamp)) >= '''
      + @start_datetime  + ''' AND (SELECT CONVERT(NVARCHAR(200), CRQ.crqTimestamp)) < '''
      + @end_datetime + ''' '
  END

  
  IF UPPER(TRIM(@location)) != 'ALL'
  BEGIN
    SET @LocationClause = ' SIT.sitDisplayName = ''' + @location + ''' ';
  END

  IF UPPER(TRIM(@result)) != 'ALL'
  BEGIN
    SET @ResultClause = ' CRS.crsWorkingResultType = ''' + @result + ''' ';
  END

  IF UPPER(TRIM(@machine)) != 'ALL'
  BEGIN  
    SET @MachineClause = ' CHARINDEX(''' + @machine +''', CHA.chaName) > 0 ';
  END

  IF UPPER(TRIM(@workingTask)) != 'ALL'
  BEGIN
    SET @workingTaskClause = ' TSK.tskDisplayName = ''' + @workingTask + ''' ';
  END

  IF @WhereClause = ''
  BEGIN
    IF @LocationClause <> ''
    BEGIN
      SET @WhereClause = ' WHERE ' + @LocationClause
    END
  END
  ELSE
  BEGIN
    IF @LocationClause <> ''
    BEGIN
      SET @WhereClause += ' AND ' + @LocationClause
    END
  END

  IF @WhereClause = ''
  BEGIN
    IF @ResultClause <> ''
    BEGIN
      SET @WhereClause = ' WHERE ' + @ResultClause
    END
  END
  ELSE
  BEGIN
    IF @ResultClause <> ''
    BEGIN
      SET @WhereClause += ' AND ' + @ResultClause
    END
  END

  IF @WhereClause = ''
  BEGIN
    IF @MachineClause <> ''
    BEGIN
      SET @WhereClause = ' WHERE ' + @MachineClause
    END
  END
  ELSE
  BEGIN
    IF @MachineClause <> ''
    BEGIN
      SET @WhereClause += ' AND ' + @MachineClause
    END
  END

  IF @WhereClause = ''
  BEGIN
    IF @workingTaskClause <> ''
    BEGIN
      SET @WhereClause = ' WHERE ' + @workingTaskClause
    END
  END
  ELSE
  BEGIN
    IF @workingTaskClause <> ''
    BEGIN
      SET @WhereClause += ' AND ' + @workingTaskClause
    END
  END

  SET @AllTrans = '
  SELECT TOP (1000)
    USR.[usrFullName] AS [User Name],
    TSK.[tskDisplayName] AS [Working Task],
    SIT.[sitDisplayName] AS Location,
    UPPER(SUBSTRING(CHA.[chaName], 9, 3)) AS Machine,
    CRQ.[crqTimestamp] AS [Timestamp],
    CRQ.[crqWorkingRequestID] AS [Working Request ID],
    CRQ.[crqQueueTimestamp] AS [Working Request Timestamp],
    CRS.[crsWorkingResultType] AS [Working Result]
  FROM ' + QUOTENAME(@db_customer) + '.[dbo].[WorkingRequest] CRQ
  INNER JOIN ' + QUOTENAME(@db_customer) + '.[dbo].[WorkingResult] CRS
  ON CRQ.crqWorkingRequestID = CRS.crsWorkingRequestID
  INNER JOIN [webworking-identity].[dbo].[User] USR
  ON CRS.crsusrIDFK = USR.usrID
  INNER JOIN [webworking-configuration].[dbo].[Task] TSK
  ON CRS.crstskIDFK = TSK.tskID
  INNER JOIN [webworking-trains].[dbo].[Channel] CHA
  ON CRS.crschaIDFK = CHA.chaID
  INNER JOIN [webworking-configuration].[dbo].[Source] SRC
  ON SRC.srcID = CHA.chasrcIDFK
  INNER JOIN [webworking-configuration].[dbo].[Site] SIT
  ON SIT.sitID = SRC.srcsitIDFK ' +
  @WhereClause + 'ORDER BY TSK.tskDisplayName'

  EXECUTE sp_executesql @AllTrans
END
GO

DECLARE @db_customer NVARCHAR(64) = 'webworking-trains'
DECLARE @location nvarchar(64) = 'All'
DECLARE @result nvarchar(64) = 'All'
DECLARE @machine nvarchar(16) = 'ALL'
DECLARE @workingTask NVARCHAR(64) = 'Household Working'
DECLARE @start_datetime nvarchar(32) = '2019-02-02 13:16:30'
DECLARE @end_datetime nvarchar(32) = '2019-02-29 07:43:00'
EXEC dbo.spGrafanaWorkingRequestResults @db_customer, @location, @result, @machine, @workingTask, @start_datetime, @end_datetime
GO