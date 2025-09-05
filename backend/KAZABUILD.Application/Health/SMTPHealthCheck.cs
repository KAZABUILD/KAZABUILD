using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;

namespace KAZABUILD.Application.Health
{
    public class SmtpHealthCheck(IOptions<SmtpSettings> settings) : IHealthCheck
    {
        private readonly SmtpSettings _settings = settings.Value;

        public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
        {
            //Try to establish a connection, return if it failed or not
            try
            {
                using var client = new SmtpClient(_settings.Host, _settings.Port)
                {
                    EnableSsl = true,
                    Credentials = new NetworkCredential(_settings.Username, _settings.Password),
                    Timeout = 3000
                };

                //Establish a connection
                await client.SendMailAsync(
                    new MailMessage(_settings.Username, _settings.Username, "HealthCheck", "OK"),
                    cancellationToken
                );

                return HealthCheckResult.Healthy("SMTP reachable");
            }
            catch (Exception ex)
            {
                return HealthCheckResult.Unhealthy("SMTP connection failed", ex);
            }
        }
    }
}
