using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserActivity
{
    public class CreateUserActivityDto
    {
        /// <summary>
        /// What type of activity the user performed.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Activity Type cannot be longer than 50 characters!")]
        public string ActivityType { get; set; } = default!;

        /// <summary>
        /// The target Id of the object which the activity was related to.
        /// It's a singular field unlike UserComment and similar since every model in the database could potentially have it's activity logged.
        /// </summary>
        [Required]
        public Guid TargetId { get; set; } = default!;

        /// <summary>
        /// When the activity happened.
        /// </summary>
        [Required]
        public DateTime Timestamp { get; set; } = default!;
    }
}
