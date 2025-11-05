using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Settings
{
    public class EncryptionSettings
    {
        [Required]
        public string Key { get; set; } = default!;
    }
}
