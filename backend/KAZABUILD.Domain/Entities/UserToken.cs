using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class UserToken
    {
        //User Token fields
        [Key]
        public Guid Id { get; set; } = default!;

        [Required]
        public Guid UserId { get; set; } = default!;

        [Required]
        public string TokenHash { get; set; } = default!;

        [Required]
        [StringLength(25, ErrorMessage = "Token Type cannot be longer than 25 characters!")]
        public string TokenType { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime CreatedAt { get; set; } = default!;

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime ExpiresAt { get; set; } = default!;

        [DataType(DataType.DateTime)]
        public DateTime? UsedAt { get; set; }

        [Required]
        [StringLength(25, ErrorMessage = "Token Type cannot be longer than 25 characters!")]
        public string IpAddress { get; set; } = default!;

        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid redirect URL!")]
        public string RedirectUrl { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        public string? Note { get; set; }

        //Database relationships
        public User? User { get; set; } = default!;
    }
}
