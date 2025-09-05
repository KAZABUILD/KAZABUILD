using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;

namespace KAZABUILD.Infrastructure.Services
{
    public class SmtpEmailService : IEmailService
    {
        private readonly SmtpSettings _settings;

        public SmtpEmailService(IOptions<SmtpSettings> settings)
        {
            _settings = settings.Value;
        }

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            using var client = new SmtpClient(_settings.Host, _settings.Port)
            {
                Credentials = new NetworkCredential(_settings.Username, _settings.Password),
                EnableSsl = true
            };
            var mailMessage = new MailMessage(_settings.Username, to, subject, body);
            await client.SendMailAsync(mailMessage);
        }
    }
}
