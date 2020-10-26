CREATE TABLE [dbo].[Reporting_IC_Details] (
    [Territory]                         VARCHAR (500)  NULL,
    [Territory Name]                    VARCHAR (500)  NULL,
    [Rep Name]                          VARCHAR (500)  NULL,
    [Baseline]                          INT            NULL,
    [Q4 New baseline]                   INT            NULL,
    [Q4 Sales]                          INT            NULL,
    [Volume Growth]                     INT            NULL,
    [Volume Growth % Change]            INT            NULL,
    [Volume Rank]                       INT            NULL,
    [% Growth Rank]                     INT            NULL,
    [Weighted Rank]                     DECIMAL (9, 1) NULL,
    [Final Rank based on Weighted Rank] INT            NULL,
    [Hire Date]                         VARCHAR (50)   NULL,
    [Original Payout]                   INT            NULL,
    [Adjusted Payout]                   INT            NULL,
    [Notes]                             VARCHAR (500)  NULL
);

