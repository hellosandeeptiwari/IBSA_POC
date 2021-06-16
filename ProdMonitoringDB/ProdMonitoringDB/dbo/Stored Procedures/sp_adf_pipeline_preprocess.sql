CREATE OR ALTER PROCEDURE sp_adf_pipeline_preprocess
AS
BEGIN

ALTER TABLE ADF_Pipeline DROP COLUMN PipelineDescription;

END


CREATE OR ALTER PROCEDURE sp_adf_pipeline_postprocess
AS
BEGIN

IF NOT EXISTS (SELECT 1 FROM sys.tables t INNER JOIN sys.columns c ON t.object_id = c.object_id WHERE T.name = 'ADF_Pipeline' AND c.name = 'PipelineDescription')
	ALTER TABLE ADF_Pipeline ADD PipelineDescription VARCHAR(200) NULL;


CREATE TABLE #temp_PipelineDetails(DataFactoryName VARCHAR(200), PipelineName VARCHAR(200), PipelineDescription VARCHAR(200));

INSERT INTO #temp_PipelineDetails VALUES('MTPAProdDataFactory', 'VeevaToStagingPipeline', 'Daily Veeva data load process (Veeva to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('PACPDataFactory', 'VeevaToBRFPipeline', 'Daily Veeva data load process (Veeva to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('PACPDataFactory', 'SyncReportGenerationPipeline', 'Weekly Veeva Sync report generation process (ODS to Pacira)');
INSERT INTO #temp_PipelineDetails VALUES('HBSDatafactory', 'CallPlanReportingPipeline', 'Daily call planning report generation process(ODS to Harmony)');
INSERT INTO #temp_PipelineDetails VALUES('FidiaProdDataFactory', 'CHInvoiceChargebackPipeline', 'Daily Cardinal Health Invoice and Chargeback data load process(Fidia to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('FidiaProdDataFactory', 'CashSalesFileLoadPipeline', 'Weekly Cash Sales data load process (Fidia to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('FidiaProdDataFactory', 'ActivityRunLogNotificationPipeline', 'Daily job statics email notification - Fidia');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'MTPA-VeevaToODSPipeline', 'Daily job statics email notification - MTPA');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'HBS-VeevaToODSPipeline', 'Daily job statics email notification - Harmony');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'AdfJobMonitorPipeline', 'Daily job statics email notification');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'ADTC-VeevaToODSPipeline', 'Daily job statics email notification - ADCT');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'PACIRA-VeevaToODSPipeline', 'Daily job statics email notification - Pacira');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'UROGEN-VeevaToODSPipeline', 'Daily job statics email notification - Urogen');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'BIPI-VeevaToODSPipeline', 'Daily job statics email notification - BIPI');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'FIDIA-VeevaToODSPipeline', 'Daily job statics email notification - Fidia');
INSERT INTO #temp_PipelineDetails VALUES('MonitoringProdDataFactory', 'OPTINOSE-VeevaToODSPipeline', 'Daily job statics email notification - Optinose');
INSERT INTO #temp_PipelineDetails VALUES('ADCTProdDataFactory', 'SteepRockToODSPipeline', 'Daily SteepRock data load process(ADCT to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('ADCTProdDataFactory', 'MasterVeevaToODSPipeline', 'Daily Veeva data load process(Veeva to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('ADCTProdDataFactory', 'HibbertHCPDataPipeline', 'Daily Hibbert file generation process (ODS to Hibbert)');
INSERT INTO #temp_PipelineDetails VALUES('ADCTProdDataFactory', 'MedispendExtractPipeline', 'Daily Medispend data load process (Medispend to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('ADCTProdDataFactory', 'MasterSymphonyPipeline', 'Weekly Symphony data load process (Symphony to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('ADCTProdDataFactory', 'MasterAcornCustomerPatientPipeline', 'Daily Acorn report generation (ODS to Acorn)');
INSERT INTO #temp_PipelineDetails VALUES('URGNProdDataFactory', 'VeevaToBoastDataLoadPipeline', 'Weekly account data load process (ODS to Boast)');
INSERT INTO #temp_PipelineDetails VALUES('BIPIProdDataFactory', 'HmsToDifPipeline', 'Daily HMS data load process (HMS to Veeva)');
INSERT INTO #temp_PipelineDetails VALUES('BIPIProdDataFactory', 'DifToHmsPipeline', 'Daily Sample data file genentation process (Veeva to HMS)');
INSERT INTO #temp_PipelineDetails VALUES('BIPIProdDataFactory', 'ArchwayToDifPipeline', 'Daily Archway data load process (Archway to Veeva)');
INSERT INTO #temp_PipelineDetails VALUES('BIPIProdDataFactory', 'DifToArchwayPipleine', 'Daily promotional data file generation process (Veeva to Archway)');
INSERT INTO #temp_PipelineDetails VALUES('BIPIProdDataFactory', 'BipiDoNotCallExtractPipeline', 'Weekly Do Not Call file generation process (Veeva to BIPI)');
INSERT INTO #temp_PipelineDetails VALUES('BIPIProdDataFactory', 'VeevaToODSPipline', 'Daily Veeva data load process (Veeva to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('BIPIProdDataFactory', 'BipiToDifCustomerMasterPipeline', 'Daily BIPI customer master data load process (BIPI to Veeva)');
INSERT INTO #temp_PipelineDetails VALUES('BIPIProdDataFactory', 'BipiToDifCallActivityPipeline', 'Daily BIPI call activity data load process (BIPI to Veeva)');
INSERT INTO #temp_PipelineDetails VALUES('THVProdDataFactory', 'MasterDDDPipeline', 'Weekly DDD data load process (IQVIA to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('THVProdDataFactory', 'MasterConcurPipeline', 'Daily Concur data load process (Concur to ODS)');
INSERT INTO #temp_PipelineDetails VALUES('THVProdDataFactory', 'DDDPreProcessPipeline', 'Weekly DDD data backup process');

DECLARE @strUpdateQuery NVARCHAR(MAX)

SET @strUpdateQuery = '
UPDATE P SET P.PipelineDescription = T.PipelineDescription
FROM ADF_Pipeline P INNER JOIN #temp_PipelineDetails T ON P.DataFactoryName = T.DataFactoryName AND P.PipelineName = T.PipelineName;
'

EXEC sp_executesql @strUpdateQuery;

DROP TABLE IF EXISTS #temp_PipelineDetails;

END