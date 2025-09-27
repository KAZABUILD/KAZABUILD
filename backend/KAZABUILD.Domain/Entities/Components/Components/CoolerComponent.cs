using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the Cooling system in the computer. Required for the computer not too overheat and break.
    /// </summary>
    public class CoolerComponent : BaseComponent
    {
        /// <summary>
        /// Minimum fan rotation speed in RPM (Rotations Per Minute).
        /// </summary>
        [Required]
        [Range(0, 6000, ErrorMessage = "Minimum Fan Rotation Speed must be between 0 and 6000 RPM")]
        public int MinFanRotationSpeed { get; set; } = default!;

        /// <summary>
        /// Maximum fan rotation speed in RPM (Rotations Per Minute).
        /// Leave as null if a constant and just fill in the Min Fan Rotation Speed.
        /// </summary>
        [Range(0, 6000, ErrorMessage = "Maximum Fan Rotation Speed must be between 0 and 6000 RPM")]
        public int? MaxFanRotationSpeed { get; set; }

        /// <summary>
        /// Minimum noise level in dBA.
        /// </summary>
        [Required]
        [Range(0, 100, ErrorMessage = "Minimum Noise Level must be between 0 and 100 dB")]
        public int MinNoiseLevel { get; set; } = default!;

        /// <summary>
        /// Maximum noise level in dB.
        /// Leave as null if a constant and just fill in the Min Noise Level.
        /// </summary>
        [Range(0, 100, ErrorMessage = "Maximum Noise Level must be between 0 and 100 dB")]
        public int? MaxNoiseLevel { get; set; }

        /// <summary>
        /// Height of the cooler in mm.
        /// </summary>
        [Required]
        [Range(0, 400, ErrorMessage = "Height must be between 0 and 400 mm")]
        public decimal Height { get; set; } = default!;

        /// <summary>
        /// Whether the cooler uses water-cooling.
        /// </summary>
        [Required]
        public bool IsWaterCooled { get; set; } = default!;

        /// <summary>
        /// Radiator size in mm.
        /// Applies only if water-cooled.
        /// </summary>
        [Range(0, 1000, ErrorMessage = "Radiator Size must be between 0 and 1000 mm")]
        public decimal? RadiatorSize { get; set; }

        /// <summary>
        /// Whether the cooler can operate fanless.
        /// </summary>
        [Required]
        public bool CanOperateFanless { get; set; } = default!;

        /// <summary>
        /// Size of the fan(s) included with the cooler in mm.
        /// </summary>
        [Range(40, 500, ErrorMessage = "Fan Size must be between 10 and 500 mm")]
        public decimal? FanSize { get; set; }

        /// <summary>
        /// Quantity of fans included with the cooler.
        /// </summary>
        [Range(0, 10, ErrorMessage = "Fan Quantity must be between 0 and 10")]
        public int? FanQuantity { get; set; }
    }
}
