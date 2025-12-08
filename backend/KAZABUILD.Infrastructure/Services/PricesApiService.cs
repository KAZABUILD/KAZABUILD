using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.ComponentPrice;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Enums;
using Microsoft.Extensions.Options;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Service that sends API calls to external prices provider.
    /// </summary>
    public class PricesApiService : IPricesApiService
    {
        private readonly PricesApiSettings _settings;
        private readonly HttpClient _httpClient;
        private readonly ILoggerService _logger;

        public PricesApiService(IOptions<PricesApiSettings> settings, HttpClient httpClient, ILoggerService logger)
        {
            _settings = settings.Value;
            _httpClient = httpClient;
            _logger = logger;

            //Ensure the BaseAddress is set either here or in Program.cs
            if (_httpClient.BaseAddress == null && !string.IsNullOrEmpty(_settings.Url))
            {
                _httpClient.BaseAddress = new Uri(_settings.Url);
            }
        }

        /// <summary>
        /// Sends a request for component price
        /// </summary>
        /// <param name="component"></param>
        /// <returns></returns>
        public async Task<PricesApiPriceResponseDto?> GetPartPrice(BaseComponent component)
        {
            try
            {
                var requestDto = new PricesApiPriceDto
                {
                    Name = component.Name,
                    Type = component.GetType().Name,
                    Currency = "PLN"
                };

                //Call the External API
                var response = await _httpClient.PostAsJsonAsync(_settings.PriceApiEndpoint, requestDto);

                if (!response.IsSuccessStatusCode)
                {
                    //Log the external API failure
                    await _logger.LogAsync(
                        Guid.Empty,
                        "GET",
                        "ExternalPriceApi",
                        "",
                        component.Id,
                        PrivacyLevel.WARNING,
                        $"External API returned error: {response.StatusCode}" // Message
                    );

                    return null;
                }

                //Deserialize response
                return await response.Content.ReadFromJsonAsync<PricesApiPriceResponseDto>();
            }
            catch (Exception ex)
            {
                //Log the exception
                await _logger.LogAsync(
                    Guid.Empty,
                    "GET",
                    "ExternalPriceApi",
                    "",
                    component.Id,
                    PrivacyLevel.WARNING,
                    $"Exception while fetching external price: {ex.Message}"
                );

                return null;
            }
        }
    }
}
