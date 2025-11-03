CREATE TABLE [dbo].[LogMessage] (
    [LogId]         INT             IDENTITY (1, 1) NOT NULL,
    [ProcedureName] NVARCHAR (64)   NOT NULL,
    [Comments]      NVARCHAR (1024) NULL,
    [LogUTCDate]    DATETIME        NOT NULL
);

