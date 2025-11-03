CREATE TABLE [dbo].[SOpsCallPlanAccountTier] (
    [SOpsCallPlanAccountTierId]       INT            IDENTITY (1, 1) NOT NULL,
    [ParentSOpsCallPlanAccountTierId] INT            NULL,
    [SOpsCallPlanPeriodId]            INT            NOT NULL,
    [FieldTerritoryId]                INT            NOT NULL,
    [FieldUserId]                     INT            NOT NULL,
    [SOpsUserId]                      INT            NULL,
    [SOpsAccountId]                   INT            NOT NULL,
    [SOpsAccountTierId]               INT            NULL,
    [Comment]                         NVARCHAR (200) NULL,
    [CreatedDate]                     DATETIME       NULL,
    [LastUpdateDate]                  DATETIME       NULL,
    PRIMARY KEY CLUSTERED ([SOpsCallPlanAccountTierId] ASC),
    CONSTRAINT [FK_SOpsCallPlanAccountTier_FieldTerritoryId] FOREIGN KEY ([FieldTerritoryId]) REFERENCES [dbo].[SOpsTerritory] ([SOpsTerritoryId]),
    CONSTRAINT [FK_SOpsCallPlanAccountTier_FieldUserId] FOREIGN KEY ([FieldUserId]) REFERENCES [dbo].[SOpsUser] ([SOpsUserId]),
    CONSTRAINT [FK_SOpsCallPlanAccountTier_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [dbo].[SOpsAccount] ([SOpsAccountId]),
    CONSTRAINT [FK_SOpsCallPlanAccountTier_SOpsAccountTierId] FOREIGN KEY ([SOpsAccountTierId]) REFERENCES [dbo].[SOpsAccountTier] ([SOpsAccountTierId]),
    CONSTRAINT [FK_SOpsCallPlanAccountTier_SOpsCallPlanPeriodId] FOREIGN KEY ([SOpsCallPlanPeriodId]) REFERENCES [dbo].[SOpsCallPlanPeriod] ([SOpsCallPlanPeriodId]),
    CONSTRAINT [FK_SOpsCallPlanAccountTier_SOpsUserId] FOREIGN KEY ([SOpsUserId]) REFERENCES [dbo].[SOpsUser] ([SOpsUserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanAccountTier_SOpsCallPlanAccountTierId]
    ON [dbo].[SOpsCallPlanAccountTier]([SOpsCallPlanAccountTierId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanAccountTier_ParentSOpsCallPlanAccountTierId]
    ON [dbo].[SOpsCallPlanAccountTier]([ParentSOpsCallPlanAccountTierId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanAccountTier_SOpsCallPlanPeriodId]
    ON [dbo].[SOpsCallPlanAccountTier]([SOpsCallPlanPeriodId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanAccountTier_FieldTerritoryId]
    ON [dbo].[SOpsCallPlanAccountTier]([FieldTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanAccountTier_FieldUserId]
    ON [dbo].[SOpsCallPlanAccountTier]([FieldUserId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanAccountTier_SOpsUserId]
    ON [dbo].[SOpsCallPlanAccountTier]([SOpsUserId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanAccountTier_SOpsAccountId]
    ON [dbo].[SOpsCallPlanAccountTier]([SOpsAccountId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanAccountTier_SOpsAccountTierId]
    ON [dbo].[SOpsCallPlanAccountTier]([SOpsAccountTierId] ASC);

