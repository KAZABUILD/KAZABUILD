using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Settings
{
    public class FrontendSettings
    {
        [Required, MinLength(1)]
        public string[] AllowedFrontendOrigins { get; set; } = [];
    }
}
