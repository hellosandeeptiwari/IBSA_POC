CREATE TABLE [web].[SOpsAccountReview] (
    [SOpsReviewSupportId]  INT             IDENTITY (1, 1) NOT NULL,
    [SOpsCallPlanId]       INT             NOT NULL,
    [SOpsTerritoryId]      INT             NOT NULL,
    [SOpsAccountId]        INT             NOT NULL,
    [AccountName]          NVARCHAR (200)  NOT NULL,
    [CRMId]                NVARCHAR (200)  NULL,
    [AddressLine1]         NVARCHAR (2000) NULL,
    [City]                 NVARCHAR (200)  NULL,
    [State]                NVARCHAR (4)    NULL,
    [Specialty]            NVARCHAR (200)  NULL,
    [CurrentTierValue]     NVARCHAR (200)  NULL,
    [RecommendedTierValue] NVARCHAR (200)  NULL,
    [ExternalId1]          NVARCHAR (200)  NULL,
    [ExternalId2]          NVARCHAR (200)  NULL,
    [ExternalId3]          NVARCHAR (200)  NULL,
    [ExternalId4]          NVARCHAR (200)  NULL,
    [ExternalId5]          NVARCHAR (200)  NULL,
    [ExternalId6]          NVARCHAR (200)  NULL,
    [ExternalId7]          NVARCHAR (200)  NULL,
    [ExternalId8]          NVARCHAR (200)  NULL,
    PRIMARY KEY CLUSTERED ([SOpsReviewSupportId] ASC),
    CONSTRAINT [FK_SOpsAccountReview_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [web].[SOpsAccount] ([SOpsAccountId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountReview_SOpsReviewSupportId]
    ON [web].[SOpsAccountReview]([SOpsReviewSupportId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountReview_SOpsCallPlanId]
    ON [web].[SOpsAccountReview]([SOpsCallPlanId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountReview_SOpsTerritoryId]
    ON [web].[SOpsAccountReview]([SOpsTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountReview_SOpsAccountId]
    ON [web].[SOpsAccountReview]([SOpsAccountId] ASC);

