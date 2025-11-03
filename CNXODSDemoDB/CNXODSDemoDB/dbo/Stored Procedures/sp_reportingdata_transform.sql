
CREATE   PROCEDURE [dbo].[sp_reportingdata_transform]
AS
BEGIN

-------------------------------------Create Reporting_AM_Counts table----------------------------------
DROP TABLE IF EXISTS Reporting_AM_Counts;

CREATE TABLE [dbo].[Reporting_AM_Counts] (
   [TerritoryId] [uniqueidentifier] NOT NULL,
   [Description] [nvarchar](200) NULL,
   [AccountCount] [int] NULL,
   [HCPCount] [int] NULL
);

INSERT INTO Reporting_AM_Counts 
SELECT 
	T.TerritoryId, ISNULL(T.Description, T.Name) AS Description,
	SUM(CASE WHEN A.IsPersonAccount = 'False' THEN 1 ELSE 0 END) AS AccountCount,
	SUM(CASE WHEN A.IsPersonAccount = 'True' THEN 1 ELSE 0 END) AS HCPCount
from ATL ATL 
INNER JOIN Territory T ON ATL.Territory = T.ExternalId1 AND ATL.EndDate IS NULL AND T.EndDate IS NULL
INNER JOIN Account A ON ATL.Account = A.ExternalId1 AND A.EndDate IS NULL
GROUP BY T.TerritoryId, ISNULL(T.Description, T.Name);


-------------------------------------Create Reporting_AM_TerritoryDetails table----------------------------------
IF EXISTS(SELECT 1 FROM sysobjects WHERE type = 'U' and name = 'Reporting_AM_TerritoryDetails')
BEGIN
   DROP TABLE Reporting_AM_TerritoryDetails;
END
CREATE TABLE [dbo].[Reporting_AM_TerritoryDetails] (
   [TerritoryId] [uniqueidentifier] NOT NULL,
   [Territory1] [nvarchar](200) NULL,
   [Territory2] [nvarchar](200) NULL,
   [Territory3] [nvarchar](200) NULL,
   [Territory] [nvarchar](200) NULL
)

INSERT INTO Reporting_AM_TerritoryDetails
SELECT
	DISTINCT T1.TerritoryId, 
	CASE WHEN T3.Description IS NULL THEN ISNULL(T2.Description, T2.Name) ELSE ISNULL(T3.Description, T3.Name) END AS [Territory1], 
	CASE WHEN T3.Description IS NULL THEN ISNULL(T1.Description, T1.Name) ELSE ISNULL(T2.Description, T2.Name) END AS [Territory2], 
	CASE WHEN T3.Description IS NULL THEN NULL ELSE ISNULL(T1.Description, T1.Name) END AS [Territory3], 
	ISNULL(ISNULL(T1.Description, T1.Name), ISNULL(T2.Description, T2.Name)) AS [Territory]
from Territory T1
LEFT OUTER JOIN Territory T2 ON T2.ExternalId1 = T1.ParentTerritoryId
LEFT OUTER JOIN Territory T3 ON T3.ExternalId1 = T2.ParentTerritoryId
WHERE T1.ParentTerritoryId IS NOT NULL AND T1.EndDate IS NULL AND T2.EndDate IS NULL AND T3.EndDate IS NULL;


-------------------------------------Create Reporting_AU_AccountDetails table----------------------------------
DROP TABLE IF EXISTS Reporting_AU_AccountDetails;

CREATE TABLE Reporting_AU_AccountDetails
(
	AccountCRMId				VARCHAR(50), 
	AccountName					VARCHAR(200), 
	AccountType					VARCHAR(200), 
	NPINumber					VARCHAR(50), 
	TargetType					VARCHAR(25), 
	Specialty1					VARCHAR(200), 
	Specialty2					VARCHAR(200), 
	AddressCRMId				VARCHAR(50), 
	AddressLine1				VARCHAR(200), 
	AddressLine2				VARCHAR(200), 
	City						VARCHAR(50), 
	State						VARCHAR(50), 
	ZipCode						VARCHAR(50),
	Territory					VARCHAR(200), 
	CallCount					INT,
	PrimaryParent				VARCHAR(200)
);


