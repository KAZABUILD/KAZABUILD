using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;

namespace KAZABUILD.Application.DTOs.Components.Components.MotherboardComponent
{
    public class MotherboardComponentResponseDto : BaseComponentResponseDto
    {
        public string? SocketType { get; set; }

        public string? FormFactor { get; set; }

        public string? ChipsetType { get; set; }

        public string? RAMType { get; set; }

        public int? RAMSlotsAmount { get; set; }

        public decimal? MaxRAMAmount { get; set; }

        public int? SATA6GBsAmount { get; set; }

        public int? SATA3GBsAmount { get; set; }

        public int? U2PortAmount { get; set; }

        public string? WirelessNetworkingStandard { get; set; }

        public int? CPUFanHeaderAmount { get; set; }

        public int? CaseFanHeaderAmount { get; set; }

        public int? PumpHeaderAmount { get; set; }

        public int? CPUOptionalFanHeaderAmount { get; set; }

        public int? ARGB5vHeaderAmount { get; set; }

        public int? RGB12vHeaderAmount { get; set; }

        public bool? HasPowerButtonHeader { get; set; }

        public bool? HasResetButtonHeader { get; set; }

        public bool? HasPowerLEDHeader { get; set; }

        public bool? HasHDDLEDHeader { get; set; }

        public int? TemperatureSensorHeaderAmount { get; set; }

        public int? ThunderboltHeaderAmount { get; set; }

        public int? COMPortHeaderAmount { get; set; }

        public string? MainPowerType { get; set; }

        public bool? HasECCSupport { get; set; }

        public bool? HasRAIDSupport { get; set; }

        public bool? HasFlashback { get; set; }

        public bool? HasCMOS { get; set; }

        public string? AudioChipset { get; set; }

        public decimal? MaxAudioChannels { get; set; }
    }
}
