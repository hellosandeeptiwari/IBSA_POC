CREATE TABLE [dbo].[UserTerritory] (
    [Id]               INT              IDENTITY (1, 1) NOT NULL,
    [EndDate]          DATETIME         NULL,
    [CreatedDate]      DATETIME         NULL,
    [UpdatedDate]      DATETIME         NULL,
    [ExternalId1]      VARCHAR (400)    NULL,
    [UserTerritoryId]  UNIQUEIDENTIFIER NULL,
    [UserId]           VARCHAR (400)    NULL,
    [TerritoryId]      VARCHAR (400)    NULL,
    [IsActive]         VARCHAR (400)    NULL,
    [LastModifiedDate] VARCHAR (400)    NULL,
    [LastModifiedById] VARCHAR (400)    NULL,
    [SystemModstamp]   VARCHAR (400)    NULL,
    CONSTRAINT [PK_UserTerritory] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE TRIGGER [dbo].[trg_UserTerritory] on [dbo].[UserTerritory] INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN

	-- To suppress messages from the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT UserTerritoryId, UserId, TerritoryId, IsActive into #deleted from DELETED where EndDate IS NULL;

	IF EXISTS (select 1 from INSERTED)
	BEGIN
		IF exists (select 1 from #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			select * into #insertedUPDATE from INSERTED where EndDate IS NULL;

			--declare necessary variables to store temporary values
			declare @UserIdINSERT varchar(400), @TerritoryIdINSERT varchar(400), @IsActiveINSERT varchar(400),  
				@UserIdDELETE varchar(400), @TerritoryIdDELETE varchar(400), @IsActiveDELETE varchar(400), 
				@PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = count(*) from #insertedUPDATE;
			While @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = UserTerritoryId, @UserIdINSERT = UserId, @TerritoryIdINSERT = TerritoryId, @IsActiveINSERT = IsActive
				from #insertedUPDATE;

				SELECT
					@UserIdDELETE = UserId, @TerritoryIdDELETE = TerritoryId, @IsActiveDELETE = IsActive
				from #deleted WHERE UserTerritoryId = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF 
					@UserIdINSERT <> @UserIdDELETE OR (@UserIdINSERT IS NULL AND @UserIdDELETE IS NOT NULL) OR (@UserIdINSERT IS NOT NULL AND @UserIdDELETE IS NULL) OR @TerritoryIdINSERT <> @TerritoryIdDELETE OR (@TerritoryIdINSERT IS NULL AND @TerritoryIdDELETE IS NOT NULL) OR (@TerritoryIdINSERT IS NOT NULL AND @TerritoryIdDELETE IS NULL) OR @IsActiveINSERT <> @IsActiveDELETE OR (@IsActiveINSERT IS NULL AND @IsActiveDELETE IS NOT NULL) OR (@IsActiveINSERT IS NOT NULL AND @IsActiveDELETE IS NULL)
					BEGIN
						UPDATE [UserTerritory] SET EndDate = GETDATE() WHERE UserTerritoryId = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [UserTerritory](CreatedDate, UpdatedDate, ExternalId1, UserTerritoryId, UserId, TerritoryId, IsActive, LastModifiedDate, LastModifiedById, SystemModstamp)
						SELECT CreatedDate, UpdatedDate, ExternalId1, UserTerritoryId, UserId, TerritoryId, IsActive, LastModifiedDate, LastModifiedById, SystemModstamp
						FROM #insertedUPDATE WHERE UserTerritoryId = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET T.CreatedDate = I.CreatedDate
						 , T.UpdatedDate = I.UpdatedDate
						 , T.ExternalId1 = I.ExternalId1
						 , T.LastModifiedDate = I.LastModifiedDate
						 , T.LastModifiedById = I.LastModifiedById
						 , T.SystemModstamp = I.SystemModstamp
					FROM [UserTerritory] T INNER JOIN #insertedUPDATE I ON T.UserTerritoryId = I.UserTerritoryId AND I.UserTerritoryId = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				delete from #insertedUPDATE where UserTerritoryId = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (select 1 from DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [UserTerritory](CreatedDate, UpdatedDate, ExternalId1, UserTerritoryId, UserId, TerritoryId, IsActive, LastModifiedDate, LastModifiedById, SystemModstamp)
				SELECT CreatedDate, UpdatedDate, ExternalId1, UserTerritoryId, UserId, TerritoryId, IsActive, LastModifiedDate, LastModifiedById, SystemModstamp FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [UserTerritory] SET EndDate = GETDATE() WHERE UserTerritoryId IN (SELECT UserTerritoryId FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END

