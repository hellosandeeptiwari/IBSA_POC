CREATE TABLE [web].[SOpsCallPlanPeriodUserSubmission] (
    [SOpsCallPlanPeriodUserSubmissionId] INT          IDENTITY (1, 1) NOT NULL,
    [SOpsCallPlanPeriodId]               INT          NOT NULL,
    [Status]                             NVARCHAR (4) NOT NULL,
    [SOpsUserId]                         INT          NOT NULL,
    [SOpsTerritoryId]                    INT          NOT NULL,
    [SubmissionDate]                     DATETIME     NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsCallPlanPeriodUserSubmissionId] ASC),
    CONSTRAINT [FK_SOpsCallPlanPeriodUserSubmission_SOpsCallPlanPeriodId] FOREIGN KEY ([SOpsCallPlanPeriodId]) REFERENCES [web].[SOpsCallPlanPeriod] ([SOpsCallPlanPeriodId]),
    CONSTRAINT [FK_SOpsCallPlanPeriodUserSubmission_SOpsTerritoryId] FOREIGN KEY ([SOpsTerritoryId]) REFERENCES [web].[SOpsTerritory] ([SOpsTerritoryId]),
    CONSTRAINT [FK_SOpsCallPlanPeriodUserSubmission_SOpsUserId] FOREIGN KEY ([SOpsUserId]) REFERENCES [web].[SOpsUser] ([SOpsUserId]),
    CONSTRAINT [SOpsCallPlanPeriodUserSubmission_SOpsCallPlanPeriodId_SOpsUserId_SOpsTerritoryId] UNIQUE NONCLUSTERED ([SOpsCallPlanPeriodId] ASC, [SOpsUserId] ASC, [SOpsTerritoryId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_SOpsCPPeriodUserSubmissionId]
    ON [web].[SOpsCallPlanPeriodUserSubmission]([SOpsCallPlanPeriodUserSubmissionId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_SOpsCallPlanPeriodId]
    ON [web].[SOpsCallPlanPeriodUserSubmission]([SOpsCallPlanPeriodId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_SOpsUserId]
    ON [web].[SOpsCallPlanPeriodUserSubmission]([SOpsUserId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_SOpsTerritoryId]
    ON [web].[SOpsCallPlanPeriodUserSubmission]([SOpsTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_Status]
    ON [web].[SOpsCallPlanPeriodUserSubmission]([Status] ASC);

