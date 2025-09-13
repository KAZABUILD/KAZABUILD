using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    public class UserToken
    {
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

        [Required]
        [DataType(DataType.DateTime)]
        public DateTime UsedAt { get; set; } = default!;

        [Required]
        [StringLength(25, ErrorMessage = "Token Type cannot be longer than 25 characters!")]
        public string IpAddress { get; set; } = default!;

        [Required]
        [StringLength(255, ErrorMessage = "Url cannot be longer than 255 characters!")]
        [Url(ErrorMessage = "Invalid redirect URL!")]
        public string RedirectUrl { get; set; } = default!;
    }
}
