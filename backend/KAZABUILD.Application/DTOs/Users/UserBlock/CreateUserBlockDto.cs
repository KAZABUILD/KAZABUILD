using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserBlock
{
    public class CreateUserBlockDto
    {
        /// <summary>
        /// Id of the User who Reported the other User.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Id of the User who is getting Reported.
        /// </summary>
        [Required]
        public Guid BlockedUserId { get; set; } = default!;
    }
}
