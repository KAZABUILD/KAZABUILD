using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Users.UserGuide
{
    public class UpdateUserGuideDto
    {
        /// <summary>
        /// Title of the Guide.
        /// </summary>
        [StringLength(100, ErrorMessage = "Title cannot be longer than 100 characters!")]
        [MinLength(5, ErrorMessage = "Title must be at least 5 characters long!")]
        public string? Title { get; set; }

        /// <summary>
        /// Text of the Guide.
        /// </summary>
        [MinLength(50, ErrorMessage = "Title must be at least 50 characters long!")]
        public string? Text { get; set; }

        /// <summary>
        /// Author of the Guide.
        /// </summary>
        [StringLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        [MinLength(5, ErrorMessage = "Title must be at least 5 characters long!")]
        public string? Author { get; set; }

        /// <summary>
        /// Category of the Guide.
        /// </summary>
        [StringLength(50, ErrorMessage = "Title cannot be longer than 50 characters!")]
        [MinLength(5, ErrorMessage = "Title must be at least 5 characters long!")]
        public string? Category { get; set; }

        /// <summary>
        /// Estimated Time required To Read the guide in minutes.
        /// </summary>
        [Range(0, 1000, ErrorMessage = "Time To Read must be between 0 and 1000 min")]
        [Precision(6, 2)]
        public decimal? TimeToRead { get; set; }

        /// <summary>
        /// Date of posting.
        /// </summary>
        [DataType(DataType.DateTime)]
        public DateTime? PostedAt { get; set; }

        [StringLength(255, ErrorMessage = "Note cannot be longer than 255 characters!")]
        public string? Note { get; set; }
    }
}
