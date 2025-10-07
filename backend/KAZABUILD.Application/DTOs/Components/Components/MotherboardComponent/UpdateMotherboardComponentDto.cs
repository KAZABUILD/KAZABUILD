using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class UpdateMotherboardComponentDto : UpdateBaseComponentDto
    {
        /// <summary>
        /// CPU Socket Type supported by the Motherboard (e.g., AM5, LGA1700, TR4).
        /// </summary>
        [StringLength(50, ErrorMessage = "Socket cannot be longer than 50 characters!")]
        public string? SocketType { get; set; }

        /// <summary>
        /// Design aspect that defines the size, shape, and other physical specifications of the Motherboard (e.g., ATX, Micro-ATX, Mini-ITX).
        /// </summary>
        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string? FormFactor { get; set; }

        /// <summary>
        /// Chipset Type used by the Motherboard (e.g., Z790, B650, X670E).
        /// </summary>
        [StringLength(50, ErrorMessage = "Chipset cannot be longer than 50 characters!")]
        public string? ChipsetType { get; set; }

        /// <summary>
        /// Which generation of the DDR (Double Data Rate) the Motherboard supports (e.g., DDR4, DDR5).
        /// </summary>
        [StringLength(50, ErrorMessage = "RAM type cannot be longer than 50 characters!")]
        public string? RAMType { get; set; }

        /// <summary>
        /// The Amount of expansion Slots available for RAM.
        /// </summary>
        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 0 and 15")]
        public int? RAMSlotsAmount { get; set; }

        /// <summary>
        /// The maximum Amount of RAM the Motherboard can support in GB.
        /// </summary>
        [Range(0, 1024, ErrorMessage = "Max RAM Amount must be between 0 and 1024")]
        public int? MaxRAMAmount { get; set; }

        /// <summary>
        /// The Amount of Serial AT Attachment (SATA) with 6 GBs speed available in the Motherboard.
        /// SATA is a computer bus interface that connects host bus adapters to mass storage devices.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Serial AT Attachment 6GBs Amount must be between 0 and 20")]
        public int? SerialATAttachment6GBsAmount { get; set; }

        /// <summary>
        /// The Amount of Serial AT Attachment (SATA) with 6 GBs speed available in the Motherboard.
        /// SATA is a computer bus interface that connects host bus adapters to mass storage devices.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Serial AT Attachment 3GBs Amount must be between 0 and 20")]
        public int? SerialATAttachment3GBsAmount { get; set; }

        /// <summary>
        /// The Amount of U2 Ports used to connect SSD's available in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "U2 Port Amount must be between 0 and 20")]
        public int? U2PortAmount { get; set; }

        /// <summary>
        /// Supported WiFi Standard (E.g., WiFi 6E, WiFi 7).
        /// </summary>
        [StringLength(50, ErrorMessage = "Wireless Networking Standard cannot be longer than 50 characters!")]
        public string? WirelessNetworkingStandard { get; set; }

        /// <summary>
        /// Number of CPU Fan Headers (typically 4-pin PWM) in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "CPU Fan Header Amount must be between 0 and 20")]
        public int? CPUFanHeaderAmount { get; set; }

        /// <summary>
        /// Number of Case/chassis fan Headers (typically 4-pin PWM) in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Case Fan Header Amount must be between 0 and 20")]
        public int? CaseFanHeaderAmount { get; set; }

        /// <summary>
        /// Number of dedicated pump Headers for liquid (AIO) coolers in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Pump Header Amount must be between 0 and 20")]
        public int? PumpHeaderAmount { get; set; }

        /// <summary>
        /// Number of Optional CPU Fan Headers in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "CPU Optional Fan Header Amount must be between 0 and 20")]
        public int? CPUOptionalFanHeaderAmount { get; set; }

        /// <summary>
        /// Number of Addressable RGB headers (5V, 3-pin) in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Addressable RGB 5v Header Amount must be between 0 and 20")]
        public int? ARGB5vHeaderAmount { get; set; }

        /// <summary>
        /// Number of standard RGB headers (12V, 4-pin) in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "RGB 12v Header Amount must be between 0 and 20")]
        public int? RGB12vHeaderAmount { get; set; }

        /// <summary>
        /// Whether the Motherboard has a Power Button Header.
        /// </summary>
        public bool? HasPowerButtonHeader { get; set; }

        /// <summary>
        /// Whether the Motherboard has a Reset Button Header.
        /// </summary>
        public bool? HasResetButtonHeader { get; set; }

        /// <summary>
        /// Whether the Motherboard has a Power LED Header.
        /// </summary>
        public bool? HasPowerLEDHeader { get; set; }

        /// <summary>
        /// Whether the Motherboard has a Hard Drive Activity Light Header.
        /// </summary>
        public bool? HasHDDLEDHeader { get; set; }

        /// <summary>
        /// Number of temperature sensor Headers in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Temperature Sensor Header Amount must be between 0 and 20")]
        public int? TemperatureSensorHeaderAmount { get; set; }

        /// <summary>
        /// Number of Thunderbolt Headers in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Thunderbolt Header Amount must be between 0 and 20")]
        public int? ThunderboltHeaderAmount { get; set; }

        /// <summary>
        /// Number of COM port headers in the Motherboard.
        /// </summary>
        [Range(0, 20, ErrorMessage = "Com Port Header Amount must be between 0 and 20")]
        public int? COMPortHeaderAmount { get; set; }

        /// <summary>
        /// Main power connector specification (e.g., '24-pin').
        /// </summary>
        [StringLength(50, ErrorMessage = "Main Power Type cannot be longer than 50 characters!")]
        public string? MainPowerType { get; set; }

        /// <summary>
        /// Whether the motherboard supports Error Connection Code (ECC) memory.
        /// ECC detects and corrects errors in data transmission or storage, it does so by adding extra bits to the original data.
        /// <summary>
        public bool? HasECCSupport { get; set; }

        /// <summary>
        /// Whether the motherboard supports Redundant Array of Independent Disks (RAID) configurations.
        /// RAID stores the same data in different places on multiple drives.
        /// <summary>
        public bool? HasRAIDSupport { get; set; }

        /// <summary>
        /// Whether the board has BIOS backup capability in flashback.
        /// <summary>
        public bool? HasFlashback { get; set; }

        /// <summary>
        /// Whether the Motherboard has a Clear Complementary Metal-Oxide-Semiconductor (CMOS) button which resets the BIOS to default settings.
        /// <summary>
        public bool? HasCMOS { get; set; }

        /// <summary>
        /// Details of the Audio Chipset used.
        /// </summary>
        [StringLength(50, ErrorMessage = "Audio Chipset cannot be longer than 50 characters!")]
        public string? AudioChipset { get; set; }

        /// <summary>
        /// The Maximum number of Audio Channels in the Motherboard.
        /// </summary>
        [Range(1, 32, ErrorMessage = "Audio Channels must be between 1 and 32!")]
        public decimal? MaxAudioChannels { get; set; }
    }
}
