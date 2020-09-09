using System;
using System.Linq;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using SendGrid;
using SendGrid.Helpers.Mail;
using Microsoft.WindowsAzure.Storage;
using Newtonsoft.Json;
using Microsoft.WindowsAzure.Storage.Blob;

namespace SendEmailActivity
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Send email activity started");
            Execute().Wait();
            Console.WriteLine("Send email activity completed");
        }
        static async Task Execute()
        {
            Console.WriteLine("Printing the pipeline properties");
            dynamic activity = JsonConvert.DeserializeObject(File.ReadAllText("activity.json"));
            Console.WriteLine(activity);
            Console.WriteLine("Printing the LinkedService properties");
            dynamic linkedServices = JsonConvert.DeserializeObject(File.ReadAllText("linkedServices.json"));
            Console.WriteLine(linkedServices);
            Console.WriteLine("Printing the Datasets properties");
            dynamic datasets = JsonConvert.DeserializeObject(File.ReadAllText("datasets.json"));
            Console.WriteLine(datasets);

            SendGridClient objSendGridClient = new SendGridClient("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");
            SendGridMessage objMessage = new SendGridMessage();
            
            string strToEmails = activity.typeProperties.extendedProperties.emailTo.ToString();
            Console.WriteLine(strToEmails);
            string[] strArrToEmails = strToEmails.Split(',');
            List<EmailAddress> lstToEmails = new List<EmailAddress>(strArrToEmails.Select(str => new EmailAddress(str)));
            objMessage.AddTos(lstToEmails);

            string extendedProperties = activity.typeProperties.extendedProperties.ToString();
            if(extendedProperties.Contains("emailCC"))
            {
                string strCCEmails = activity.typeProperties.extendedProperties.emailCC.ToString();
                if (strCCEmails.Trim().Length > 0)
                {
                    Console.WriteLine(strCCEmails);
                    string[] strArrCCEmails = strCCEmails.Split(',');
                    List<EmailAddress> lstCCEmails = new List<EmailAddress>(strArrCCEmails.Select(str => new EmailAddress(str)));
                    objMessage.AddCcs(lstCCEmails);
                }
            }

            if (extendedProperties.Contains("emailBCC"))
            {
                string strBCCEmails = activity.typeProperties.extendedProperties.emailBCC.ToString();
                if (strBCCEmails.Trim().Length > 0)
                {
                    Console.WriteLine(strBCCEmails);
                    string[] strArrBCCEmails = strBCCEmails.Split(',');
                    List<EmailAddress> lstBCCEmails = new List<EmailAddress>(strArrBCCEmails.Select(str => new EmailAddress(str)));
                    objMessage.AddBccs(lstBCCEmails);
                }
            }
           
            objMessage.SetFrom(activity.typeProperties.extendedProperties.emailFrom.ToString());
            objMessage.SetSubject(activity.typeProperties.extendedProperties.emailSubject.ToString());
            objMessage.AddContent(MimeType.Html, activity.typeProperties.extendedProperties.emailBody.ToString());

            if (extendedProperties.Contains("strBlobConnectionstring"))
            {
                var storageAccount = CloudStorageAccount.Parse(activity.typeProperties.extendedProperties.strBlobConnectionstring.ToString());
                if (extendedProperties.Contains("attachmentURLs"))
                {
                    string strBlobURLs = activity.typeProperties.extendedProperties.attachmentURLs.ToString();
                    if (strBlobURLs.Trim().Length > 0)
                    {
                        string[] strArrBlobURLs = strBlobURLs.Split(',');
                        foreach (var blobURLs in strArrBlobURLs)
                        {
                            CloudBlockBlob blob = new CloudBlockBlob(new Uri(blobURLs), storageAccount.Credentials);
                            var memoryStream = new MemoryStream();
                            blob.DownloadToStream(memoryStream);
                            memoryStream.Position = 0;
                            await objMessage.AddAttachmentAsync(blob.Name, memoryStream);
                        }
                    }
                }
            }
            var response = await objSendGridClient.SendEmailAsync(objMessage);
        }
    }
}


