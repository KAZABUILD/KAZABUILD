// Ignore Spelling: ARGB RGB

using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class CreateMotherboardComponentDto : CreateBaseComponentDto
    {
        [Required]
        [StringLength(50, ErrorMessage = "Socket cannot be longer than 50 characters!")]
        public string SocketType { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public string FormFactor { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Chipset cannot be longer than 50 characters!")]
        public string ChipsetType { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "RAM type cannot be longer than 50 characters!")]
        public string RAMType { get; set; } = default!;

        [Required]
        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 0 and 15")]
        public string RAMSlotsAmount { get; set; } = default!;

        [Required]
        [Range(0, 1024, ErrorMessage = "Max RAM Amount must be between 0 and 1024")]
        public int MaxRAMAmount { get; set; } = default!;

        [Required]
        [Range(0, 20, ErrorMessage = "Serial AT Attachment 6GBs Amount must be between 0 and 20")]
        public int SerialATAttachment6GBsAmount { get; set; } = default!;

        [Required]
        [Range(0, 20, ErrorMessage = "Serial AT Attachment 3GBs Amount must be between 0 and 20")]
        public int SerialATAttachment3GBsAmount { get; set; } = default!;

        [Required]
        [Range(0, 20, ErrorMessage = "U2 Port Amount must be between 0 and 20")]
        public int U2PortAmount { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Wireless Networking Standard cannot be longer than 50 characters!")]
        public string WirelessNetworkingStandard { get; set; } = default!;

        [Range(0, 20, ErrorMessage = "CPU Fan Header Amount must be between 0 and 20")]
        public int? CpuFanHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Case Fan Header Amount must be between 0 and 20")]
        public int? CaseFanHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Pump Header Amount must be between 0 and 20")]
        public int? PumpHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "CPU Optional Fan Header Amount must be between 0 and 20")]
        public int? CPUOptionalFanHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Addressable RGB 5v Header Amount must be between 0 and 20")]
        public int? ARGB5vHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "RGB 12v Header Amount must be between 0 and 20")]
        public int? RGB12vHeaderAmount { get; set; }

        public bool? HasPowerButtonHeader { get; set; }

        public bool? HasResetButtonHeader { get; set; }

        public bool? HasPowerLEDHeader { get; set; }

        public bool? HasHDDLEDHeader { get; set; }

        [Range(0, 20, ErrorMessage = "Temperature Sensor Header Amount must be between 0 and 20")]
        public int? TemperatureSensorHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Thunderbolt Header Amount must be between 0 and 20")]
        public int? ThunderboltHeaderAmount { get; set; }

        [Range(0, 20, ErrorMessage = "Com Port Header Amount must be between 0 and 20")]
        public int? ComPortHeaderAmount { get; set; }

        [StringLength(50, ErrorMessage = "Main Power Type cannot be longer than 50 characters!")]
        public string? MainPowerType { get; set; }

        [Required]
        public bool HasECCSupport { get; set; } = default!;

        [Required]
        public bool HasRAIDSupport { get; set; } = default!;

        [Required]
        public bool HasFlashback { get; set; } = default!;

        [Required]
        public bool HasCMOS { get; set; } = default!;

        [Required]
        [StringLength(50, ErrorMessage = "Audio Chipset cannot be longer than 50 characters!")]
        public string AudioChipset { get; set; } = default!;

        [Range(1, 32, ErrorMessage = "Audio Channels must be between 0 and 20!")]
        public decimal MaxAudioChannels { get; set; } = default!;
    }
}
