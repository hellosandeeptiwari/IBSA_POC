CREATE TABLE [dbo].[SOpsCallPlanPeriod] (
    [SOpsCallPlanPeriodId] INT            IDENTITY (1, 1) NOT NULL,
    [SOpsCallPlanId]       INT            NOT NULL,
    [LevelCode]            NVARCHAR (4)   NOT NULL,
    [Description]          NVARCHAR (200) NULL,
    [StartDate]            DATE           NULL,
    [EndDate]              DATE           NULL,
    [Sequence]             INT            NOT NULL,
    [UILabel]              NVARCHAR (50)  NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsCallPlanPeriodId] ASC),
    CONSTRAINT [FK_SOpsCallPlanPeriod_SOpsCallPlanId] FOREIGN KEY ([SOpsCallPlanId]) REFERENCES [dbo].[SOpsCallPlan] ([SOpsCallPlanId])
);

