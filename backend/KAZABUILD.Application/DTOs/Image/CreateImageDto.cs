using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Image
{
    public class CreateImageDto
    {
        /// <summary>
        /// Name which is used for the image in the html.
        /// Can be used to match the returned images to their proper name.
        /// </summary>
        [Required]
        [StringLength(255, ErrorMessage = "Name cannot be longer than 255 characters!")]
        [MinLength(3, ErrorMessage = "Name must be at least 3 characters long!")]
        public string Name { get; set; } = default!;

        /// <summary>
        /// Type of location of the image.
        /// </summary>
        [Required]
        [EnumDataType(typeof(ImageLocationType))]
        public ImageLocationType LocationType { get; set; } = default!;

        /// <summary>
        /// Id of the object this Image is located in.
        /// Which object it's applied to depends on the ImageLocationType set.
        /// </summary>
        public Guid? TargetId { get; set; }
    }
}
