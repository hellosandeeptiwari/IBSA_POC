CREATE TABLE [dbo].[SOpsCallPlanPeriodUserSubmission] (
    [SOpsCallPlanPeriodUserSubmissionId] INT          IDENTITY (1, 1) NOT NULL,
    [SOpsCallPlanPeriodId]               INT          NOT NULL,
    [Status]                             NVARCHAR (4) NOT NULL,
    [SOpsUserId]                         INT          NOT NULL,
    [SOpsTerritoryId]                    INT          NOT NULL,
    [SubmissionDate]                     DATETIME     NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsCallPlanPeriodUserSubmissionId] ASC),
    CONSTRAINT [FK_SOpsCallPlanPeriodUserSubmission_SOpsCallPlanPeriodId] FOREIGN KEY ([SOpsCallPlanPeriodId]) REFERENCES [dbo].[SOpsCallPlanPeriod] ([SOpsCallPlanPeriodId]),
    CONSTRAINT [FK_SOpsCallPlanPeriodUserSubmission_SOpsTerritoryId] FOREIGN KEY ([SOpsTerritoryId]) REFERENCES [dbo].[SOpsTerritory] ([SOpsTerritoryId]),
    CONSTRAINT [FK_SOpsCallPlanPeriodUserSubmission_SOpsUserId] FOREIGN KEY ([SOpsUserId]) REFERENCES [dbo].[SOpsUser] ([SOpsUserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_SOpsCPPeriodUserSubmissionId]
    ON [dbo].[SOpsCallPlanPeriodUserSubmission]([SOpsCallPlanPeriodUserSubmissionId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_SOpsCallPlanPeriodId]
    ON [dbo].[SOpsCallPlanPeriodUserSubmission]([SOpsCallPlanPeriodId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_SOpsUserId]
    ON [dbo].[SOpsCallPlanPeriodUserSubmission]([SOpsUserId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_SOpsTerritoryId]
    ON [dbo].[SOpsCallPlanPeriodUserSubmission]([SOpsTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsCPPeriodUserSubmission_Status]
    ON [dbo].[SOpsCallPlanPeriodUserSubmission]([Status] ASC);

