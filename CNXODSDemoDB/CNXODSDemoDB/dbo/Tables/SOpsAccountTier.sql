CREATE TABLE [dbo].[SOpsAccountTier] (
    [SOpsAccountTierId]  INT            IDENTITY (1, 1) NOT NULL,
    [FutureCallPlanTier] BIT            NOT NULL,
    [Value]              NVARCHAR (200) NOT NULL,
    [NumberOfCalls]      INT            NOT NULL,
    [Sequence]           INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsAccountTierId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTier_SOpsAccountTierId]
    ON [dbo].[SOpsAccountTier]([SOpsAccountTierId] ASC);

