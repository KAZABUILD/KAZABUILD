using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Settings
{
    public class FrontendSettings
    {
        [Required, MinLength(1, ErrorMessage = "At least one frontend origin must be specified.")]
        public string[] AllowedFrontendOrigins { get; set; } = [];
    }
}
