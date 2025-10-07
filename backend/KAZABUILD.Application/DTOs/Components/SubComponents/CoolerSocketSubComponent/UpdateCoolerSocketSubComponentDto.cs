using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.CoolerSocketSubComponent
{
    public class UpdateCoolerSocketSubComponentDto : UpdateBaseSubComponentDto
    {
        /// <summary>
        /// Socket Type supported by the cooler (e.g., AM5, LGA1700, TR4).
        /// </summary>
        [StringLength(50, ErrorMessage = "Socket type cannot be longer than 50 characters!")]
        public string? SocketType { get; set; }
    }
}
