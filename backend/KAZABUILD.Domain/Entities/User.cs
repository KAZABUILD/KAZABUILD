using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class User
    {
        //User Profile fields
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
        public string Gender { get; set; } = "Unknown";

        [Required]
        public UserRole UserRole { get; set; } = UserRole.GUEST;

        [Required]
        [StringLength(255)]
        [Url]
        public string ImageUrl { get; set; } = "wwwroot/defaultuser.png";

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime Birth { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime RegisteredAt { get; set; } = default!;

        public Address? Address { get; set; }

        //User Settings fields
        [Required]
        public ProfileAccessibility ProfileAccessibility { get; set; } = ProfileAccessibility.FOLLOWS;

        [Required]
        public Theme Theme { get; set; } = Theme.DARK;

        [Required]
        public Language Language { get; set; } = Language.ENGLISH;

        [StringLength(100)]
        public string? Location { get; set; }

        [Required]
        public bool ReceiveEmailNotifications { get; set; } = true; 

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255)]
        public string? Note { get; set; }

        //Database relationships
        public ICollection<UserFollow>? Followers { get; }
        public ICollection<UserFollow>? Followed { get; }
    }
}
