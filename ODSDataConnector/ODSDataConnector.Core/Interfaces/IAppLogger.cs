using System;
using System.Collections.Generic;

namespace ODSDataConnector.Core.Interfaces
{
    public interface IAppLogger
    {
        /// <summary>
        /// Logs the information.
        /// </summary>
        /// <param name="message">The message.</param>
        void LogInformation(string message);

        /// <summary>
        /// Logs the information.
        /// </summary>
        /// <param name="message">The message.</param>
        /// <param name="properties">The properties.</param>
        void LogInformation(string message, IDictionary<string, string> properties);

        /// <summary>
        /// Logs the error.
        /// </summary>
        /// <param name="ex">The ex.</param>
        /// <param name="customProperties">The custom properties.</param>
        void LogError(Exception ex, Dictionary<string, string> customProperties);

        /// <summary>
        /// Logs the custom event.
        /// </summary>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="customData">The custom data.</param>
        void LogCustomEvent(string eventName, IDictionary<string, string> customData = null);

        void LogError(Exception ex);
    }
}
