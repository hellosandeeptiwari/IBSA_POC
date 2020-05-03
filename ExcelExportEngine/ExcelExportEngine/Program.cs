using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using OfficeOpenXml;
using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;

/// <summary>
/// *************************************** NUGET PACKAGES ***************************************
/// Install the below Nuget packagaes.
/// Install-Package log4net -Version 2.0.8
/// Install-Package WindowsAzure.Storage -Version 9.3.3
/// Install-Package EPPlus -Version 4.5.3.2, Do not use higher versions of EPPlus since they are no longer free.
/// 
/// 
/// *************************************** TEST CASES ***************************************
/// Local Directory With Template
/// -i "C:\TestData\aaa.txt" -o "C:\TestData\aaa.xlsx" -t "C:\TestData\template.xlsx"
/// 
/// Local Directory With Template with Cell Number
/// -i "C:\TestData\aaa.txt" -o "C:\TestData\bbb.xlsx" -t "C:\TestData\template.xlsx" -cell "A5"
/// 
/// Local Directory Without Template
/// -i "C:\TestData\aaa.txt" -o "C:\TestData\bbb.xlsx"
/// 
/// Local Directory Without Template with Header needed argument
/// -i "C:\TestData\aaa.txt" -o "C:\TestData\bbb.xlsx" -header "false"
/// 
/// Local Directory Without Template
/// -i "C:\TestData\aaa.txt" -o "C:\TestData\bbb.xlsx" -sheet "TestSheetName"
/// 
/// Blob location Without Template
/// -i "test/aaa.txt" -o "test/bbb.xlsx" -t "test/template.xlsx"
/// 
/// Blob location Without Template
/// -i "test/aaa.txt" -o "test/bbb.xlsx"
/// </summary>
namespace ExcelExportEngine
{
    class Program
    {
        private static string stSQLConnectionString = ConfigurationManager.AppSettings["stSQLConnectionString"].ToString();
        private static string strBlobConnectionString = ConfigurationManager.AppSettings["strBlobConnectionString"].ToString();

        private static string strInputSQLQueryFilepath;
        private static string strOutputFilepath;
        private static string strTemplateFilepath;
        private static string strExcelSheetName = "ReportsData";
        private static string strExcelCellNumber = "A1";
        private static bool blnHeaderNeeded = true;

        static void Main(string[] args)
        {
            LogHelper.WriteDebugLog("Started....");

            try
            {
                string strValidationError = ValidateAndParseArguments(args);
                if (strValidationError.Length > 0)
                {
                    LogHelper.WriteDebugLog($"Following are the errors with the arguments passed to the Excel Export Engine: {strValidationError}");
                    return;
                }

                DataTable dtReportData = GetReportData();

                LogHelper.WriteDebugLog("Input data from database has been retrieved successfully....");

                // Windows Path or Azure Blob Storage path
                if (strOutputFilepath.Contains("/"))
                {
                    CreateExcelFileFromTableInAzureBlob(dtReportData, strTemplateFilepath, strOutputFilepath);
                }
                else
                {
                    CreateExcelFileFromTableInLocalDirectory(dtReportData, strTemplateFilepath, strOutputFilepath);
                }
            }
            catch (Exception ex)
            {
                LogHelper.WriteDebugLog(ex.Message);
                LogHelper.WriteDebugLog(ex.StackTrace);
            }

            LogHelper.WriteDebugLog("Completed....");
        }

