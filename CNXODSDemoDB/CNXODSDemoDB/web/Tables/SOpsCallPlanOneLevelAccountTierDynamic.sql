DROP TABLE [web].[SOpsCallPlanOneLevelAccountTierDynamic] ;
GO
CREATE TABLE [web].[SOpsCallPlanOneLevelAccountTierDynamic] (
    [SOpsCallPlanOneLevelAccountTierDynamicId] int NOT NULL IDENTITY(1,1),
    [SOpsCallPlanOneLevelAccountTierId] int NOT NULL CONSTRAINT FK_SOpsCallPlanOneLevelAccountTierDynamic_SOpsCallPlanOneLevelAccountTierId FOREIGN KEY REFERENCES [web].[SOpsCallPlanOneLevelAccountTier] ([SOpsCallPlanOneLevelAccountTierId]),
    [SOpsCallPlanPeriodId] int NOT NULL,
    [FieldTerritoryId] int NOT NULL,
    [SOpsAccountId] int NOT NULL,
    [SOpsUserId] int NOT NULL,
    [TextField1] nvarchar(2000) NULL,
    [TextField2] nvarchar(2000) NULL,
    [TextField3] nvarchar(2000) NULL,
    [TextField4] nvarchar(2000) NULL,
    [TextField5] nvarchar(2000) NULL,
    [TextField6] nvarchar(2000) NULL,
    [TextField7] nvarchar(2000) NULL,
    [TextField8] nvarchar(2000) NULL,
    [TextField9] nvarchar(2000) NULL,
    [TextField10] nvarchar(2000) NULL,	
    [TextField11] nvarchar(2000) NULL,
    [TextField12] nvarchar(2000) NULL,
    [TextField13] nvarchar(2000) NULL,
    [TextField14] nvarchar(2000) NULL,
    [TextField15] nvarchar(2000) NULL,
    [TextField16] nvarchar(2000) NULL,
    [TextField17] nvarchar(2000) NULL,
    [TextField18] nvarchar(2000) NULL,
    [TextField19] nvarchar(2000) NULL,
    [TextField20] nvarchar(2000) NULL,
    [CodeField1] nvarchar(4) NULL,
    [CodeField2] nvarchar(4) NULL,
    [CodeField3] nvarchar(4) NULL,
    [CodeField4] nvarchar(4) NULL,
    [CodeField5] nvarchar(4) NULL,
    PRIMARY KEY ([SOpsCallPlanOneLevelAccountTierDynamicId]),
);
ALTER TABLE [web].[SOpsCallPlanOneLevelAccountTierDynamic]  ADD CONSTRAINT 
[UC_SOpsCallPlanOneLevelAccountTierDynamic_SOpsCallPlanPeriodId_FieldTerritoryId_SOpsAccountId_SOpsUserId] UNIQUE 
([SOpsCallPlanOneLevelAccountTierId],[SOpsCallPlanPeriodId],[FieldTerritoryId],[SOpsAccountId],[SOpsUserId]);


CREATE INDEX IX_SOpsCallPlanOneLevelAccountTierDynamic_SOpsCallPlanOneLevelAccountTierId ON [web].[SOpsCallPlanOneLevelAccountTierDynamic] ([SOpsCallPlanOneLevelAccountTierId]);
CREATE INDEX IX_SOpsCallPlanOneLevelAccountTierDynamic_FieldTerritoryId ON [web].[SOpsCallPlanOneLevelAccountTierDynamic] ([FieldTerritoryId]);
CREATE INDEX IX_SOpsCallPlanOneLevelAccountTierDynamic_SOpsAccountId ON [web].[SOpsCallPlanOneLevelAccountTierDynamic] ([SOpsAccountId]);
GO