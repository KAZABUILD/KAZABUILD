using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.User
{
    public class UpdateUserDto
    {
        /// <summary>
        /// Name that is displayed to other user on the website.
        /// </summary>
        [StringLength(50, ErrorMessage = "Display name cannot be longer than 50 characters!")]
        [MinLength(4, ErrorMessage = "Display Name must be at least 4 characters long!")]
        public string? DisplayName { get; set; }

        /// <summary>
        /// User Login. Has to be unique.
        /// </summary>
        [StringLength(50, ErrorMessage = "Login cannot be longer than 50 characters!")]
        [MinLength(8, ErrorMessage = "Login must be at least 8 characters long!")]
        public string? Login { get; set; }

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
        public string? Description { get; set; }

        /// <summary>
        /// User's gender.
        /// </summary>
        [StringLength(20, ErrorMessage = "Gender cannot be longer than 20 characters!")]
        public string? Gender { get; set; }

        /// <summary>
        /// Id of the images storing the user's profile picture.
        /// If null the frontend should use a default one.
        /// </summary>
        public Guid? ImageId { get; set; }

        /// <summary>
        /// User's date of birth.
        /// Should only ever be set to null when creating an account through OAuth, afterwards the user should be prompted for the date anyway.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? Birth { get; set; }

        /// <summary>
        /// Password decided by the updater for the user. Later hashed and discarded.
        /// </summary>
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long!")]
        public string? Password { get; set; }

        /// <summary>
        /// User Email. Has to be unique.
        /// </summary>
        [EmailAddress(ErrorMessage = "Invalid Email Format!")]
        public string? Email { get; set; }

        /// <summary>
        /// Authentication role given to the user.
        /// Determines how much access to the backend calls and webpages the user has.
        /// </summary>
        [EnumDataType(typeof(UserRole))]
        public UserRole? UserRole { get; set; }

        /// <summary>
        /// User's address. Can be null.
        /// </summary>
        public Address? Address { get; set; }

        /// <summary>
        /// Setting for who can see user's profile.
        /// Hides profiles from browsing if set to private.
        /// </summary>
        [EnumDataType(typeof(ProfileAccessibility))]
        public ProfileAccessibility? ProfileAccessibility { get; set; }

        /// <summary>
        /// Settings for the visual theme used by the user.
        /// </summary>
        [EnumDataType(typeof(Theme))]
        public Theme? Theme { get; set; }

        /// <summary>
        /// Setting for the language used by the user.
        /// </summary>
        [EnumDataType(typeof(Language))]
        public Language? Language { get; set; }

        /// <summary>
        /// User's location automatically saved by the frontend.
        /// </summary>
        [StringLength(100, ErrorMessage = "Location cannot be longer than 100 characters!")]
        public string? Location { get; set; }

        /// <summary>
        /// Setting for whether the user wants to receive promotional emails.
        /// </summary>
        public bool? ReceiveEmailNotifications { get; set; }

        /// <summary>
        /// Settings for whether the user has double factor authentication enabled.
        /// </summary>
        public bool? EnableDoubleFactorAuthentication { get; set; }


        [StringLength(255, ErrorMessage = "Location cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
