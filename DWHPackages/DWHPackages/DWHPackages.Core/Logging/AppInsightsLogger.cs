using DWHPackages.Core.Interfaces;
using Microsoft.ApplicationInsights;
using Microsoft.IdentityModel.Abstractions;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DWHPackages.Core.Logging
{
    public class AppInsightsLogger : IAppLogger
    {
        private readonly TelemetryClient telemetryClient;

        public AppInsightsLogger(TelemetryClient telemetryClient)
        {
            this.telemetryClient = telemetryClient;
            this.telemetryClient.Context.Operation.Id = "ODSDataConnectorAPI_" + DateTime.UtcNow.ToString("yyyyMMddHHmmss", CultureInfo.CurrentCulture);
        }

        public void LogCustomEvent(string eventName, IDictionary<string, string> customData = null)
        {
            try
            {
                if (customData == null)
                {
                    this.telemetryClient.TrackEvent(eventName);
                }
                else
                {
                    this.telemetryClient.TrackEvent(eventName, customData);
                }
            }
            catch (Exception ex)
            {
                Trace.TraceError(FormatExceptionMessage(ex));
            }
        }

        public void LogError(Exception ex)
        {
            if (ex != null)
            {
                try
                {
                    this.telemetryClient.TrackException(ex);
                }
                catch (Exception exc)
                {
                    Trace.TraceError(FormatExceptionMessage(exc));
                }
            }
        }

        public void LogError(Exception ex, Dictionary<string, string> customProperties)
        {
            if (ex != null)
            {
                try
                {
                    this.telemetryClient.TrackException(ex, customProperties);
                    Trace.TraceError(FormatExceptionMessage(ex));
                }
                catch (Exception exc)
                {
                    Trace.TraceError(FormatExceptionMessage(exc));
                }
            }
        }

        public void LogInformation(string message)
        {
            if (message != null)
            {
                try
                {
                    this.telemetryClient.TrackTrace(message);
                    Trace.TraceInformation(message);
                }
                catch (Exception ex)
                {
                    Trace.TraceError(FormatExceptionMessage(ex));
                }
            }
        }

        public void LogInformation(string message, IDictionary<string, string> properties)
        {
            if (message != null)
            {
                try
                {
                    this.telemetryClient.TrackTrace(message, properties);
                    Trace.TraceInformation(message);
                }
                catch (Exception ex)
                {
                    Trace.TraceError(FormatExceptionMessage(ex));
                }
            }
        }

        /// <summary>
        /// Formats the exception message.
        /// </summary>
        /// <param name="e">The exception.</param>
        /// <param name="fmt">The FMT.</param>
        /// <param name="variableObject">The variableObject.</param>
        /// <returns>returns string</returns>
        private static string FormatExceptionMessage(Exception e, string fmt = "", object[] variableObject = null)
        {
            var sb = new StringBuilder();
            if (!string.IsNullOrEmpty(fmt))
            {
                sb.Append(string.Format(CultureInfo.InvariantCulture, fmt, variableObject));
            }

            do
            {
                sb.AppendLine(e.Message);
                if (e.InnerException == null)
                {
                    sb.AppendLine(e.StackTrace);
                }

                e = e.InnerException;
            }
            while (e != null);

            return sb.ToString();
        }
    }
}
