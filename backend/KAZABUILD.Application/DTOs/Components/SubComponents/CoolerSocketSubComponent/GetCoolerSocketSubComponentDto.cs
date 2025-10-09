using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;

namespace KAZABUILD.Application.DTOs.Components.SubComponents.CoolerSocketSubComponent
{
    public class GetCoolerSocketSubComponentDto : GetBaseSubComponentDto
    {
        public List<string>? SocketType { get; set; }
    }
}
