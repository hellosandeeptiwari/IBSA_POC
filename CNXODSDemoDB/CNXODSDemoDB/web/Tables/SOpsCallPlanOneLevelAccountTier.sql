CREATE TABLE [web].[SOpsCallPlanOneLevelAccountTier] (
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
    [LevelOneComment2]                  NVARCHAR (200) NULL,
    [LevelTwoComment2]                  NVARCHAR (200) NULL,
    [LevelThreeComment2]                NVARCHAR (200) NULL,
    PRIMARY KEY CLUSTERED ([SOpsCallPlanOneLevelAccountTierId] ASC),
    CONSTRAINT [FK_SOpsCallPlanOneLevelAccountTier_FieldTerritoryId] FOREIGN KEY ([FieldTerritoryId]) REFERENCES [web].[SOpsTerritory] ([SOpsTerritoryId]),
    CONSTRAINT [FK_SOpsCallPlanOneLevelAccountTier_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [web].[SOpsAccount] ([SOpsAccountId]),
    CONSTRAINT [FK_SOpsCallPlanOneLevelAccountTier_SOpsCallPlanId] FOREIGN KEY ([SOpsCallPlanId]) REFERENCES [web].[SOpsCallPlan] ([SOpsCallPlanId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanOneLevelAccountTier_SOpsCallPlanId]
    ON [web].[SOpsCallPlanOneLevelAccountTier]([SOpsCallPlanId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanOneLevelAccountTier_FieldTerritoryId]
    ON [web].[SOpsCallPlanOneLevelAccountTier]([FieldTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCallPlanOneLevelAccountTier_SOpsAccountId]
    ON [web].[SOpsCallPlanOneLevelAccountTier]([SOpsAccountId] ASC);