WITH CTE AS
(
	SELECT 
		A.ExternalId1 AS AccountCRMId, 
		A.Name AS AccountName, A.AccountTypec AS AccountType,
		A.NPI, A.CNXTargetTypec AS TargetType,
		A.Specialty1, A.Specialty2, AD.ExternalId1 AS AddressCRMId,
		AD.Name AS AddressLine1, AD.AddressLine2, AD.City, 
		AD.State, AD.Zip AS ZipCode, ISNULL(T.Description, T.Name) AS Territory, 
		C.CallId, PA.Name AS PrimaryParent
	FROM Account A 
	LEFT OUTER JOIN Account PA					ON A.PrimaryParent = PA.ExternalId1 AND PA.EndDate IS NULL
	LEFT OUTER JOIN AccountAddress AD			ON A.ExternalId1 = AD.Account AND AD.EndDate IS NULL
	LEFT OUTER JOIN ATL ATL						ON A.ExternalId1 = ATL.Account AND ATL.EndDate IS NULL 
	LEFT OUTER JOIN Territory T					ON ATL.Territory = T.ExternalId1 AND T.EndDate IS NULL
	LEFT OUTER JOIN UserTerritory UT			ON T.ExternalId1 = UT.TerritoryId AND UT.EndDate IS NULL
	LEFT OUTER JOIN Call C						ON A.ExternalId1 = C.Account AND C.EndDate IS NULL
	where 
	--A.AccountType = 'PRES' -- To filter only HCPs
	--AND U.Status = 'ACTV' -- To show only active Rep Name
	A.EndDate IS NULL
)
INSERT INTO Reporting_AU_AccountDetails
(AccountCRMId, AccountName, AccountType, NPINumber, TargetType, Specialty1, Specialty2, 
AddressCRMId, AddressLine1, AddressLine2, City, State, ZipCode, Territory, CallCount, PrimaryParent)
SELECT 
AccountCRMId, AccountName, AccountType, NPI, TargetType, Specialty1, Specialty2, 
AddressCRMId, AddressLine1, AddressLine2, City, State, ZipCode, Territory, COUNT(DISTINCT CallId) AS HCPCallCount, PrimaryParent
FROM CTE
GROUP BY AccountCRMId, AccountName, AccountType, NPI, TargetType, Specialty1, Specialty2, 
AddressCRMId, AddressLine1, AddressLine2, City, State, ZipCode, Territory, PrimaryParent
ORDER BY AccountName;



IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Reporting_AU_AccountDetails_Specialty1')
    DROP INDEX IX_Reporting_AU_AccountDetails_Specialty ON dbo.Reporting_AU_AccountDetails;
CREATE NONCLUSTERED INDEX IX_Reporting_AU_AccountDetails_Specialty  ON dbo.Reporting_AU_AccountDetails (Specialty1 ASC);

IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Reporting_AU_AccountDetails_TargetType')
    DROP INDEX IX_Reporting_AU_AccountDetails_TargetType ON dbo.Reporting_AU_AccountDetails;
CREATE NONCLUSTERED INDEX IX_Reporting_AU_AccountDetails_TargetType  ON dbo.Reporting_AU_AccountDetails (TargetType ASC);

IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Reporting_AU_AccountDetails_Territory')
    DROP INDEX IX_Reporting_AU_AccountDetails_Territory ON dbo.Reporting_AU_AccountDetails;
CREATE NONCLUSTERED INDEX IX_Reporting_AU_AccountDetails_Territory  ON dbo.Reporting_AU_AccountDetails (Territory ASC);


-------------------------------------Create Reporting_RF_IndividualSummary table----------------------------------
DROP TABLE IF EXISTS Reporting_RF_IndividualSummary;

