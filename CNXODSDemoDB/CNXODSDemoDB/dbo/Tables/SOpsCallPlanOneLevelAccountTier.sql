CREATE TABLE [dbo].[SOpsCallPlanOneLevelAccountTier] (
    [SOpsCallPlanOneLevelAccountTierId] INT            IDENTITY (1, 1) NOT NULL,
    [SOpsCallPlanId]                    INT            NOT NULL,
    [FieldTerritoryId]                  INT            NOT NULL,
    [SOpsAccountId]                     INT            NOT NULL,
    [LevelOneUserId]                    INT            NOT NULL,
    [LevelOneSOpsCallPlanPeriodId]      INT            NOT NULL,
    [LevelOneTierId]                    INT            NULL,
    [LevelOneComment]                   NVARCHAR (200) NULL,
    [LevelOneCommentCode]               NVARCHAR (4)   NULL,
    [LevelOneUpdateDate]                DATETIME       NOT NULL,
    [LevelTwoUserId]                    INT            NOT NULL,
    [LevelTwoSOpsCallPlanPeriodId]      INT            NOT NULL,
    [LevelTwoTierId]                    INT            NULL,
    [LevelTwoComment]                   NVARCHAR (200) NULL,
    [LevelTwoCommentCode]               NVARCHAR (4)   NULL,
    [LevelTwoUpdateDate]                DATETIME       NOT NULL,
    [LevelThreeUserId]                  INT            NOT NULL,
    [LevelThreeSOpsCallPlanPeriodId]    INT            NOT NULL,
    [LevelThreeTierId]                  INT            NULL,
    [LevelThreeComment]                 NVARCHAR (200) NULL,
    [LevelThreeCommentCode]             NVARCHAR (4)   NULL,
    [LevelThreeUpdateDate]              DATETIME       NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsCallPlanOneLevelAccountTierId] ASC),
    CONSTRAINT [FK_SOpsCallPlanOneLevelAccountTier_FieldTerritoryId] FOREIGN KEY ([FieldTerritoryId]) REFERENCES [dbo].[SOpsTerritory] ([SOpsTerritoryId]),
    CONSTRAINT [FK_SOpsCallPlanOneLevelAccountTier_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [dbo].[SOpsAccount] ([SOpsAccountId]),
    CONSTRAINT [FK_SOpsCallPlanOneLevelAccountTier_SOpsCallPlanId] FOREIGN KEY ([SOpsCallPlanId]) REFERENCES [dbo].[SOpsCallPlan] ([SOpsCallPlanId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanOneLevelAccountTier_SOpsCallPlanId]
    ON [dbo].[SOpsCallPlanOneLevelAccountTier]([SOpsCallPlanId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanOneLevelAccountTier_FieldTerritoryId]
    ON [dbo].[SOpsCallPlanOneLevelAccountTier]([FieldTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanOneLevelAccountTier_SOpsAccountId]
    ON [dbo].[SOpsCallPlanOneLevelAccountTier]([SOpsAccountId] ASC);

