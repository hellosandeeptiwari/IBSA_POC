CREATE TABLE [dbo].[Reporting_RF_ManagerSummary] (
    [UserId]                UNIQUEIDENTIFIER NOT NULL,
    [ManagerName]           NVARCHAR (400)   NULL,
    [TargetType]            NVARCHAR (20)    NULL,
    [TargetTypeInteger]     INT              NULL,
    [QuarterString]         NVARCHAR (20)    NULL,
    [WorkDays]              INT              NULL,
    [#Targets]              INT              NULL,
    [#TargetCalled]         INT              NULL,
    [#Calls]                INT              NULL,
    [DesiredCalls]          INT              NULL,
    [% Reach]               NVARCHAR (20)    NULL,
    [Freq Goal per HCP]     INT              NULL,
    [#Targets FreqAchieved] INT              NULL,
    [Freq %]                INT              NULL,
    [Req Freq %]            INT              NULL
);

