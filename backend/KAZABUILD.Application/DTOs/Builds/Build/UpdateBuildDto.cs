using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Builds.Build
{
    public class UpdateBuildDto
    {
        /// <summary>
        /// Id of the User that created the Build.
        /// Updating value transfers ownership.
        /// </summary>
        public Guid? UserId { get; set; }

        /// <summary>
        /// Name given to the Build by the user.
        /// </summary>
        [StringLength(50, ErrorMessage = "Name cannot be longer than 50 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string? Name { get; set; }

        /// <summary>
        /// Description of the Build written by the user.
        /// </summary>
        [StringLength(5000, ErrorMessage = "Description cannot be longer than 5000 characters!")]
        public string? Description { get; set; }

        /// <summary>
        /// Current status of the Build.
        /// Determines where on the website the Build is visible
        /// </summary>
        [EnumDataType(typeof(BuildStatus))]
        public BuildStatus? Status { get; set; } = BuildStatus.DRAFT;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
