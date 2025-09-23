using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class UserPreference
    {
        //User Preferences fields
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid UserId { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Location cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
    }
}
