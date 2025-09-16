using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;

namespace KAZABUILD.Infrastructure.Services
{
    public class SmtpEmailService(IOptions<SmtpSettings> settings, IServiceProvider serviceProvider) : IEmailService
    {
        private readonly SmtpSettings _settings = settings.Value;
        private readonly IServiceProvider _serviceProvider = serviceProvider;

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            try
            {
                using var client = new SmtpClient(_settings.Host, _settings.Port)
                {
                    Credentials = new NetworkCredential(_settings.Username, _settings.Password),
                    EnableSsl = true
                };
                var mailMessage = new MailMessage(_settings.Username, to, subject, body);
                await client.SendMailAsync(mailMessage);
            }
            catch (Exception ex)
            {
                using var scope = _serviceProvider.CreateScope();
                var logger = scope.ServiceProvider.GetRequiredService<ILoggerService>();

                await logger.LogAsync(
                    Guid.Empty,
                    "Send Email",
                    "SMTPService",
                    "",
                    Guid.Empty,
                    PrivacyLevel.ERROR,
                    $"SMTP Service Unavailable. Skipping sending mail. Error message: {ex.Message}"
                );

                throw;
            }
        }
    }
}
