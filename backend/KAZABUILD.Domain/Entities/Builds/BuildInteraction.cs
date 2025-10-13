using KAZABUILD.Domain.Entities.Users;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Builds
{
    /// <summary>
    /// Represents Interactions that a user can have with a Build.
    /// </summary>
    public class BuildInteraction
    {
        //User Profile fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the User that Interacted with the Build.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// Id of the Build the user Interacted with.
        /// </summary>
        [Required]
        public Guid BuildId { get; set; } = default!;

        /// <summary>
        /// Whether the user Wishlisted the Build.
        /// </summary>
        [Required]
        public bool IsWishlisted { get; set; } = false;

        /// <summary>
        /// Whether the user Liked the Build.
        /// </summary>
        [Required]
        public bool IsLiked { get; set; } = false;

        /// <summary>
        /// User's Rating for the Build on the scale of 0-100.
        /// </summary>
        [Required]
        [Range(0, 100, ErrorMessage = "Amount must be between 0 and 100!")]
        public int Rating { get; set; } = default!;

        /// <summary>
        /// User's Note for the Build.
        /// </summary>
        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? UserNote { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public Build? Build { get; set; } = default!;
        public User? User { get; set; } = default!;
    }
}
