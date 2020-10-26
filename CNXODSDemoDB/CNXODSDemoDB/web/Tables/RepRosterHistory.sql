CREATE TABLE [web].[RepRosterHistory] (
    [RepRosterHistoryId] INT            IDENTITY (1, 1) NOT NULL,
    [RepRosterId]        INT            NOT NULL,
    [EmployeeId]         NVARCHAR (200) NOT NULL,
    [UserId]             INT            NOT NULL,
    [HistoryType]        NVARCHAR (4)   NOT NULL,
    [LastUpdateDate]     DATETIME       NOT NULL,
    PRIMARY KEY CLUSTERED ([RepRosterHistoryId] ASC),
    CONSTRAINT [FK_RepRosterHistory_RepRosterId] FOREIGN KEY ([RepRosterId]) REFERENCES [web].[RepRoster] ([RepRosterId])
);


GO
CREATE NONCLUSTERED INDEX [IX_RepRosterHistory_RepRosterId]
    ON [web].[RepRosterHistory]([RepRosterId] ASC);

