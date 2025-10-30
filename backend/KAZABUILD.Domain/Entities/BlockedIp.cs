using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities
{
    /// <summary>
    /// Stores ip address block from using the app by the administration.
    /// </summary>
    public class BlockedIp
    {
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Ip Address that is block from using the app.
        /// </summary>
        [Required]
        [StringLength(50)]
        public string IpAddress { get; set; } = default!;

        /// <summary>
        /// When the ban was issued.
        /// </summary>
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Who issued the ban.
        /// </summary>
        public Guid? BlockedByUserId { get; set; }

        /// <summary>
        /// The reason for the issued ban.
        /// </summary>
        [StringLength(255)]
        public string? Reason { get; set; }
    }
}
