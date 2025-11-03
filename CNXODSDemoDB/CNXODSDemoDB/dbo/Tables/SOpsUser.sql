CREATE TABLE [dbo].[SOpsUser] (
    [SOpsUserId]                  INT            IDENTITY (1, 1) NOT NULL,
    [Email]                       NVARCHAR (200) NOT NULL,
    [OdsUserId]                   NVARCHAR (200) NOT NULL,
    [DisplayName]                 NVARCHAR (200) NOT NULL,
    [SOpsUserTitleId]             INT            NULL,
    [OdsManagerUserId]            NVARCHAR (200) NULL,
    [NumberOfCurrentTotalCalls]   INT            NULL,
    [NumberOfCurrentAverageCalls] DECIMAL (6, 2) NULL,
    [NumberOfFutureTotalCalls]    INT            NULL,
    [NumberOfFutureAverageCalls]  DECIMAL (6, 2) NULL,
    [ExternalId1]                 NVARCHAR (200) NULL,
    [ExternalId2]                 NVARCHAR (200) NULL,
    PRIMARY KEY CLUSTERED ([SOpsUserId] ASC),
    CONSTRAINT [FK_SOpsUser_SOpsUserTitleId] FOREIGN KEY ([SOpsUserTitleId]) REFERENCES [dbo].[SOpsUserTitle] ([SOpsUserTitleId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsUser_SOpsUserId]
    ON [dbo].[SOpsUser]([SOpsUserId] ASC);

