 using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Infrastructure.SMTP
{
    /// <summary>
    /// Used by the SMTP service to send emails with embeded images.
    /// </summary>
    public class EmailContent
    {
        [Required]
        public string HtmlBody { get; set; } = default!;

        [Required]
        public string ImagePath { get; set; } = default!;

        [Required]
        public string ContentId { get; set; } = default!;
    }
}