        private static string ValidateAndParseArguments(string[] args)
        {
            // First argument - Input SQL query validation
            if (args.Contains("-i"))
            {
                int index = Array.IndexOf<string>(args, "-i");
                if (args[index + 1].ToLower().EndsWith(".sql") || args[index + 1].ToLower().EndsWith(".txt"))
                {
                    strInputSQLQueryFilepath = args[index + 1];
                }
                else
                {
                    return "The Input SQL Query filepath should be a SQL or TXT file.";
                }
            }
            else
            {
                return "The Input SQL Query filepath is a mandatory argument and is has not been passed";
            }

            // Second argument - Output filepath validation
            if (args.Contains("-o"))
            {
                int index = Array.IndexOf<string>(args, "-o");
                if (args[index + 1].ToLower().EndsWith(".xlsx") || args[index + 1].ToLower().EndsWith(".csv"))
                {
                    strOutputFilepath = args[index + 1];
                }
                else
                {
                    return "The Output filepath should be a XLSX or CSV file.";
                }
            }
            else
            {
                return "The Output filepath is a mandatory argument and is has not been passed";
            }

            // Third argument - Template filename validation
            if (args.Contains("-t"))
            {
                if (strOutputFilepath.ToLower().EndsWith(".xlsx"))
                {
                    int index = Array.IndexOf<string>(args, "-t");
                    if (args[index + 1].ToLower().EndsWith(".xlsx"))
                    {
                        strTemplateFilepath = args[index + 1];
                    }
                    else
                    {
                        return "The Template filepath should be XLSX file.";
                    }
                }
                else
                {
                    return "The Template filepath should be specified only if the Output file type is XLSX";
                }
            }

            // Fourth argument - Excel Cell Number validation
            if (args.Contains("-cell"))
            {
                if ((! string.IsNullOrWhiteSpace(strTemplateFilepath)) && strTemplateFilepath.ToLower().EndsWith(".xlsx"))
                {
                    int index = Array.IndexOf<string>(args, "-cell");

                    // Check if the cell number starts with a letter and end with a digit.
                    if (args[index + 1].Length > 0 && char.IsLetter(args[index + 1], 0) && char.IsDigit(args[index + 1], args[index + 1].Length - 1))
                    {
                        strExcelCellNumber = args[index + 1];
                    }
                    else
                    {
                        return "The Cell number does not start with a letter or does not end with a digit.";
                    }
                }
                else
                {
                    return "The Cell number should be specified only if the Template file type is XLSX";
                }
            }

            // Fifth argument - Header needed validation
            if (args.Contains("-header"))
            {
                int index = Array.IndexOf<string>(args, "-header");
                if (args[index + 1].ToLower() == "false" || args[index + 1].ToLower() == "true")
                {
                    blnHeaderNeeded = Convert.ToBoolean(args[index + 1]);
                }
                else
                {
                    return "The Header needed flag should be either true or false.";
                }
            }

            // Sixth argument - Excel Sheet Name validation
            if (args.Contains("-sheet"))
            {
                int index = Array.IndexOf<string>(args, "-sheet");
                if (args[index + 1].Length > 0)
                {
                    strExcelSheetName = args[index + 1];
                }
                else
                {
                    return "The excel sheet name cannot be empty.";
                }
            }

            return string.Empty;
        }

        private static DataTable GetReportData()
        {
            DataTable dtSyncData = new DataTable();
            using (SqlConnection sqlConn = new SqlConnection(stSQLConnectionString))
            {
                string sqlQuery = string.Empty;
                if (strInputSQLQueryFilepath.Contains("/"))
                {
                    // Setup the connection to the storage account
                    CloudStorageAccount storageAccount = CloudStorageAccount.Parse(strBlobConnectionString);

                    // Connect to the blob storage
                    CloudBlobClient serviceClient = storageAccount.CreateCloudBlobClient();

                    int index = strInputSQLQueryFilepath.LastIndexOf("/");

                    // Connect to the blob container
                    CloudBlobContainer downloadContainer = serviceClient.GetContainerReference(strInputSQLQueryFilepath.Substring(0, index));

                    // Connect to the blob file
                    CloudBlockBlob downloadBlob = downloadContainer.GetBlockBlobReference(strInputSQLQueryFilepath.Substring(index + 1, strInputSQLQueryFilepath.Length - index - 1));

                    // Get the blob file as text
                    sqlQuery = downloadBlob.DownloadTextAsync().Result;
                }
                else
                {
                    sqlQuery = File.ReadAllText(strInputSQLQueryFilepath);
                }

                using (SqlCommand cmd = new SqlCommand(sqlQuery, sqlConn))
                {
                    SqlDataAdapter da = new SqlDataAdapter(cmd);
                    da.Fill(dtSyncData);
                }
            }
            return dtSyncData;
        }

