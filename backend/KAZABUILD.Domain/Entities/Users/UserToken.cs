using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Class storing temporary user token used in the auth controller.
    /// The token get cleaned-up every 7 days in the CleanupService.
    /// </summary>
    public class UserToken
    {
        //User Token fields
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Id of the user that requested the token.
        /// </summary>
        [Required]
        public Guid UserId { get; set; } = default!;

        /// <summary>
        /// The actual token string.
        /// </summary>
        [Required]
        public string Token { get; set; } = default!;

        /// <summary>
        /// Type of the token used to distinguish what action is it created for.
        /// </summary>
        [Required]
        [EnumDataType(typeof(TokenType))]
        public TokenType TokenType { get; set; } = default!;

        /// <summary>
        /// Date when the token was created at.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime CreatedAt { get; set; } = default!;

        /// <summary>
        /// Expiry date of the token.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime ExpiresAt { get; set; } = default!;

        /// <summary>
        /// Date when the token was used.
        /// Nullable at first so that this value can be used to determine whether the token was used or not. 
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? UsedAt { get; set; }

        /// <summary>
        /// IpAddress of the user for additional IP verification.
        /// </summary>
        [Required]
        [StringLength(25, ErrorMessage = "Token Type cannot be longer than 25 characters!")]
        public string IpAddress { get; set; } = default!;

        /// <summary>
        /// The address the user should be redirected to on the main website after using the token.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid redirect URL!")]
        public string RedirectUrl { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        //Database relationships
        public User? User { get; set; } = default!;
    }
}
