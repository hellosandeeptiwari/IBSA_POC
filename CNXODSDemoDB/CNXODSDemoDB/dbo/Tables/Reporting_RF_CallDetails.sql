CREATE TABLE [dbo].[Reporting_RF_CallDetails] (
    [PK]                NVARCHAR (100)   NULL,
    [UserId]            UNIQUEIDENTIFIER NOT NULL,
    [Rep Name]          NVARCHAR (400)   NULL,
    [TerritoryId]       UNIQUEIDENTIFIER NOT NULL,
    [Territory]         NVARCHAR (400)   NULL,
    [Target Type]       NVARCHAR (20)    NULL,
    [TargetTypeInteger] INT              NULL,
    [QuarterString]     NVARCHAR (20)    NULL,
    [HCP Name]          NVARCHAR (400)   NULL,
    [Specialty]         NVARCHAR (200)   NULL,
    [Last Call Date]    DATE             NULL,
    [Actual Calls]      INT              NULL,
    [Freq Achieved?]    INT              NULL
);

