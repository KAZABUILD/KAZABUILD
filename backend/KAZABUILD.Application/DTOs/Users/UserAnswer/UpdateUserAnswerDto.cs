using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserAnswer
{
    public class UpdateUserAnswerDto
    {
        [StringLength(255, ErrorMessage = "Location cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
