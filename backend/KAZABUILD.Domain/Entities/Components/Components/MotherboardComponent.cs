using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.Entities.Components.Components
{
    /// <summary>
    /// Represents the Motherboard which connect all the other components together.
    /// </summary>
    public class MotherboardComponent : BaseComponent
    {
        /// <summary>
        /// CPU Socket Type supported by the Motherboard (e.g., AM5, LGA1700, TR4).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Socket cannot be longer than 50 characters!")]
        public string SocketType { get; set; } = default!;

        /// <summary>
        /// Design aspect that defines the size, shape, and other physical specifications of the Motherboard (e.g., ATX, Micro-ATX, Mini-ITX).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string FormFactor { get; set; } = default!;

        /// <summary>
        /// Chipset Type used by the Motherboard (e.g., Z790, B650, X670E).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Chipset cannot be longer than 50 characters!")]
        public string ChipsetType { get; set; } = default!;

        /// <summary>
        /// Which generation of the DDR (Double Data Rate) the Motherboard supports (e.g., DDR4, DDR5).
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "RAM type cannot be longer than 50 characters!")]
        public string RAMType { get; set; } = default!;

        /// <summary>
        /// The Amount of expansion Slots available for RAM.
        /// </summary>
        [Required]
        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 0 and 15")]
        public string RAMSlotsAmount { get; set; } = default!;

        /// <summary>
        /// The maximum amount of RAM the motherboard can support in GB.
        /// </summary>
        [Required]
        [Range(0, 1024 , ErrorMessage = "MaxRAM Amount must be between 0 and 1024")]
        public int MaxRAM { get; set; } = default!;

        /// <summary>
        /// The amount of sata_6_gb_s available in the motherboard.
        /// </summary>
        [Required]
        [Range(0, 20, ErrorMessage = "Sata6Gbs Amount must be between 0 and 20")]
        public int Sata6Gbs { get; set; } = default!;

        /// <summary>
        /// The amount of sata_3_gb_s ports available in the motherboard.
        /// </summary>
        [Required]
        [Range(0, 20, ErrorMessage = "Sata3Gbs Amount must be between 0 and 20")]
        public int Sata3Gbs { get; set; } = default!;

        /// <summary>
        /// The amount of U2 ports available in the motherboard.
        /// </summary>
        [Required]
        [Range(0, 20, ErrorMessage = "U2 Amount must be between 0 and 20")]
        public int U2 { get; set; } = default!;

        /// <summary>
        /// Supported wifi standards. E.g. Wifi 6E, Wifi 7, etc.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "wirelessNetworking type cannot be longer than 50 characters!")]
        public string wirelessNetworking { get; set; } = default!;

        /// <summary>
        /// Number of CPU fan headers (typically 4-pin PWM).
        /// </summary>
        [Range(0, 20, ErrorMessage = "CpuFan Amount must be between 0 and 20")]
        public int? CpuFan { get; set; }

        /// <summary>
        /// Number of case/chassis fan headers (typically 4-pin PWM).
        /// </summary>
        [Range(0, 20, ErrorMessage = "CaseFan Amount must be between 0 and 20")]
        public int? CaseFan { get; set; }

        /// <summary>
        /// Number of dedicated pump headers for AIO coolers.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Pump Amount must be between 0 and 20")]
        public int? Pump { get; set; }

        /// <summary>
        /// Number of CPU optional fan headers.
        /// </summary>
        [Range(0, 20, ErrorMessage = "CpuOptFan Amount must be between 0 and 20")]
        public int? CpuOptFan { get; set; }

        /// <summary>
        /// Number of addressable RGB headers (5V, 3-pin).
        /// </summary>
        [Range(0, 20, ErrorMessage = "CpuOptFan Amount must be between 0 and 20")]
        public int? Argb5v { get; set; }

        /// <summary>
        /// Number of standard RGB headers (12V, 4-pin).
        /// </summary>
        [Range(0, 20, ErrorMessage = "Rgb12v Amount must be between 0 and 20")]
        public int? Rgb12v { get; set; }

        /// <summary>
        /// Whether the motherboard has a power button header (could not be listed in the database).
        /// </summary>
        public bool? HasPowerButton { get; set; }

        /// <summary>
        /// Whether the motherboard has a reset button header (could not be listed in the database).
        /// </summary>
        public bool? HasResetButton { get; set; }

        /// <summary>
        /// Whether the motherboard has a power led header (could not be listed in the database).
        /// </summary>
        public bool? HasPowerLED { get; set; }

        /// <summary>
        /// Whether the motherboard has a hard drive activity light header (could not be listed in the database).
        /// </summary>
        public bool? HasHddLED { get; set; }

        /// <summary>
        /// Number of temperature sensor headers.
        /// </summary>
        [Range(0, 20, ErrorMessage = "TempratureSensor Amount must be between 0 and 20")]
        public int? TempratureSensor { get; set; }

        /// <summary>
        /// Number of thunderbolt headers.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Thunderbolt Amount must be between 0 and 20")]
        public int? Thunderbolt { get; set; }

        /// <summary>
        /// Number of COM port headers.
        /// </summary>
        [Range(0, 20, ErrorMessage = "comPort Amount must be between 0 and 20")]
        public int? comPort { get; set; }

        /// <summary>
        /// Main power connector specification (e.g., '24-pin').
        /// </summary>
        [StringLength(50, ErrorMessage = "Main power type cannot be longer than 50 characters!")]
        public string? MainPower { get; set; }

        /// <summary>
        /// Whether the motherboard supports ECC memory.
        /// <summary>
        [Required]
        public bool HasEccSupport { get; set; } = default!;

        /// <summary>
        /// Whether the motherboard supports RAID configurations.
        /// <summary>
        [Required]
        public bool HasRaidSupport { get; set; } = default!;

        /// <summary>
        /// Whether the board has BIOS flashback capability.
        /// <summary>
        [Required]
        public bool HasFalshback { get; set; } = default!;

        /// <summary>
        /// Whether the board has a clear Complementary Metal-Oxide-Semiconductor (CMOS) button.
        /// <summary>
        [Required]
        public bool HasClearCmos { get; set; } = default!;

        /// <summary>
        /// Details on the audio chipset used.
        /// </summary>
        [Required]
        [StringLength(50, ErrorMessage = "Audio Chipset cannot be longer than 50 characters!")]
        public string AudioChipset { get; set; } = default!;

        /// <summary>
        /// Number of audio channels supported.
        /// </summary>
        [Required]
        [Range(0, 64.99 ErrorMessage = "Channel Amount must be between 0 and 64.99")]
        public decimal AudioChannels { get; set; } = default!;

    }
}
