using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Admin
{
    public class BlockIpRequestDto
    {
        /// <summary>
        /// Ip Address that is block from using the app.
        /// </summary>
        [Required]
        public string IpAddress { get; set; } = default!;

        /// <summary>
        /// The reason for the issued ban.
        /// </summary>
        public string? Reason { get; set; }
    }
}
