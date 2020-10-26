CREATE TABLE [web].[SOpsAccountTierAudit] (
    [SOpsAccountTierAuditId] INT             IDENTITY (1, 1) NOT NULL,
    [SOpsCallPlanId]         INT             NOT NULL,
    [SOpsCallPlanPeriodId]   INT             NOT NULL,
    [SOpsTerritoryId]        INT             NOT NULL,
    [SOpsAccountId]          INT             NOT NULL,
    [SOpsUserId]             INT             NULL,
    [PlatformUserId]         INT             NULL,
    [PlatformEmail]          NVARCHAR (2000) NULL,
    [OldTier]                NVARCHAR (200)  NULL,
    [NewTier]                NVARCHAR (200)  NOT NULL,
    [Comment]                NVARCHAR (2000) NULL,
    [CreatorType]            NVARCHAR (4)    NOT NULL,
    [CreatedDate]            DATETIME        NOT NULL,
    [Comment2]               NVARCHAR (2000) NULL,
    PRIMARY KEY CLUSTERED ([SOpsAccountTierAuditId] ASC),
    CONSTRAINT [FK_SOpsAccountTierAudit_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [web].[SOpsAccount] ([SOpsAccountId]),
    CONSTRAINT [FK_SOpsAccountTierAudit_SOpsCallPlanId] FOREIGN KEY ([SOpsCallPlanId]) REFERENCES [web].[SOpsCallPlan] ([SOpsCallPlanId]),
    CONSTRAINT [FK_SOpsAccountTierAudit_SOpsCallPlanPeriodId] FOREIGN KEY ([SOpsCallPlanPeriodId]) REFERENCES [web].[SOpsCallPlanPeriod] ([SOpsCallPlanPeriodId]),
    CONSTRAINT [FK_SOpsAccountTierAudit_SOpsTerritoryId] FOREIGN KEY ([SOpsTerritoryId]) REFERENCES [web].[SOpsTerritory] ([SOpsTerritoryId]),
    CONSTRAINT [FK_SOpsAccountTierAudit_SOpsUserId] FOREIGN KEY ([SOpsUserId]) REFERENCES [web].[SOpsUser] ([SOpsUserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTierAudit_SOpsCallPlanId]
    ON [web].[SOpsAccountTierAudit]([SOpsCallPlanId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTierAudit_SOpsCallPlanPeriodId]
    ON [web].[SOpsAccountTierAudit]([SOpsCallPlanPeriodId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTierAudit_SOpsTerritoryId]
    ON [web].[SOpsAccountTierAudit]([SOpsTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTierAudit_SOpsAccountId]
    ON [web].[SOpsAccountTierAudit]([SOpsAccountId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTierAudit_SOpsUserId]
    ON [web].[SOpsAccountTierAudit]([SOpsUserId] ASC);

