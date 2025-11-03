CREATE TABLE [web].[RepRosterHistoryDetail] (
    [RepRosterHistoryDetailId] INT            IDENTITY (1, 1) NOT NULL,
    [RepRosterHistoryId]       INT            NOT NULL,
    [ColumnName]               NVARCHAR (200) NOT NULL,
    [OldValue]                 NVARCHAR (MAX) NULL,
    [NewValue]                 NVARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([RepRosterHistoryDetailId] ASC),
    CONSTRAINT [FK_RepRosterHistory_RepRosterHistoryId] FOREIGN KEY ([RepRosterHistoryId]) REFERENCES [web].[RepRosterHistory] ([RepRosterHistoryId])
);


GO
CREATE NONCLUSTERED INDEX [IX_RepRosterHistoryDetail_RepRosterHistoryId]
    ON [web].[RepRosterHistoryDetail]([RepRosterHistoryId] ASC);

