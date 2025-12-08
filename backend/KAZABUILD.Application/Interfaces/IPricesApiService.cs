using KAZABUILD.Application.DTOs.Components.ComponentPrice; // Add this namespace
using KAZABUILD.Domain.Entities.Components.Components;

namespace KAZABUILD.Application.Interfaces
{
    public interface IPricesApiService
    {
        Task<PricesApiPriceResponseDto?> GetPartPrice(BaseComponent component);
    }
}
