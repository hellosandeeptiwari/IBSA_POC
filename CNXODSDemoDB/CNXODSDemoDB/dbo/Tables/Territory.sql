CREATE TABLE [dbo].[Territory] (
    [Id]                INT              IDENTITY (1, 1) NOT NULL,
    [EndDate]           DATETIME         NULL,
    [CreatedDate]       DATETIME         NULL,
    [UpdatedDate]       DATETIME         NULL,
    [ExternalId1]       VARCHAR (400)    NULL,
    [TerritoryId]       UNIQUEIDENTIFIER NULL,
    [Name]              VARCHAR (400)    NULL,
    [ParentTerritoryId] VARCHAR (400)    NULL,
    [Description]       VARCHAR (400)    NULL,
    [LastModifiedDate]  VARCHAR (400)    NULL,
    [LastModifiedById]  VARCHAR (400)    NULL,
    [SystemModstamp]    VARCHAR (400)    NULL,
    [MasterAlignId]     VARCHAR (400)    NULL,
    CONSTRAINT [PK_Territory] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE TRIGGER [dbo].[trg_Territory] on [dbo].[Territory] INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN

	-- To suppress messages from the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT TerritoryId, Name, ParentTerritoryId, Description into #deleted from DELETED where EndDate IS NULL;

	IF EXISTS (select 1 from INSERTED)
	BEGIN
		IF exists (select 1 from #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			select * into #insertedUPDATE from INSERTED where EndDate IS NULL;

			--declare necessary variables to store temporary values
			declare @NameINSERT varchar(400), @ParentTerritoryIdINSERT varchar(400), @DescriptionINSERT varchar(400),  
				@NameDELETE varchar(400), @ParentTerritoryIdDELETE varchar(400), @DescriptionDELETE varchar(400), 
				@PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = count(*) from #insertedUPDATE;
			While @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = TerritoryId, @NameINSERT = Name, @ParentTerritoryIdINSERT = ParentTerritoryId, @DescriptionINSERT = Description
				from #insertedUPDATE;

				SELECT
					@NameDELETE = Name, @ParentTerritoryIdDELETE = ParentTerritoryId, @DescriptionDELETE = Description
				from #deleted WHERE TerritoryId = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF 
					@NameINSERT <> @NameDELETE OR (@NameINSERT IS NULL AND @NameDELETE IS NOT NULL) OR (@NameINSERT IS NOT NULL AND @NameDELETE IS NULL) OR @ParentTerritoryIdINSERT <> @ParentTerritoryIdDELETE OR (@ParentTerritoryIdINSERT IS NULL AND @ParentTerritoryIdDELETE IS NOT NULL) OR (@ParentTerritoryIdINSERT IS NOT NULL AND @ParentTerritoryIdDELETE IS NULL) OR @DescriptionINSERT <> @DescriptionDELETE OR (@DescriptionINSERT IS NULL AND @DescriptionDELETE IS NOT NULL) OR (@DescriptionINSERT IS NOT NULL AND @DescriptionDELETE IS NULL)
					BEGIN
						UPDATE [Territory] SET EndDate = GETDATE() WHERE TerritoryId = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [Territory](CreatedDate, UpdatedDate, ExternalId1, TerritoryId, Name, ParentTerritoryId, Description, LastModifiedDate, LastModifiedById, SystemModstamp, MasterAlignId)
						SELECT CreatedDate, UpdatedDate, ExternalId1, TerritoryId, Name, ParentTerritoryId, Description, LastModifiedDate, LastModifiedById, SystemModstamp, MasterAlignId
						FROM #insertedUPDATE WHERE TerritoryId = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET T.CreatedDate = I.CreatedDate
						 , T.UpdatedDate = I.UpdatedDate
						 , T.ExternalId1 = I.ExternalId1
						 , T.LastModifiedDate = I.LastModifiedDate
						 , T.LastModifiedById = I.LastModifiedById
						 , T.SystemModstamp = I.SystemModstamp
						 , T.MasterAlignId = I.MasterAlignId
					FROM [Territory] T INNER JOIN #insertedUPDATE I ON T.TerritoryId = I.TerritoryId AND I.TerritoryId = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				delete from #insertedUPDATE where TerritoryId = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (select 1 from DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [Territory](CreatedDate, UpdatedDate, ExternalId1, TerritoryId, Name, ParentTerritoryId, Description, LastModifiedDate, LastModifiedById, SystemModstamp, MasterAlignId)
				SELECT CreatedDate, UpdatedDate, ExternalId1, TerritoryId, Name, ParentTerritoryId, Description, LastModifiedDate, LastModifiedById, SystemModstamp, MasterAlignId FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [Territory] SET EndDate = GETDATE() WHERE TerritoryId IN (SELECT TerritoryId FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END

