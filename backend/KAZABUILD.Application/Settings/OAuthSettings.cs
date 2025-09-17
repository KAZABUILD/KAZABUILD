using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Settings
{
    public class OAuthSettings
    {
        [Required]
        public GoogleSettings Google { get; set; } = default!;
    }

    public class GoogleSettings
    {
        [Required]
        public string ClientId { get; set; } = default!;

        [Required]
        public string ClientSecret { get; set; } = default!;
    }
}