        private static void CreateExcelFileFromTableInAzureBlob(DataTable datatable, string strTemplateFilepath, string strOutputFilepath)
        {
            MemoryStream msOutput = new MemoryStream();

            // Setup the connection to the storage account
            CloudStorageAccount storageAccount = CloudStorageAccount.Parse(strBlobConnectionString);

            // Connect to the blob storage
            CloudBlobClient serviceClient = storageAccount.CreateCloudBlobClient();

            int index = strOutputFilepath.LastIndexOf("/");

            // Connect to the blob container
            CloudBlobContainer outputContainer = serviceClient.GetContainerReference(strOutputFilepath.Substring(0, index));

            // Connect to the blob file
            CloudBlockBlob outputBlob = outputContainer.GetBlockBlobReference(strOutputFilepath.Substring(index + 1, strOutputFilepath.Length - index - 1));

            if (! string.IsNullOrWhiteSpace(strTemplateFilepath))
            {
                MemoryStream msTemplate = new MemoryStream();

                index = strTemplateFilepath.LastIndexOf("/");

                // Connect to the blob container
                CloudBlobContainer templateContainer = serviceClient.GetContainerReference(strTemplateFilepath.Substring(0, index));

                // Connect to the blob file
                CloudBlockBlob templateBlob = templateContainer.GetBlockBlobReference(strTemplateFilepath.Substring(index + 1, strTemplateFilepath.Length - index - 1));

                // Get the blob file as stream
                templateBlob.DownloadToStream(msTemplate);

                using (ExcelPackage myExcel = new ExcelPackage(msOutput, msTemplate))
                {
                    myExcel.Workbook.Worksheets[1].Cells[strExcelCellNumber].LoadFromDataTable(datatable, blnHeaderNeeded);

                    myExcel.Save();
                }
            }
            else
            {
                using (ExcelPackage myExcel = new ExcelPackage(msOutput))
                {
                    myExcel.Workbook.Worksheets.Add(strExcelSheetName);

                    myExcel.Workbook.Worksheets[1].Cells[strExcelCellNumber].LoadFromDataTable(datatable, blnHeaderNeeded);

                    myExcel.Save();
                }
            }

            msOutput.Position = 0;
            outputBlob.UploadFromStream(msOutput);

            LogHelper.WriteDebugLog($"Excel file, {strOutputFilepath} has been created with Rows: {datatable.Rows.Count}");
        }

        private static void CreateExcelFileFromTableInLocalDirectory(DataTable datatable, string strTemplateFilepath, string strOutputFilepath)
        {
            // If the output file already exists, then delete it.
            if (File.Exists(strOutputFilepath))
            {
                File.Delete(strOutputFilepath);

                LogHelper.WriteDebugLog($"Deleted file, {strOutputFilepath}");
            }

            // Create the output file from template file.
            if (string.IsNullOrWhiteSpace(strTemplateFilepath))
            {
                using (ExcelPackage myExcel = new ExcelPackage(new FileInfo(strOutputFilepath)))
                {
                    myExcel.Workbook.Worksheets.Add(strExcelSheetName);

                    myExcel.Workbook.Worksheets[1].Cells[strExcelCellNumber].LoadFromDataTable(datatable, blnHeaderNeeded);

                    myExcel.Save();
                }
            }
            else
            {
                using (ExcelPackage myExcel = new ExcelPackage(new FileInfo(strOutputFilepath), new FileInfo(strTemplateFilepath)))
                {
                    myExcel.Workbook.Worksheets[1].Cells[strExcelCellNumber].LoadFromDataTable(datatable, blnHeaderNeeded);

                    myExcel.Save();
                }
            }

            LogHelper.WriteDebugLog($"Excel file, {strOutputFilepath} has been created with Rows: {datatable.Rows.Count}");
        }
    }
}
