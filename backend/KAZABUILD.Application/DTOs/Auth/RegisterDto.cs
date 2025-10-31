using KAZABUILD.Application.Validators;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Auth
{
    /// <summary>
    /// Full user registration form.
    /// </summary>
    public class RegisterDto
    {
        /// <summary>
        /// User Login. Has to be unique.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Login cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Login must be at least 8 characters long!")]
        public string Login { get; set; } = default!;

        /// <summary>
        /// User Email. Has to be unique.
        /// </summary>
        [Required]
        [EmailAddress(ErrorMessage = "Invalid Email Format!")]
        public string Email { get; set; } = default!;

        /// <summary>
        /// Password set by the user. Later hashed and discarded.
        /// </summary>
        [Required]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string Password { get; set; } = default!;

        /// <summary>
        /// Name that is displayed to other user on the website.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Display name cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Display Name must be at least 8 characters long!")]
        public string DisplayName { get; set; } = default!;

        /// <summary>
        /// Nullable Phone Number.
        /// </summary>
        [Phone(ErrorMessage = "Invalid phone number format!")]
        public string? PhoneNumber { get; set; }

        /// <summary>
        /// User's profile description.
        /// Should be saved as html.
        /// </summary>
        [StringLength(1000, ErrorMessage = "Description cannot be longer than 1000 characters!")]
        public string? Description { get; set; } = "";

        /// <summary>
        /// User's gender.
        /// </summary>
        [Required]
        [StringLength(20, ErrorMessage = "Gender cannot be longer than 20 characters!")]
        public string Gender { get; set; } = "Unknown";

        /// <summary>
        /// Id of the images storing the user's profile picture.
        /// If null the frontend should use a default one.
        /// </summary>
        public Guid? ImageId { get; set; }

        /// <summary>
        /// User's date of birth.
        /// Should only ever be set to null when creating an account through OAuth, afterwards the user should be prompted for the date anyway.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime Birth { get; set; }

        /// <summary>
        /// Data of registration.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime RegisteredAt { get; set; }

        /// <summary>
        /// User's address. Can be null.
        /// </summary>
        public Address? Address { get; set; }

        /// <summary>
        /// Setting for who can see user's profile.
        /// Hides profiles from browsing if set to private.
        /// </summary>
        [Required]
        [EnumDataType(typeof(ProfileAccessibility))]
        public ProfileAccessibility ProfileAccessibility { get; set; } = ProfileAccessibility.FOLLOWS;

        /// <summary>
        /// Settings for the visual theme used by the user.
        /// </summary>
        [Required]
        [EnumDataType(typeof(Theme))]
        public Theme Theme { get; set; } = Theme.DARK;

        /// <summary>
        /// Setting for the language used by the user.
        /// </summary>
        [Required]
        [EnumDataType(typeof(Language))]
        public Language Language { get; set; } = Language.ENGLISH;

        /// <summary>
        /// User's location automatically saved by the frontend.
        /// </summary>
        [StringLength(100, ErrorMessage = "Location cannot be longer than 100 characters!")]
        public string? Location { get; set; }

        /// <summary>
        /// Setting for whether the user wants to receive promotional emails.
        /// </summary>
        public bool ReceiveEmailNotifications { get; set; } = true;

        /// <summary>
        /// Settings for whether the user has double factor authentication enabled.
        /// </summary>
        public bool EnableDoubleFactorAuthentication { get; set; } = false;

        /// <summary>
        /// Redirect Url provided by the frontend to redirect to page on the website for custom behaviour.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [RelativePath(ErrorMessage = "Invalid redirect URL!")]
        public string RedirectUrl { get; set; } = default!;
    }
}
