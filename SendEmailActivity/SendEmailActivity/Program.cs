using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using SendGrid;
using SendGrid.Helpers.Mail;
using Microsoft.Azure;
using Microsoft.WindowsAzure.Storage;
using System.Configuration;
using Microsoft.Azure.Management.DataFactory.Models;
using Newtonsoft.Json;

namespace SendEmailActivity
{
    class Program
    {
        private readonly static string AzureConnectionstring =
                 System.Configuration.ConfigurationManager.AppSettings["AzureconnectionString"];
        private readonly static string blobContainer =
            System.Configuration.ConfigurationManager.AppSettings["blobContainer"];

        [Newtonsoft.Json.JsonProperty(PropertyName = "userProperties")]
        public IList<UserProperty> UserProperties { get; set; }
        static void Main(string[] args)
        {
            //GetBlobDetails();
            Execute().Wait();
            Console.WriteLine("completed");

        }
        //public static void GetBlobDetails()
        //{
        //    var storageAccount = CloudStorageAccount.Parse(AzureConnectionstring);
        //    var blobClient = storageAccount.CreateCloudBlobClient();
        //    var container = blobClient.GetContainerReference(blobContainer);
        //    var blob = container.GetBlockBlobReference("outbound/NewHCPsFound_2020-08-31.csv");
        //    Console.WriteLine("input blob details folder: {0}, filename: {1}", blobContainer, blob);
        //}
        static async Task Execute()
        {

            
            Console.WriteLine("Printng the pipeline properties");
            dynamic activity = JsonConvert.DeserializeObject(File.ReadAllText("activity.json"));
            Console.WriteLine(activity.userProperties[0].value.ToString());
            Console.WriteLine("Completed");
            Console.WriteLine("Printng the LinkedService properties");
            dynamic linkedServices = JsonConvert.DeserializeObject(File.ReadAllText("linkedServices.json"));
            Console.WriteLine(linkedServices);
            Console.WriteLine("Printng the Datasets properties");
            dynamic datasets = JsonConvert.DeserializeObject(File.ReadAllText("datasets.json"));
            Console.WriteLine(datasets);
            Console.WriteLine("Completed");
            
            
            var client = new SendGridClient("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");
            var msg = new SendGridMessage();

            Console.WriteLine (activity.typeProperties.extendedProperties.emailTo.ToString());
            //// For a detailed description of each of these settings, please see the [documentation](https://sendgrid.com/docs/API_Reference/api_v3.html).
            var toEmails = activity.typeProperties.extendedProperties.emailTo.ToString();
            toEmails.split();
            msg.AddTo(new EmailAddress(activity.typeProperties.extendedProperties.emailTo.ToString()));
            var to_emails = new List<EmailAddress>
            {
                new EmailAddress("jagadeeshkumbar1@gmail.com", "Example User2"),
                new EmailAddress("test3@gmail.com", "Example User3")
            };
            msg.AddTos(to_emails);

            msg.AddCc(new EmailAddress(activity.typeProperties.extendedProperties.emailCC.ToString()));
            ////var cc_emails = new List<EmailAddress>
            ////{
            ////    new EmailAddress("test5@gmail.com", "Example User5"),
            ////    new EmailAddress("test6@gmail.com", "Example User6")
            ////};
            ////msg.AddCcs(cc_emails);

            msg.AddBcc(new EmailAddress(activity.typeProperties.extendedProperties.emailBCC.ToString()));
            ////var bcc_emails = new List<EmailAddress>
            ////{
            ////    new EmailAddress("test8@gmail.com", "Example User8"),
            ////    new EmailAddress("test9@gmail.com", "Example User9")
            ////};
            ////msg.AddBccs(bcc_emails);

            //// The values below this comment are global to an entire message

            msg.SetFrom(activity.typeProperties.extendedProperties.emailFrom.ToString());

            msg.SetSubject(activity.typeProperties.extendedProperties.emailSubject.ToString());

            ////msg.SetGlobalSubject("Sending with Twilio SendGrid is Fun");

            //msg.AddContent(MimeType.Text, "and easy to do anywhere, even with C#");
            msg.AddContent(MimeType.Html, activity.typeProperties.extendedProperties.emailBody.ToString());


            //// For base64 encoding, see [`Convert.ToBase64String`](https://msdn.microsoft.com/en-us/library/system.convert.tobase64string(v=vs.110).aspx)
            //// For an example using an attachment, please see this [use case](USE_CASES.md#attachments).
            ////msg.AddAttachment("balance_001.pdf",
            ////                  "base64 encoded string",
            ////                  "application/pdf",
            ////                  "attachment",
            ////                  "Balance Sheet");
            ////var attachments = new List<Attachment>()
            ////{
            ////    new Attachment()
            ////    {
            ////        Content = "base64 encoded string",
            ////        Type = "image/png",
            ////        Filename = "banner.png",
            ////        Disposition = "inline",
            ////        ContentId = "Banner"
            ////    },
            ////    new Attachment()
            ////    {
            ////        Content = "base64 encoded string",
            ////        Type = "image/png",
            ////        Filename = "banner2.png",
            ////        Disposition = "inline",
            ////        ContentId = "Banner 2"
            ////    }
            ////};
            ////msg.AddAttachments(attachments);

            ////using (var fileStream = File.OpenRead("C:\\Users\\Jagadeesh\\Desktop\\DailyTracker.xlsx"))
            ////{
            ////    await msg.AddAttachmentAsync("DailyTracker.xlsx", fileStream);
            ////}

            var storageAccount = CloudStorageAccount.Parse(AzureConnectionstring);
            var blobClient = storageAccount.CreateCloudBlobClient();
            var container = blobClient.GetContainerReference(blobContainer);
            var blob = container.GetBlockBlobReference("outbound/NewHCPsFound_2020-08-31.csv");
            Console.WriteLine("input blob details folder: {0}, filename: {1}", blobContainer, blob);
            var memoryStream = new MemoryStream();
            blob.DownloadToStream(memoryStream);
            memoryStream.Position = 0;
            await msg.AddAttachmentAsync("NewHCPsFound_2020-08-31.csv", memoryStream);

            var response = await client.SendEmailAsync(msg);
            //Console.WriteLine(msg.Serialize());
            //Console.WriteLine(response.StatusCode);
            //Console.WriteLine(response.Body.ReadAsStringAsync().Result);
            //Console.WriteLine(response.Headers);
        }
    }
}


