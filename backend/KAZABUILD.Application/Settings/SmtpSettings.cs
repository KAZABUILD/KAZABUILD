using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Settings
{
    public class SmtpSettings
    {
        [Required]
        public string Host { get; set; } = default!;

        public int Port { get; set; } = 587;

        [Required]
        public string Username { get; set; } = default!;

        [Required]
        public string Password { get; set; } = default!;
    }
}
