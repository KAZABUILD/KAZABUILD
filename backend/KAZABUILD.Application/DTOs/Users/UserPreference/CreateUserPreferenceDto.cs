using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserPreference
{
    public class CreateUserPreferenceDto
    {
        [Required]
        public Guid UserId { get; set; } = default!;
    }
}
