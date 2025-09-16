using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Settings
{
    public class FrontendHost
    {
        [Required]
        public string Host { get; set; } = default!;
    }
}
