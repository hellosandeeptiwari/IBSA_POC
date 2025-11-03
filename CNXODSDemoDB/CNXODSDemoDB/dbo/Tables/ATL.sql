CREATE TABLE [dbo].[ATL] (
    [Id]               INT              IDENTITY (1, 1) NOT NULL,
    [EndDate]          DATETIME         NULL,
    [CreatedDate]      DATETIME         NULL,
    [UpdatedDate]      DATETIME         NULL,
    [ExternalId1]      VARCHAR (400)    NULL,
    [ATLId]            UNIQUEIDENTIFIER NULL,
    [OwnerId]          VARCHAR (400)    NULL,
    [IsDeleted]        VARCHAR (400)    NULL,
    [Name]             VARCHAR (400)    NULL,
    [VeevaCreatedDate] VARCHAR (400)    NULL,
    [VeevaCreatedById] VARCHAR (400)    NULL,
    [LastModifiedDate] VARCHAR (400)    NULL,
    [LastModifiedById] VARCHAR (400)    NULL,
    [SystemModstamp]   VARCHAR (400)    NULL,
    [MayEdit]          VARCHAR (400)    NULL,
    [IsLocked]         VARCHAR (400)    NULL,
    [Account]          VARCHAR (400)    NULL,
    [ExternalID]       VARCHAR (400)    NULL,
    [Territory]        VARCHAR (400)    NULL,
    [MobileID]         VARCHAR (400)    NULL,
    [TerritoryToAdd]   VARCHAR (400)    NULL,
    [TerritorytoDrop]  VARCHAR (400)    NULL,
    CONSTRAINT [PK_ATL] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE TRIGGER [dbo].[trg_ATL] on [dbo].[ATL] INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN

	-- To suppress messages from the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT ATLId, Account, Territory into #deleted from DELETED where EndDate IS NULL;

	IF EXISTS (select 1 from INSERTED)
	BEGIN
		IF exists (select 1 from #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			select * into #insertedUPDATE from INSERTED where EndDate IS NULL;

			--declare necessary variables to store temporary values
			declare @AccountINSERT varchar(400), @TerritoryINSERT varchar(400),  
				@AccountDELETE varchar(400), @TerritoryDELETE varchar(400), 
				@PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = count(*) from #insertedUPDATE;
			While @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = ATLId, @AccountINSERT = Account, @TerritoryINSERT = Territory
				from #insertedUPDATE;

				SELECT
					@AccountDELETE = Account, @TerritoryDELETE = Territory
				from #deleted WHERE ATLId = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF 
					@AccountINSERT <> @AccountDELETE OR (@AccountINSERT IS NULL AND @AccountDELETE IS NOT NULL) OR (@AccountINSERT IS NOT NULL AND @AccountDELETE IS NULL) OR @TerritoryINSERT <> @TerritoryDELETE OR (@TerritoryINSERT IS NULL AND @TerritoryDELETE IS NOT NULL) OR (@TerritoryINSERT IS NOT NULL AND @TerritoryDELETE IS NULL)
					BEGIN
						UPDATE [ATL] SET EndDate = GETDATE() WHERE ATLId = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [ATL](CreatedDate, UpdatedDate, ExternalId1, ATLId, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, ExternalID, Territory, MobileID, TerritoryToAdd, TerritorytoDrop, EndDate)
						SELECT CreatedDate, UpdatedDate, ExternalId1, ATLId, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, ExternalID, Territory, MobileID, TerritoryToAdd, TerritorytoDrop, CASE WHEN IsDeleted = 'True' THEN GETDATE() END
						FROM #insertedUPDATE WHERE ATLId = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET T.CreatedDate = I.CreatedDate
						 , T.UpdatedDate = I.UpdatedDate
						 , T.ExternalId1 = I.ExternalId1
						 , T.OwnerId = I.OwnerId
						 , T.IsDeleted = I.IsDeleted
						 , T.Name = I.Name
						 , T.VeevaCreatedDate = I.VeevaCreatedDate
						 , T.VeevaCreatedById = I.VeevaCreatedById
						 , T.LastModifiedDate = I.LastModifiedDate
						 , T.LastModifiedById = I.LastModifiedById
						 , T.SystemModstamp = I.SystemModstamp
						 , T.MayEdit = I.MayEdit
						 , T.IsLocked = I.IsLocked
						 , T.ExternalID = I.ExternalID
						 , T.MobileID = I.MobileID
						 , T.TerritoryToAdd = I.TerritoryToAdd
						 , T.TerritorytoDrop = I.TerritorytoDrop, T.EndDate = CASE WHEN I.IsDeleted = 'True' THEN GETDATE() END 
					FROM [ATL] T INNER JOIN #insertedUPDATE I ON T.ATLId = I.ATLId AND I.ATLId = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				delete from #insertedUPDATE where ATLId = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (select 1 from DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [ATL](CreatedDate, UpdatedDate, ExternalId1, ATLId, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, ExternalID, Territory, MobileID, TerritoryToAdd, TerritorytoDrop, EndDate)
				SELECT CreatedDate, UpdatedDate, ExternalId1, ATLId, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, ExternalID, Territory, MobileID, TerritoryToAdd, TerritorytoDrop, CASE WHEN IsDeleted = 'True' THEN GETDATE() END FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [ATL] SET EndDate = GETDATE() WHERE ATLId IN (SELECT ATLId FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END

