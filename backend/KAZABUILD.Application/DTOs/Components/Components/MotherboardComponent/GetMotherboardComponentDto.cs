// Ignore Spelling: ARGB RGB

using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class GetMotherboardComponentDto : GetBaseComponentDto
    {
        [StringLength(50, ErrorMessage = "Socket cannot be longer than 50 characters!")]
        public List<string>? SocketType { get; set; }

        [StringLength(50, ErrorMessage = "Form Factor cannot be longer than 50 characters!")]
        public List<string>? FormFactor { get; set; }

        [StringLength(50, ErrorMessage = "Chipset cannot be longer than 50 characters!")]
        public List<string>? ChipsetType { get; set; }

        [StringLength(50, ErrorMessage = "RAM type cannot be longer than 50 characters!")]
        public List<string>? RAMType { get; set; }

        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 0 and 15")]
        public int? RAMSlotsAmountStart { get; set; }

        [Range(0, 15, ErrorMessage = "RAM Slots Amount must be between 0 and 15")]
        public int? RAMSlotsAmountEnd { get; set; }

        [Range(0, 1024, ErrorMessage = "Max RAM Amount must be between 0 and 1024")]
        public int? MaxRAMAmountStart { get; set; }

        [Range(0, 1024, ErrorMessage = "Max RAM Amount must be between 0 and 1024")]
        public int? MaxRAMAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Serial AT Attachment 6GBs Amount must be between 0 and 20")]
        public int? SerialATAttachment6GBsAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Serial AT Attachment 6GBs Amount must be between 0 and 20")]
        public int? SerialATAttachment6GBsAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Serial AT Attachment 3GBs Amount must be between 0 and 20")]
        public int? SerialATAttachment3GBsAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Serial AT Attachment 3GBs Amount must be between 0 and 20")]
        public int? SerialATAttachment3GBsAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "U2 Port Amount must be between 0 and 20")]
        public int? U2PortAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "U2 Port Amount must be between 0 and 20")]
        public int? U2PortAmountEnd { get; set; }

        [StringLength(50, ErrorMessage = "Wireless Networking Standard cannot be longer than 50 characters!")]
        public List<string>? WirelessNetworkingStandard { get; set; }

        [Range(0, 20, ErrorMessage = "CPU Fan Header Amount must be between 0 and 20")]
        public int? CPUFanHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "CPU Fan Header Amount must be between 0 and 20")]
        public int? CPUFanHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Case Fan Header Amount must be between 0 and 20")]
        public int? CaseFanHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Case Fan Header Amount must be between 0 and 20")]
        public int? CaseFanHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Pump Header Amount must be between 0 and 20")]
        public int? PumpHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Pump Header Amount must be between 0 and 20")]
        public int? PumpHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "CPU Optional Fan Header Amount must be between 0 and 20")]
        public int? CPUOptionalFanHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "CPU Optional Fan Header Amount must be between 0 and 20")]
        public int? CPUOptionalFanHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Addressable RGB 5v Header Amount must be between 0 and 20")]
        public int? ARGB5vHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Addressable RGB 5v Header Amount must be between 0 and 20")]
        public int? ARGB5vHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "RGB 12v Header Amount must be between 0 and 20")]
        public int? RGB12vHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "RGB 12v Header Amount must be between 0 and 20")]
        public int? RGB12vHeaderAmountEnd { get; set; }

        public bool? HasPowerButtonHeader { get; set; }

        public bool? HasResetButtonHeader { get; set; }

        public bool? HasPowerLEDHeader { get; set; }

        public bool? HasHDDLEDHeader { get; set; }

        [Range(0, 20, ErrorMessage = "Temperature Sensor Header Amount must be between 0 and 20")]
        public int? TemperatureSensorHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Temperature Sensor Header Amount must be between 0 and 20")]
        public int? TemperatureSensorHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Thunderbolt Header Amount must be between 0 and 20")]
        public int? ThunderboltHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Thunderbolt Header Amount must be between 0 and 20")]
        public int? ThunderboltHeaderAmountEnd { get; set; }

        [Range(0, 20, ErrorMessage = "Com Port Header Amount must be between 0 and 20")]
        public int? COMPortHeaderAmountStart { get; set; }

        [Range(0, 20, ErrorMessage = "Com Port Header Amount must be between 0 and 20")]
        public int? COMPortHeaderAmountEnd { get; set; }

        [StringLength(50, ErrorMessage = "Main Power Type cannot be longer than 50 characters!")]
        public List<string>? MainPowerType { get; set; }

        public bool? HasECCSupport { get; set; }

        public bool? HasRAIDSupport { get; set; }

        public bool? HasFlashback { get; set; }

        public bool? HasCMOS { get; set; }

        [StringLength(50, ErrorMessage = "Audio Chipset cannot be longer than 50 characters!")]
        public List<string>? AudioChipset { get; set; }

        [Range(1, 32, ErrorMessage = "Audio Channels must be between 1 and 32!")]
        public decimal? MaxAudioChannelsStart { get; set; }

        [Range(1, 32, ErrorMessage = "Audio Channels must be between 1 and 32!")]
        public decimal? MaxAudioChannelsEnd { get; set; }
    }
}
