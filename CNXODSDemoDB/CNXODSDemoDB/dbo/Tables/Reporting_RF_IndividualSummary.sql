CREATE TABLE [dbo].[Reporting_RF_IndividualSummary] (
    [PK]                    NVARCHAR (100)   NULL,
    [UserId]                UNIQUEIDENTIFIER NOT NULL,
    [RepName]               NVARCHAR (400)   NULL,
    [TerritoryId]           UNIQUEIDENTIFIER NOT NULL,
    [Territory]             NVARCHAR (400)   NULL,
    [TargetType]            NVARCHAR (20)    NULL,
    [TargetTypeInteger]     INT              NULL,
    [QuarterString]         NVARCHAR (20)    NULL,
    [#Targets]              INT              NULL,
    [#TargetCalled]         INT              NULL,
    [#Calls]                INT              NULL,
    [DesiredCalls]          INT              NULL,
    [% Reach]               NVARCHAR (20)    NULL,
    [Freq Goal per HCP]     INT              NULL,
    [WorkDays]              INT              NULL,
    [#Targets FreqAchieved] INT              NULL,
    [Freq %]                INT              NULL,
    [Req Freq %]            INT              NULL
);

