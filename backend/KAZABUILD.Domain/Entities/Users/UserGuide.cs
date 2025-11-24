using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Users
{
    /// <summary>
    /// Model for storing User Guides available on the website for users to learn pc building.
    /// </summary>
    public class UserGuide
    {
        [Key]
        public Guid Id { get; set; }

        /// <summary>
        /// Title of the Guide.
        /// </summary>
        [Required]
        [StringLength(100, ErrorMessage = "Title cannot be longer than 100 characters!")]
        [MinLength(5, ErrorMessage = "Title must be at least 5 characters long!")]
        public string Title { get; set; } = default!;

        /// <summary>
        /// Text of the Guide.
        /// </summary>
        [Required]
        [MinLength(50, ErrorMessage = "Title must be at least 50 characters long!")]
        public string Text { get; set; } = default!;

        /// <summary>
        /// Author of the Guide.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        [MinLength(5, ErrorMessage = "Title must be at least 5 characters long!")]
        public string Author { get; set; } = default!;

        /// <summary>
        /// Category of the Guide.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        [MinLength(5, ErrorMessage = "Title must be at least 5 characters long!")]
        public string Category { get; set; } = default!;

        /// <summary>
        /// Estimated Time required To Read the guide in minutes.
        /// </summary>
        [Required]
        [Range(0, 1000, ErrorMessage = "Time To Read must be between 0 and 1000 min")]
        [Precision(6, 2)]
        public decimal TimeToRead { get; set; } = default!;

        /// <summary>
        /// Date of posting.
        /// </summary>
        [Required]
        [DataType(DataType.DateTime)]
        public DateTime PostedAt { get; set; } = default!;

        //Additional database information
        [DataType(DataType.DateTime)]
        public DateTime DatabaseEntryAt { get; set; } = DateTime.UtcNow;

        [DataType(DataType.DateTime)]
        public DateTime LastEditedAt { get; set; } = DateTime.UtcNow;

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
