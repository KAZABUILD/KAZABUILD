using KAZABUILD.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class User
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        [StringLength(50)]
        [MinLength(8)]
        public string Login { get; set; } = default!;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = default!;

        [Required]
        [MinLength(8)]
        public string PasswordHash { get; set; } = default!;

        [Required]
        [StringLength(50)]
        [MinLength(8)]
        public string DisplayName { get; set; } = default!;

        [Phone]
        public string? PhoneNumber { get; set; }

        [StringLength(1000)]
        public string? Description { get; set; } = "";

        [Required]
        [StringLength(20)]
        public string Gender { get; set; } = "Not Set";

        [Required]
        [StringLength(50)]
        [MinLength(8)]
        public UserRole UserRole { get; set; } = UserRole.GUEST;

        [Required]
        [StringLength(255)]
        [Url]
        public string ImageUrl { get; set; } = "Not Set";

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime RegisteredAt { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;


    }
}
