using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.Build
{
    public class UpdateBuildDto
    {
        /// <summary>
        /// Id of the User that created the Build.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Name given to the Build by the user.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Name cannot be longer than 50 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Description of the Build written by the user.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Description cannot be longer than 500 characters!")]
        public string Description { get; set; } = default!;

        /// <summary>
        /// Current status of the Build.
        /// Determines where on the website the Build is visible
        /// </summary>
        [Required]
        [EnumDataType(typeof(BuildStatus))]
        public BuildStatus Status { get; set; } = BuildStatus.DRAFT;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
