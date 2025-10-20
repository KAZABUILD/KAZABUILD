using KAZABUILD.Domain.Enums;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Image
{
    public class CreateImageDto
    {
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
