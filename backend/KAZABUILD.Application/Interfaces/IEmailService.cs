using KAZABUILD.Infrastructure.SMTP;

namespace KAZABUILD.Application.Interfaces
{
    public interface IEmailService
    {
        Task SendEmailAsync(string to, string subject, EmailContent body);
    }
}
