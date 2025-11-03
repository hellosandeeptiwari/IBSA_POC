CREATE OR ALTER PROCEDURE sp_security_check_user_db_transform
AS
BEGIN

IF EXISTS (	SELECT USER_NAME(member_principal_id) AS [Owner]
			FROM sys.database_role_members
			WHERE USER_NAME(role_principal_id) = 'db_owner'
			AND USER_NAME(member_principal_id) NOT IN ('dbo', 'odsjobsuser', 'Shridevik@cnxsi.com', 'jagadeesham@cnxsi.com'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1258 - Database owners are as expected.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1258 - Database owners are as expected.', 1;
END


IF EXISTS (	SELECT USER_NAME(sr.member_principal_id) as [Principal], USER_NAME(sr.role_principal_id) as [Role], type_desc as [Principal Type], authentication_type_desc as [Authentication Type]
			FROM sys.database_role_members AS sr
			INNER JOIN sys.database_principals AS sp ON sp.principal_id = sr.member_principal_id
			WHERE USER_NAME(member_principal_id) NOT IN ('dbo', 'odsjobsuser', 'odsreportsuser', 'Shridevik@cnxsi.com', 'jagadeesham@cnxsi.com', 'priyankas@cnxsi.com','kundank@cnxsi.com'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2109 - Minimal set of principals should be members of fixed low impact database roles.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2109 - Minimal set of principals should be members of fixed low impact database roles.', 1;
END


;WITH UsersAndRoles (principal_name, sid, type) AS 
(
	SELECT DISTINCT prin.name, prin.sid, prin.type 
	FROM sys.database_principals prin 
		INNER JOIN sys.database_permissions perm 
			ON perm.grantee_principal_id = prin.principal_id 
		WHERE prin.type in ('S', 'X', 'R')
	UNION ALL
	SELECT 
		user_name(rls.member_principal_id), prin.sid, prin.type
	FROM 
		UsersAndRoles cte
		INNER JOIN sys.database_role_members rls
			ON user_name(rls.role_principal_id) = cte.principal_name
		INNER JOIN sys.database_principals prin
			ON rls.member_principal_id = prin.principal_id
		WHERE cte.type = 'R'
),
Users (database_user, sid) AS
(
	SELECT principal_name, sid
	FROM UsersAndRoles
	WHERE type in ('S', 'X')
)
SELECT DISTINCT database_user, sid INTO #temp
FROM Users
WHERE sid != 0x01
AND database_user NOT IN ('dbo','odsjobsuser','odsreportsuser');

IF EXISTS (SELECT 1 FROM #temp)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2130 - Track all users with access to the database.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2130 - Track all users with access to the database.', 1;
END

DROP TABLE IF EXISTS #temp;


IF EXISTS (	SELECT roles.[name] AS [Role]
			FROM sys.database_role_members AS drms
			INNER JOIN sys.database_principals AS roles ON drms.role_principal_id = roles.principal_id
			INNER JOIN sys.database_principals AS users ON drms.member_principal_id = users.principal_id
			WHERE users.[name] = 'guest')
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1020 - Database user GUEST should not be a member of any role.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1020 - Database user GUEST should not be a member of any role.', 1;
END


IF EXISTS (	
	SELECT permission_name, schema_name, object_name
	FROM
	(
		SELECT 
			objs.TYPE COLLATE database_default AS object_type,schema_name(schema_id) COLLATE database_default AS schema_name,
			objs.name COLLATE database_default AS object_name,user_name(grantor_principal_id) COLLATE database_default AS grantor_principal_name,
			permission_name COLLATE database_default AS permission_name,perms.TYPE COLLATE database_default AS TYPE,
			STATE COLLATE database_default AS STATE
		FROM sys.database_permissions AS perms
		INNER JOIN sys.objects AS objs ON objs.object_id = perms.major_id
		WHERE perms.class = 1 -- objects or columns. Other cases are handled by VA1095 which has different remediation syntax
			AND grantee_principal_id = DATABASE_PRINCIPAL_ID('public')
			AND [state] IN ('G','W')
			AND NOT (
				-- These permissions are granted by default to public
				permission_name = 'EXECUTE'
				AND schema_name(schema_id) = 'dbo'
				AND STATE = 'G'
				AND objs.name IN (
								'fn_sysdac_is_dac_creator','fn_sysdac_is_currentuser_sa','fn_sysdac_is_login_creator','fn_sysdac_get_username'
								,'sp_sysdac_ensure_dac_creator','sp_sysdac_add_instance','sp_sysdac_add_history_entry','sp_sysdac_delete_instance'
								,'sp_sysdac_upgrade_instance','sp_sysdac_drop_database','sp_sysdac_rename_database','sp_sysdac_setreadonly_database'
								,'sp_sysdac_rollback_committed_step','sp_sysdac_update_history_entry','sp_sysdac_resolve_pending_entry'
								,'sp_sysdac_rollback_pending_object','sp_sysdac_rollback_all_pending_objects','fn_sysdac_get_currentusername'
								)
				OR permission_name = 'SELECT'
				AND schema_name(schema_id) = 'sys'
				AND STATE = 'G'
				AND objs.name IN (
								'firewall_rules','database_firewall_rules','bandwidth_usage','database_usage','external_library_setup_errors'
								,'sql_feature_restrictions','resource_stats','elastic_pool_resource_stats','dm_database_copies',
								'geo_replication_links','database_error_stats','event_log','database_connection_stats'
								)
				OR permission_name = 'SELECT'
				AND schema_name(schema_id) = 'dbo'
				AND STATE = 'G'
				AND objs.name IN ('sysdac_instances_internal','sysdac_history_internal','sysdac_instances')
			)
	) t
	--ORDER BY object_type,schema_name,object_name,TYPE,STATE
)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1054 - Excessive permissions should not be granted to PUBLIC role on objects or columns.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1054 - Excessive permissions should not be granted to PUBLIC role on objects or columns.', 1;
END


IF EXISTS 
(	
	SELECT REPLACE(perms.class_desc, '_', ' ') AS [Permission Class]
		,CASE
			WHEN perms.class = 0 THEN db_name() -- database
			WHEN perms.class = 3 THEN schema_name(major_id) -- schema
			WHEN perms.class = 4 THEN printarget.NAME -- principal
			WHEN perms.class = 5 THEN asm.NAME -- assembly
			WHEN perms.class = 6 THEN type_name(major_id) -- type
			WHEN perms.class = 10 THEN xmlsc.NAME -- xml schema
			WHEN perms.class = 15 THEN msgt.NAME COLLATE DATABASE_DEFAULT -- message types
			WHEN perms.class = 16 THEN svcc.NAME COLLATE DATABASE_DEFAULT -- service contracts
			WHEN perms.class = 17 THEN svcs.NAME COLLATE DATABASE_DEFAULT -- services
			WHEN perms.class = 18 THEN rsb.NAME COLLATE DATABASE_DEFAULT -- remote service bindings
			WHEN perms.class = 19 THEN rts.NAME COLLATE DATABASE_DEFAULT -- routes
			WHEN perms.class = 23 THEN ftc.NAME -- full text catalog
			WHEN perms.class = 24 THEN sym.NAME -- symmetric key
			WHEN perms.class = 25 THEN crt.NAME -- certificate
			WHEN perms.class = 26 THEN asym.NAME -- assymetric key
			END AS [Object]
		,perms.permission_name AS Permission
	FROM sys.database_permissions AS perms
	LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
	LEFT JOIN sys.assemblies AS asm ON perms.major_id = asm.assembly_id
	LEFT JOIN sys.xml_schema_collections AS xmlsc ON perms.major_id = xmlsc.xml_collection_id
	LEFT JOIN sys.service_message_types AS msgt ON perms.major_id = msgt.message_type_id
	LEFT JOIN sys.service_contracts AS svcc ON perms.major_id = svcc.service_contract_id
	LEFT JOIN sys.services AS svcs ON perms.major_id = svcs.service_id
	LEFT JOIN sys.remote_service_bindings AS rsb ON perms.major_id = rsb.remote_service_binding_id
	LEFT JOIN sys.routes AS rts ON perms.major_id = rts.route_id
	LEFT JOIN sys.database_principals AS printarget ON perms.major_id = printarget.principal_id
	LEFT JOIN sys.symmetric_keys AS sym ON perms.major_id = sym.symmetric_key_id
	LEFT JOIN sys.asymmetric_keys AS asym ON perms.major_id = asym.asymmetric_key_id
	LEFT JOIN sys.certificates AS crt ON perms.major_id = crt.certificate_id
	LEFT JOIN sys.fulltext_catalogs AS ftc ON perms.major_id = ftc.fulltext_catalog_id
	WHERE perms.grantee_principal_id = DATABASE_PRINCIPAL_ID('public')
		AND class != 1 -- Object or Columns (class = 1) are handled by VA1054 and have different remediation syntax
		AND [state] IN ('G','W')
		AND NOT (
			perms.class = 0
			AND prin.NAME = 'public'
			AND perms.major_id = 0
			AND perms.minor_id = 0
			AND permission_name IN ('VIEW ANY COLUMN ENCRYPTION KEY DEFINITION','VIEW ANY COLUMN MASTER KEY DEFINITION')
			)
	--ORDER BY perms.class,object_name(perms.major_id),perms.grantor_principal_id,perms.STATE
)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1095 - Excessive permissions should not be granted to PUBLIC role.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1095 - Excessive permissions should not be granted to PUBLIC role.', 1;
END


IF EXISTS (	SELECT perms.permission_name AS Permission
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE prin.[name] = 'guest' AND perms.class = 0 AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1096 - Principal GUEST should not be granted permissions in the database.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1096 - Principal GUEST should not be granted permissions in the database.', 1;
END


IF EXISTS (	SELECT object_schema_name(major_id) AS [Schema Name], object_name(major_id) AS [Object], perms.permission_name AS Permission
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE prin.[name] = 'guest' AND perms.class = 1 AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1097 - Principal GUEST should not be granted permissions on objects or columns.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1097 - Principal GUEST should not be granted permissions on objects or columns.', 1;
END


IF EXISTS (	SELECT REPLACE(perms.class_desc, '_', ' ') AS [Permission Class], perms.permission_name AS Permission,
				CASE
					WHEN perms.class = 3 THEN schema_name(major_id) -- schema
					WHEN perms.class = 4 THEN printarget.name -- principal
					WHEN perms.class = 5 THEN asm.name -- assembly
					WHEN perms.class = 6 THEN type_name(major_id) -- type
					WHEN perms.class = 24 THEN sym.name -- symmetric key
					WHEN perms.class = 25 THEN crt.name -- certificate
				END AS [Object]
			FROM sys.database_permissions AS perms
			LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			LEFT JOIN sys.assemblies AS asm ON perms.major_id = asm.assembly_id
			LEFT JOIN sys.database_principals AS printarget ON perms.major_id = printarget.principal_id
			LEFT JOIN sys.symmetric_keys AS sym ON perms.major_id = sym.symmetric_key_id
			LEFT JOIN sys.certificates AS crt ON perms.major_id = crt.certificate_id
			WHERE grantee_principal_id IN (SELECT principal_id FROM sys.database_principals WHERE [name] = 'guest')
			AND class IN (3, 4, 5, 6, 10, 15, 16, 17, 18, 19, 23, 24, 25, 26))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1099 - GUEST user should not be granted permissions on database securables.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1099 - GUEST user should not be granted permissions on database securables.', 1;
END


IF ((SELECT count(*) from sys.database_principals  WHERE principal_id >= 5 AND principal_id < 16384 ) <= 0)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1143 - ''dbo'' user should not be used for normal service operation.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1143 - ''dbo'' user should not be used for normal service operation.', 1;
END


IF EXISTS ( SELECT db_name(database_id) as db_name, encryption_state, key_algorithm, key_length, encryptor_type
			FROM sys.dm_database_encryption_keys
			WHERE key_algorithm != 'AES'
			--ORDER BY db_name(database_id), encryption_state, key_algorithm, key_length, encryptor_type
			)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1221 - Database Encryption Symmetric Keys should use AES algorithm.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1221 - Database Encryption Symmetric Keys should use AES algorithm.', 1;
END


IF EXISTS ( SELECT name, issuer_name, cert_serial_number, subject, thumbprint
			FROM sys.certificates
			WHERE key_length < 2048)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1223 - Certificate keys should use at least 2048 bits.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1223 - Certificate keys should use at least 2048 bits.', 1;
END


IF EXISTS ( SELECT name, pvt_key_encryption_type_desc, algorithm_desc
			FROM sys.asymmetric_keys
			WHERE key_length < 2048
			AND NOT (DB_NAME() = 'master' AND name = 'MS_SQLEnableSystemAssemblyLoadingKey')
			--ORDER BY name, pvt_key_encryption_type_desc, algorithm_desc
			)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1224 - Asymmetric keys'' length should be at least 2048 bits.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1224 - Asymmetric keys'' length should be at least 2048 bits.', 1;
END


IF EXISTS ( SELECT name, type
			FROM sys.database_principals
			WHERE type  = 'A')
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1246 - Application roles should not be used.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1246 - Application roles should not be used.', 1;
END


IF EXISTS ( SELECT user_name(roles.role_principal_id) AS [role], user_name(roles.member_principal_id) AS member
			FROM sys.database_role_members AS roles
			INNER JOIN sys.database_principals AS users ON roles.member_principal_id = users.principal_id
				AND roles.role_principal_id >= 16384 AND roles.role_principal_id <= 16393 AND users.type = 'R'
			--ORDER BY user_name(roles.role_principal_id), user_name(roles.member_principal_id)
		  )
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1248 - User-defined database roles should not be members of fixed roles.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1248 - User-defined database roles should not be members of fixed roles.', 1;
END


IF EXISTS ( SELECT USER_NAME(role_principal_id) as role_name, USER_NAME(member_principal_id) as member_name
			FROM sys.database_role_members
			WHERE role_principal_id NOT IN (16384,16385,16386,16387,16389,16390,16391,16392,16393)
				AND USER_NAME(role_principal_id) <> 'dataopsrole'
			--ORDER BY role_principal_id, member_principal_id
		  )
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1281 - All memberships for user-defined roles should be intended.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1281 - All memberships for user-defined roles should be intended.', 1;
END


IF EXISTS ( SELECT name 
			FROM sys.database_principals
			WHERE type = 'R'
			AND principal_id NOT IN (0,16384,16385,16386,16387,16389,16390,16391,16392,16393)
			AND principal_id NOT IN (SELECT distinct role_principal_id FROM sys.database_role_members))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA1282 - Orphan database roles should be removed.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA1282 - Orphan database roles should be removed.', 1;
END


IF EXISTS ( SELECT perms.class_desc AS [Permission Class], perms.permission_name AS Permission, type_desc AS [Principal Type], prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name IN ('CONTROL', 'AUTHENTICATE', 'TAKE OWNERSHIP', 'ALTER ANY ASSEMBLY', 'ALTER ANY DATABASE DDL TRIGGER', 'CREATE DATABASE DDL EVENT NOTIFICATION', 'KILL DATABASE CONNECTION', 'CREATE DATABASE', 'BACKUP DATABASE', 'BACKUP LOG', 'CREATE REMOTE SERVICE BINDING', 'CREATE ROUTE', 'CREATE FULLTEXT CATALOG', 'CREATE ASSEMBLY', 'REFERENCES')
			AND user_name(grantee_principal_id) NOT IN ('guest', 'public')
			AND perms.class = 0
			AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2000 - Minimal set of principals should be granted high impact database-scoped permissions.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2000 - Minimal set of principals should be granted high impact database-scoped permissions.', 1;
END


IF EXISTS ( SELECT
				perms.class_desc AS [Permission Class], object_schema_name(major_id) AS [Schema Name], object_name(major_id) AS [Object],
				perms.permission_name AS Permission, type_desc AS [Principal Type], prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name IN ('CONTROL', 'TAKE OWNERSHIP', 'REFERENCES')
			AND user_name(grantee_principal_id) NOT IN ('guest', 'public')
			AND perms.class = 1
			AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2001 - Minimal set of principals should be granted high impact database-scoped permissions on objects or columns.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2001 - Minimal set of principals should be granted high impact database-scoped permissions on objects or columns.', 1;
END


IF EXISTS ( SELECT 
				REPLACE(perms.class_desc, '_', ' ') AS [Permission Class],perms.permission_name AS Permission,
				prin.type_desc AS [Principal Type],prin.name AS Principal,
				CASE
					WHEN perms.class = 3 THEN schema_name(major_id) -- schema
					WHEN perms.class = 4 THEN printarget.name -- principal
					WHEN perms.class = 5 THEN asm.name -- assembly
					WHEN perms.class = 6 THEN type_name(major_id) -- type
					WHEN perms.class = 24 THEN sym.name -- symmetric key
					WHEN perms.class = 25 THEN crt.name -- certificate
				END AS [Object]
			FROM sys.database_permissions AS perms
			LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			LEFT JOIN sys.assemblies AS asm ON perms.major_id = asm.assembly_id
			LEFT JOIN sys.database_principals AS printarget ON perms.major_id = printarget.principal_id
			LEFT JOIN sys.symmetric_keys AS sym ON perms.major_id = sym.symmetric_key_id
			LEFT JOIN sys.certificates AS crt ON perms.major_id = crt.certificate_id
			WHERE permission_name IN ('CONTROL', 'TAKE OWNERSHIP', 'REFERENCES')
			AND prin.name <> 'dataopsrole' AND class IN (3, 4, 5, 6, 10, 15, 16, 17, 18, 19, 23, 24, 25, 26) AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2002 - Minimal set of principals should be granted high impact database-scoped permissions on various securables.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2002 - Minimal set of principals should be granted high impact database-scoped permissions on various securables.', 1;
END


IF EXISTS ( SELECT perms.class_desc AS [Permission Class],perms.permission_name AS Permission,type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name IN ('ALTER ANY ROLE', 'ALTER ANY APPLICATION ROLE', 'ALTER ANY SCHEMA', 'ALTER ANY DATASPACE', 'ALTER ANY MESSAGE TYPE', 'ALTER ANY CONTRACT', 'ALTER ANY SERVICE', 'ALTER ANY REMOTE SERVICE BINDING', 'ALTER ANY ROUTE', 'ALTER ANY FULLTEXT CATALOG', 'ALTER ANY SYMMETRIC KEY', 'ALTER ANY ASYMMETRIC KEY', 'ALTER ANY CERTIFICATE', 'ALTER ANY DATABASE EVENT NOTIFICATION', 'ALTER ANY DATABASE AUDIT', 'ALTER ANY DATABASE EVENT SESSION', 'SHOWPLAN', 'CONNECT REPLICATION', 'CHECKPOINT', 'SUBSCRIBE QUERY NOTIFICATIONS', 'VIEW DATABASE STATE', 'CREATE TABLE', 'CREATE VIEW', 'CREATE PROCEDURE', 'CREATE FUNCTION', 'CREATE RULE', 'CREATE DEFAULT', 'CREATE TYPE', 'CREATE XML SCHEMA COLLECTION', 'CREATE SCHEMA', 'CREATE SYNONYM', 'CREATE AGGREGATE', 'CREATE ROLE', 'CREATE MESSAGE TYPE', 'CREATE SERVICE', 'CREATE CONTRACT', 'CREATE QUEUE', 'CREATE SYMMETRIC KEY', 'CREATE ASYMMETRIC KEY', 'CREATE CERTIFICATE')
			AND prin.name <> 'dataopsrole' AND perms.class = 0 AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2010 - Minimal set of principals should be granted medium impact database-scoped permissions.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2010 - Minimal set of principals should be granted medium impact database-scoped permissions.', 1;
END


IF EXISTS ( SELECT perms.class_desc AS [Permission Class],perms.permission_name AS Permission,type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name IN ('ALTER','ALTER ANY USER')
				AND perms.class = 0
				AND [state] IN ('G','W')
				AND NOT (prin.type = 'S' AND prin.name = 'dbo' AND prin.authentication_type = 1 AND prin.owning_principal_id IS NULL))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2020 - Minimal set of principals should be granted ALTER or ALTER ANY USER database-scoped permissions.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2020 - Minimal set of principals should be granted ALTER or ALTER ANY USER database-scoped permissions.', 1;
END


IF EXISTS ( SELECT 
				perms.class_desc AS [Permission Class],object_schema_name(major_id) AS [Schema Name],object_name(major_id) AS [Object]
				,perms.permission_name AS Permission,type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name = 'ALTER'
				AND perms.class = 1
				AND [state] IN ('G', 'W')
				AND NOT (prin.type = 'S' AND prin.name = 'dbo' AND prin.authentication_type = 1 AND prin.owning_principal_id IS NULL))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2021 - Minimal set of principals should be granted database-scoped ALTER permissions on objects or columns.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2021 - Minimal set of principals should be granted database-scoped ALTER permissions on objects or columns.', 1;
END


IF EXISTS ( SELECT REPLACE(REPLACE(perms.class_desc, 'DATABASE_PRINCIPAL', 'ROLE'), '_', ' ') AS [Permission Class]
				,CASE
					WHEN perms.class = 3 THEN schema_name(major_id) -- schema
					WHEN perms.class = 4 THEN printarget.name -- principal
					WHEN perms.class = 5 THEN asm.name -- assembly
					WHEN perms.class = 6 THEN type_name(major_id) -- type
					WHEN perms.class = 10 THEN xmlsc.name -- xml schema
					WHEN perms.class = 15 THEN msgt.name COLLATE DATABASE_DEFAULT -- message types
					WHEN perms.class = 16 THEN svcc.name COLLATE DATABASE_DEFAULT -- service contracts
					WHEN perms.class = 17 THEN svcs.name COLLATE DATABASE_DEFAULT -- services
					WHEN perms.class = 18 THEN rsb.name COLLATE DATABASE_DEFAULT -- remote service bindings
					WHEN perms.class = 19 THEN rts.name COLLATE DATABASE_DEFAULT -- routes
					WHEN perms.class = 23 THEN ftc.name -- full text catalog
					WHEN perms.class = 24 THEN sym.name -- symmetric key
					WHEN perms.class = 25  THEN crt.name -- certificate
					WHEN perms.class = 26 THEN asym.name -- asymmetric key
					ELSE ''
				END AS [Object]
				,perms.permission_name AS [Permission],prin.type_desc AS [Principal Type],prin.name AS [Principal]
			FROM sys.database_permissions AS perms
			LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			LEFT JOIN sys.assemblies AS asm ON perms.major_id = asm.assembly_id
			LEFT JOIN sys.xml_schema_collections AS xmlsc ON perms.major_id = xmlsc.xml_collection_id
			LEFT JOIN sys.service_message_types AS msgt ON perms.major_id = msgt.message_type_id
			LEFT JOIN sys.service_contracts AS svcc ON perms.major_id = svcc.service_contract_id
			LEFT JOIN sys.services AS svcs ON perms.major_id = svcs.service_id
			LEFT JOIN sys.remote_service_bindings AS rsb ON perms.major_id = rsb.remote_service_binding_id
			LEFT JOIN sys.routes AS rts ON perms.major_id = rts.route_id
			LEFT JOIN sys.database_principals AS printarget ON perms.major_id = printarget.principal_id
			LEFT JOIN sys.symmetric_keys AS sym ON perms.major_id = sym.symmetric_key_id
			LEFT JOIN sys.asymmetric_keys AS asym ON perms.major_id = asym.asymmetric_key_id
			LEFT JOIN sys.certificates AS crt ON perms.major_id = crt.certificate_id
			LEFT JOIN sys.fulltext_catalogs AS ftc ON perms.major_id = ftc.fulltext_catalog_id
			WHERE permission_name = 'ALTER'
				AND class IN (3,4,5,6,10,15,16,17,18,19,23,24,25,26)
				AND prin.name <> 'dataopsrole'
				AND [state] IN ('G','W')
				AND NOT (prin.type = 'S' AND prin.name = 'dbo' AND prin.authentication_type = 1 AND prin.owning_principal_id IS NULL))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2022 - Minimal set of principals should be granted database-scoped ALTER permission on various securables.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2022 - Minimal set of principals should be granted database-scoped ALTER permission on various securables.', 1;
END


IF EXISTS ( SELECT perms.class_desc AS [Permission Class],perms.permission_name AS Permission,type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name IN ('SELECT', 'EXECUTE')
				AND grantee_principal_id NOT IN (SELECT principal_id FROM sys.database_principals WHERE [name] IN ('guest', 'public'))
				AND perms.class = 0
				AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2030 - Minimal set of principals should be granted database-scoped SELECT or EXECUTE permissions.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2030 - Minimal set of principals should be granted database-scoped SELECT or EXECUTE permissions.', 1;
END


IF EXISTS ( SELECT 
				perms.class_desc AS [Permission Class],object_schema_name(major_id) AS [Schema Name],object_name(major_id) AS [Object],
				perms.permission_name AS Permission,prin.type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE perms.class = '1'
				AND user_name(grantee_principal_id) NOT IN ('guest', 'public', 'odsreportsuser')
				AND permission_name IN ('SELECT', 'EXECUTE')
				AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2031 - Minimal set of principals should be granted database-scoped SELECT permission on objects or columns.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2031 - Minimal set of principals should be granted database-scoped SELECT permission on objects or columns.', 1;
END


IF EXISTS ( SELECT
				perms.class_desc AS [Permission Class],schema_name(major_id) AS [Object],perms.permission_name AS Permission,
				prin.type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE perms.class = '3'
				AND prin.name <> 'dataopsrole'
				AND permission_name IN ('SELECT', 'EXECUTE')
				AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2032 - Minimal set of principals should be granted database-scoped SELECT or EXECUTE permissions on schema.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2032 - Minimal set of principals should be granted database-scoped SELECT or EXECUTE permissions on schema.', 1;
END


IF EXISTS ( SELECT 
				perms.class_desc AS [Permission Class],object_schema_name(major_id) AS [Schema Name],object_name(major_id) AS [Object],
				perms.permission_name AS Permission,type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name IN ('EXECUTE')
				AND perms.class = 1
				AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2033 - Minimal set of principals should be granted EXECUTE permission on objects or columns.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2033 - Minimal set of principals should be granted EXECUTE permission on objects or columns.', 1;
END


IF EXISTS ( SELECT 
				REPLACE(perms.class_desc, '_', ' ') AS [Permission Class],xmlsc.name AS [Object],
				perms.permission_name AS Permission,prin.type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			LEFT JOIN sys.xml_schema_collections AS xmlsc ON perms.major_id = xmlsc.xml_collection_id
			WHERE permission_name = 'EXECUTE'
				AND [state] IN ('G','W')
				AND perms.class = 10
				AND NOT (prin.type = 'R' AND prin.name = 'dc_admin' AND user_name(grantor_principal_id) = 'dbo' AND state_desc = 'GRANT'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2034 - Minimal set of principals should be granted database-scoped EXECUTE permission on XML Schema Collection.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2034 - Minimal set of principals should be granted database-scoped EXECUTE permission on XML Schema Collection.', 1;
END


IF EXISTS ( SELECT perms.class_desc AS [Permission Class],perms.permission_name AS Permission,type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name IN ('INSERT', 'UPDATE', 'DELETE')
				AND perms.class = 0
				AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2040 - Minimal set of principals should be granted low impact database-scoped permissions.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2040 - Minimal set of principals should be granted low impact database-scoped permissions.', 1;
END


IF EXISTS ( SELECT 
				perms.class_desc AS [Permission Class],object_schema_name(major_id) AS [Schema Name],object_name(major_id) AS [Object],
				perms.permission_name AS Permission,type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name IN ('INSERT', 'UPDATE', ' DELETE')
				AND perms.class = 1
				AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2041 - Minimal set of principals should be granted low impact database-scoped permissions on objects or columns.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2041 - Minimal set of principals should be granted low impact database-scoped permissions on objects or columns.', 1;
END


IF EXISTS ( SELECT 
				perms.class_desc AS [Permission Class],schema_name(major_id) AS [Object],
				perms.permission_name AS Permission,prin.type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE perms.permission_name IN ('INSERT', 'UPDATE', 'DELETE')
				AND prin.name <> 'dataopsrole'
				AND perms.class = 3
				AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2042 - Minimal set of principals should be granted low impact database-scoped permissions on schema.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2042 - Minimal set of principals should be granted low impact database-scoped permissions on schema.', 1;
END


IF EXISTS ( SELECT prin.NAME AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name = 'VIEW DEFINITION'
				AND perms.class = 0
				AND [state] IN ('G', 'W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2050 - Minimal set of principals should be granted database-scoped VIEW DEFINITION permissions.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2050 - Minimal set of principals should be granted database-scoped VIEW DEFINITION permissions.', 1;
END


IF EXISTS ( SELECT 
				perms.class_desc AS [Permission Class],object_schema_name(major_id) AS [Schema Name],object_name(major_id) AS [Object],
				perms.permission_name AS Permission,type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			INNER JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			WHERE permission_name = 'VIEW DEFINITION'
				AND perms.class = 1
				AND [state] IN ('G','W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2051 - Minimal set of principals should be granted database-scoped VIEW DEFINITION permissions on objects or columns.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2051 - Minimal set of principals should be granted database-scoped VIEW DEFINITION permissions on objects or columns.', 1;
END


IF EXISTS ( SELECT REPLACE(perms.class_desc, '_', ' ') AS [Permission Class],
				CASE
					WHEN perms.class=3 THEN schema_name(major_id) -- schema
					WHEN perms.class=4 THEN printarget.name -- principal
					WHEN perms.class=5 THEN asm.name -- assembly
					WHEN perms.class=6 THEN type_name(major_id) -- type
					WHEN perms.class=10 THEN xmlsc.name -- xml schema
					WHEN perms.class=15 THEN msgt.name COLLATE DATABASE_DEFAULT -- message types
					WHEN perms.class=16 THEN svcc.name COLLATE DATABASE_DEFAULT -- service contracts
					WHEN perms.class=17 THEN svcs.name COLLATE DATABASE_DEFAULT -- services
					WHEN perms.class=18 THEN rsb.name COLLATE DATABASE_DEFAULT -- remote service bindings
					WHEN perms.class=19 THEN rts.name COLLATE DATABASE_DEFAULT -- routes
					WHEN perms.class=23 THEN ftc.name -- full text catalog
					WHEN perms.class=24 THEN sym.name -- symmetric key
					WHEN perms.class=25 THEN crt.name -- certificate
					WHEN perms.class=26 THEN asym.name -- assymetric key
					ELSE ''
				END AS [Object],
				perms.permission_name AS Permission,prin.type_desc AS [Principal Type],prin.name AS Principal
			FROM sys.database_permissions AS perms
			LEFT JOIN sys.database_principals AS prin ON perms.grantee_principal_id = prin.principal_id
			LEFT JOIN sys.assemblies AS asm ON perms.major_id = asm.assembly_id
			LEFT JOIN sys.xml_schema_collections AS xmlsc ON perms.major_id = xmlsc.xml_collection_id
			LEFT JOIN sys.service_message_types AS msgt ON perms.major_id = msgt.message_type_id
			LEFT JOIN sys.service_contracts AS svcc ON perms.major_id = svcc.service_contract_id
			LEFT JOIN sys.services AS svcs ON perms.major_id = svcs.service_id
			LEFT JOIN sys.remote_service_bindings AS rsb ON perms.major_id = rsb.remote_service_binding_id
			LEFT JOIN sys.routes AS rts ON perms.major_id = rts.route_id
			LEFT JOIN sys.database_principals AS printarget ON perms.major_id = printarget.principal_id
			LEFT JOIN sys.symmetric_keys AS sym ON perms.major_id = sym.symmetric_key_id
			LEFT JOIN sys.asymmetric_keys AS asym ON perms.major_id = asym.asymmetric_key_id
			LEFT JOIN sys.certificates AS crt ON perms.major_id = crt.certificate_id
			LEFT JOIN sys.fulltext_catalogs AS ftc ON perms.major_id = ftc.fulltext_catalog_id
			WHERE
				permission_name = 'VIEW DEFINITION'
				AND class in (3,4,5,6,10,15,16,17,18,19,23,24,25,26)
				AND [state] IN ('G','W'))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2052 - Minimal set of principals should be granted database-scoped VIEW DEFINITION permission on various securables.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2052 - Minimal set of principals should be granted database-scoped VIEW DEFINITION permission on various securables.', 1;
END


IF EXISTS ( SELECT name,start_ip_address,end_ip_address
			FROM sys.database_firewall_rules
			WHERE ( 
					(CONVERT(bigint, parsename(end_ip_address, 1)) +
					 CONVERT(bigint, parsename(end_ip_address, 2)) * 256 + 
					 CONVERT(bigint, parsename(end_ip_address, 3)) * 65536 + 
					 CONVERT(bigint, parsename(end_ip_address, 4)) * 16777216 ) 
					- 
					(CONVERT(bigint, parsename(start_ip_address, 1)) +
					 CONVERT(bigint, parsename(start_ip_address, 2)) * 256 + 
					 CONVERT(bigint, parsename(start_ip_address, 3)) * 65536 + 
					 CONVERT(bigint, parsename(start_ip_address, 4)) * 16777216 )
				  ) > 255)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2062 - Database-level firewall rules should not grant excessive access.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2062 - Database-level firewall rules should not grant excessive access.', 1;
END


IF EXISTS (SELECT name,start_ip_address,end_ip_address FROM sys.database_firewall_rules)
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2064 - Database-level firewall rules should be tracked and maintained at a strict minimum.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2064 - Database-level firewall rules should be tracked and maintained at a strict minimum.', 1;
END


IF EXISTS ( SELECT 
				user_name(sr.member_principal_id) as [Principal]    ,user_name(sr.role_principal_id) as [Role],
				type_desc as [Principal Type],authentication_type_desc as [Authentication Type]
			FROM sys.database_role_members AS sr 
			INNER JOIN sys.database_principals AS sp ON sp.principal_id = sr.member_principal_id
			WHERE sr.role_principal_id IN (user_id('bulkadmin'),
										 user_id('db_accessadmin'),
										 user_id('db_securityadmin'),
										 user_id('db_ddladmin'),
										 user_id('db_backupoperator')))
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2108 - Minimal set of principals should be members of fixed high impact database roles.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2108 - Minimal set of principals should be members of fixed high impact database roles.', 1;
END


IF EXISTS ( SELECT 
				QUOTENAME(sc.name) + '.' + QUOTENAME(oj.name) AS [Module]
				,IIF(ct.certificate_id IS NOT NULL, ct.name, ak.name) AS [Signing Object]
				,dp.name AS [Signing Object Owner]
				,cp.thumbprint AS [Signing Object Thumbprint]
				,oj.modify_date AS [Last Definition Modify Date]
				,HASHBYTES('SHA2_256', cp.crypt_property) AS [Hashed Signature Bits]
				,IIF(ct.certificate_id IS NOT NULL, 'CERTIFICATE', 'ASYMMETRIC KEY') AS [Signing Object Type]
				-- For debbuging, uncomment following lines:
				-- ,IIF(ct.principal_id IS NOT NULL, SUSER_NAME(ct.principal_id), SUSER_NAME(ak.principal_id)) AS [Owner_Name]
				-- ,oj.type_desc
				-- ,crypt_type
				-- ,md.DEFINITION 
				-- ,IIF(ct.subject IS NOT NULL, ct.subject, 'N/A') AS [Certificate Subject]
				-- ,IIF(ct.certificate_id IS NOT NULL, IS_OBJECTSIGNED('OBJECT', oj.object_id, 'certificate', cp.thumbprint), IS_OBJECTSIGNED('OBJECT', oj.object_id, 'asymmetric key', cp.thumbprint)) AS [Is Object Signed]
			FROM 
				sys.crypt_properties AS cp
				INNER JOIN sys.objects AS oj ON cp.major_id = oj.object_id
				INNER JOIN sys.schemas AS sc ON oj.schema_id = sc.schema_id
				INNER JOIN sys.sql_modules AS md ON md.object_id = cp.major_id
				LEFT OUTER JOIN sys.certificates AS ct ON cp.thumbprint = ct.thumbprint
				LEFT OUTER JOIN sys.asymmetric_keys AS ak ON cp.thumbprint = ak.thumbprint
				LEFT OUTER JOIN sys.database_principals AS dp ON (ct.sid = dp.sid OR ak.sid = dp.sid)
			WHERE 
				oj.type IN ('P','FN','TR')
				AND cp.class_desc = 'OBJECT_OR_COLUMN')
BEGIN
	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES('sp_securityhealthcheck', 'Security Rule Failed: VA2129 - Changes to signed modules should be authorized.', GETUTCDATE());

	THROW 51000, 'Security Rule Failed: VA2129 - Changes to signed modules should be authorized.', 1;
END

END
