
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'LogMessage')
    CREATE TABLE [dbo].[LogMessage] (
        [LogId]         INT             IDENTITY (1, 1) NOT NULL,
        [ProcedureName] VARCHAR (128)   NOT NULL,
        [Comments]      NVARCHAR (4000) NULL,
        [LogUTCDate]    DATETIME        NOT NULL
    );
