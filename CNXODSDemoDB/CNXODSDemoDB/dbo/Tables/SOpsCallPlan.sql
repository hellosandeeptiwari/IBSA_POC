CREATE TABLE [dbo].[SOpsCallPlan] (
    [SOpsCallPlanId]   INT             IDENTITY (1, 1) NOT NULL,
    [Name]             NVARCHAR (200)  NOT NULL,
    [StartDate]        DATE            NOT NULL,
    [EndDate]          DATE            NOT NULL,
    [PeriodStartDate]  DATE            NULL,
    [PeriodEndDate]    DATE            NULL,
    [TotalWorkingdays] INT             NULL,
    [TotalHolidays]    INT             NULL,
    [TotalWeekends]    INT             NULL,
    [CreatedBy]        INT             NOT NULL,
    [CreatedDate]      DATETIME        NOT NULL,
    [UpdatedBy]        INT             NULL,
    [LastUpdateDate]   DATETIME        NULL,
    [LevelOfApproval]  NVARCHAR (4)    NULL,
    [Status]           NVARCHAR (4)    NOT NULL,
    [TimeZone]         NVARCHAR (200)  NOT NULL,
    [Description]      NVARCHAR (2000) NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsCallPlanId] ASC)
);