CREATE TABLE Reporting_RF_IndividualSummary
(
	PK							NVARCHAR(100)		NULL,
	UserId						uniqueidentifier	NOT NULL,
	[RepName]					NVARCHAR(400)		NULL,
	TerritoryId					uniqueidentifier	NOT NULL,
	Territory					NVARCHAR(400)		NULL,
	TargetType					NVARCHAR(20)		NULL,
	TargetTypeInteger			int					NULL,
	QuarterString				NVARCHAR(20)		NULL,
	[#Targets]					int					NULL,
	[#TargetCalled]				int					NULL,
	[#Calls]					int					NULL,
	DesiredCalls				int					NULL,
	[% Reach]					NVARCHAR(20)		NULL,
	[Freq Goal per HCP]			int					NULL,
	WorkDays					int					NULL,
	[#Targets FreqAchieved]		int					NULL,
	[Freq %]					int					NULL,
	[Req Freq %]				int					NULL
);

INSERT INTO Reporting_RF_IndividualSummary
	(PK, UserId, RepName, TerritoryId, Territory, TargetType, TargetTypeInteger, QuarterString, [#Targets], 
	[#TargetCalled], [#Calls], DesiredCalls, [% Reach], [Freq Goal per HCP], WorkDays, [#Targets FreqAchieved], [Freq %], [Req Freq %])
SELECT
	PK, UserId, RepName, TerritoryId, Territory, TargetType, TargetTypeInteger, QuarterString, [#Targets], 
	[#TargetCalled], [#Calls], DesiredCalls, [% Reach], [Freq Goal per HCP], WorkDays, [#Targets FreqAchieved], [Freq %], [Req Freq %]
from V_RF_IndividualSummary;


-------------------------------------Create Reporting_RF_ManagerSummary table-------------------------------------
DROP TABLE IF EXISTS Reporting_RF_ManagerSummary;

CREATE TABLE Reporting_RF_ManagerSummary
(
	UserId						uniqueidentifier	NOT NULL,
	ManagerName					NVARCHAR(400)		NULL,
	TargetType					NVARCHAR(20)		NULL,
	TargetTypeInteger			int					NULL,
	QuarterString				NVARCHAR(20)		NULL,
	WorkDays					int					NULL,
	[#Targets]					int					NULL,
	[#TargetCalled]				int					NULL,
	[#Calls]					int					NULL,
	DesiredCalls				int					NULL,
	[% Reach]					NVARCHAR(20)		NULL,
	[Freq Goal per HCP]			int					NULL,
	[#Targets FreqAchieved]		int					NULL,
	[Freq %]					int					NULL,
	[Req Freq %]				int					NULL
);

INSERT INTO Reporting_RF_ManagerSummary
	(UserId, ManagerName, TargetType, TargetTypeInteger, QuarterString, WorkDays, [#Targets], [#TargetCalled], 
	[#Calls], DesiredCalls, [% Reach], [Freq Goal per HCP], [#Targets FreqAchieved], [Freq %], [Req Freq %])
SELECT
	UserId, ManagerName, TargetType, TargetTypeInteger, QuarterString, WorkDays, [#Targets], [#TargetCalled], 
	[#Calls], DesiredCalls, [% Reach], [Freq Goal per HCP], [#Targets FreqAchieved], [Freq %], [Req Freq %]
from V_RF_ManagerSummary;


-------------------------------------Create Reporting_RF_CallDetails table-------------------------------------
DROP TABLE IF EXISTS Reporting_RF_CallDetails;

CREATE TABLE Reporting_RF_CallDetails
(
	PK					NVARCHAR(100)		NULL,
	UserId				uniqueidentifier	NOT NULL,
	[Rep Name]			NVARCHAR(400)		NULL,
	TerritoryId			uniqueidentifier	NOT NULL,
	Territory			NVARCHAR(400)		NULL,
	[Target Type]		NVARCHAR(20)		NULL,
	TargetTypeInteger	int					NULL,
	QuarterString		NVARCHAR(20)		NULL,
	[HCP Name]			NVARCHAR(400)		NULL,
	Specialty			NVARCHAR(200)		NULL,
	[Last Call Date]	date				NULL,
	[Actual Calls]		int					NULL,
	[Freq Achieved?]	int					NULL
);

-- Create temp tables rather than using views to improve the performance of the data loading 
-- as it was taking 6 hours to load this table.
SELECT * INTO #temp_V_RF_UserTerritoryCallDetails from V_RF_UserTerritoryCallDetails;
SELECT * INTO #temp_V_RF_UserTerritoryCallSummary from V_RF_UserTerritoryCallSummary;

-- load the data by using the definition of V_RF_CallDetails by using the above temp tables.
INSERT INTO Reporting_RF_CallDetails
	(PK, UserId, [Rep Name], TerritoryId, Territory, [Target Type], TargetTypeInteger, QuarterString, 
	[HCP Name], Specialty, [Last Call Date], [Actual Calls], [Freq Achieved?])
SELECT 
	CAST(S.UserId AS VARCHAR(40)) + ',' + CAST(S.TerritoryId AS VARCHAR(40)) + ',' + S.TargetType + ',' + CASE WHEN S.QuarterString = 'Previous' THEN 'P' ELSE 'C' END AS PK,
	S.UserId, U.Name AS RepName, S.TerritoryId, T.Description AS Territory, S.TargetType,
	CASE S.TargetType WHEN 'Tier 1' THEN 1 WHEN 'Tier 2' THEN 2 WHEN 'Tier 3' THEN 3 WHEN 'Target' THEN 4 END AS TargetTypeInteger,
	S.QuarterString, D.HCPName AS HCPName, D.Specialty, D.LastCallDate, D.ActualCalls, 
	CASE WHEN S.[Freq Goal] > 0 AND D.ActualCalls >= S.[Freq Goal] THEN 1 ELSE 0 END AS [FreqAchieved?]
from #temp_V_RF_UserTerritoryCallSummary S 
INNER JOIN [User] U ON S.UserId = U.UserId AND U.EndDate IS NULL AND U.IsActive = 'True'
INNER JOIN [Territory] T ON S.TerritoryId = T.TerritoryId AND T.EndDate IS NULL --Consider only active territories
INNER JOIN #temp_V_RF_UserTerritoryCallDetails D ON S.UserId = D.UserId AND S.TerritoryId = D.TerritoryId 
										AND S.TargetType = D.TargetType AND S.QuarterString = D.QuarterString

-- drop the temp tables.
DROP TABLE #temp_V_RF_UserTerritoryCallSummary;
DROP TABLE #temp_V_RF_UserTerritoryCallDetails;


END
