using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Enums;

using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using MimeKit;
using MailKit.Net.Smtp;

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
                //Create the message to be sent
                var message = new MimeMessage();
                message.From.Add(MailboxAddress.Parse(_settings.Username));
                message.To.Add(MailboxAddress.Parse(to));
                message.Subject = subject;
                message.Body = new TextPart("html") { Text = body };

                //Create the client which will send the message
                using var client = new SmtpClient();

                //Connect to the SMTP service
                await client.ConnectAsync("smtp.gmail.com", _settings.Port, MailKit.Security.SecureSocketOptions.SslOnConnect);

                //Authenticate the account sending the email
                await client.AuthenticateAsync(_settings.Username, _settings.Password);

                //Send the email
                await client.SendAsync(message);

                //Disconnect the client
                await client.DisconnectAsync(true);
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
