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
        [StringLength(50, ErrorMessage = "Login cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Login must be at least 8 characters long!")]
        public string Login { get; set; } = default!;

        [Required]
        [EmailAddress(ErrorMessage = "Invalid Email Format!")]
        public string Email { get; set; } = default!;

        public string? PasswordHash { get; set; }

        [Required]
        [StringLength(50, ErrorMessage = "Display name cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Display Name must be at least 8 characters long!")]
        public string DisplayName { get; set; } = default!;

        [Phone(ErrorMessage = "Invalid phone number format!")]
        public string? PhoneNumber { get; set; }

        [StringLength(1000, ErrorMessage = "Description cannot be longer than 1000 characters!")]
        public string? Description { get; set; } = "";

        [Required]
        [StringLength(20, ErrorMessage = "Gender cannot be longer than 20 characters!")]
        public string Gender { get; set; } = "Unknown";

        [Required]
        [EnumDataType(typeof(UserRole))]
        public UserRole UserRole { get; set; } = UserRole.GUEST;

        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid image URL!")]
        public string ImageUrl { get; set; } = "wwwroot/defaultuser.png";

        [DataType(DataType.DateTime)]
        public DateTime? Birth { get; set; }

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime RegisteredAt { get; set; } = default!;

        public Address? Address { get; set; }

        //User Settings fields
        [Required]
        [EnumDataType(typeof(ProfileAccessibility))]
        public ProfileAccessibility ProfileAccessibility { get; set; } = ProfileAccessibility.FOLLOWS;

        [Required]
        [EnumDataType(typeof(Theme))]
        public Theme Theme { get; set; } = Theme.DARK;

        [Required]
        [EnumDataType(typeof(Language))]
        public Language Language { get; set; } = Language.ENGLISH;

        [StringLength(100, ErrorMessage = "Location cannot be longer than 100 characters!")]
        public string? Location { get; set; }

        public bool ReceiveEmailNotifications { get; set; } = true;

        public bool EnableDoubleFactorAuthentication { get; set; } = false;

        //Google OAuth fields
        public string? GoogleId { get; set; }

        public string? GoogleProfilePicture { get; set; }

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Location cannot be longer than 255 characters!")]
        public string? Note { get; set; }

        //Database relationships
        public ICollection<UserFollow> Followers { get; set; } = [];
        public ICollection<UserFollow> Followed { get; set; } = [];
        public ICollection<UserToken> UserTokens { get; set; } = [];
        public ICollection<UserPreference> UserPreferences { get; set; } = [];
        public ICollection<UserComment> UserComments { get; set; } = [];
        public ICollection<ForumPost> ForumPosts { get; set; } = [];
        public ICollection<Message> ReceivedMessages { get; set; } = [];
        public ICollection<Message> SentMessages { get; set; } = [];
        public ICollection<Notification> Notifications { get; set; } = [];
    }
}
