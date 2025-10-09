using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.ValueObjects
{
    public class Dimension
    {
        [Required]
        [Range(0, 1000, ErrorMessage = "Depth must be between 0 and 1000 mm")]
        [Precision(6, 2)]
        public decimal Depth { get; set; } = default;

        [Required]
        [Range(0, 1000, ErrorMessage = "Height must be between 0 and 1000 mm")]
        [Precision(6, 2)]
        public decimal Height { get; set; } = default;

        [Required]
        [Range(0, 1000, ErrorMessage = "Width must be between 0 and 1000 mm")]
        [Precision(6, 2)]
        public decimal Width { get; set; } = default;
    }
}
