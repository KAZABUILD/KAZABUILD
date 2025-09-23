using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Settings
{
    public class BackendHost
    {
        [Required]
        public string Host { get; set; } = default!;
    }
}
