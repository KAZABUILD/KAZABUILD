using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Service that controls sending authentication emails.
    /// </summary>
    /// <param name="settings"></param>
    /// <param name="serviceProvider"></param>
    public class SmtpEmailService(IOptions<SmtpSettings> settings, IServiceProvider serviceProvider) : IEmailService
    {
        private readonly SmtpSettings _settings = settings.Value;
        private readonly IServiceProvider _serviceProvider = serviceProvider;

        /// <summary>
        /// Sends emails asynchronously.
        /// </summary>
        /// <param name="to"></param>
        /// <param name="subject"></param>
        /// <param name="body"></param>
        /// <returns></returns>
        public async Task SendEmailAsync(string to, string subject, string body)
        {
            try
            {
                //Create a client that will send the mail using credentials from settings
                using var client = new SmtpClient(_settings.Host, _settings.Port)
                {
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(_settings.Username, _settings.Password),
                    EnableSsl = true
                };

                //Create the message to be sent, set it so html can be sent. 
                var mailMessage = new MailMessage(_settings.Username, to, subject, body);

                //Send the email
                await client.SendMailAsync(mailMessage);
            }
            catch (Exception ex)
            {
                //Get the scope to call the logger
                using var scope = _serviceProvider.CreateScope();
                var logger = scope.ServiceProvider.GetRequiredService<ILoggerService>();

                //Log failure
                await logger.LogAsync(
                    Guid.Empty,
                    "Send Email",
                    "SMTPService",
                    "",
                    Guid.Empty,
                    PrivacyLevel.ERROR,
                    $"SMTP Service Error. Skipping sending mail. Error message: {ex.Message}"
                );

                throw;
            }
        }
    }
}
