using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model representing a Block of a User by another User.
    /// </summary>
    public class UserBlock
    {
        [Key]
        public Guid Id { get; set; }

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

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
        public User? BlockedUser { get; set; } = default!;
    }
}
