using System.Diagnostics; 
using System.Diagnostics.Metrics; 
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

        // Metrics Definitions
        private static readonly Meter _meter = new("KazaBuild.PricesApi");
        private static readonly Histogram<double> _requestDuration = _meter.CreateHistogram<double>(
            "app_external_prices_request_duration_seconds", 
            unit: "s", 
            description: "Duration of external price API requests");
        
        private static readonly Counter<long> _requestErrors = _meter.CreateCounter<long>(
            "app_external_prices_errors_total", 
            description: "Count of failed external price API requests");

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
            var stopwatch = Stopwatch.StartNew();
            
            try
            {
                // Map domain type name to external API expected type (strip "Component" suffix)
                var typeName = component.GetType().Name;
                if (typeName.EndsWith("Component", StringComparison.OrdinalIgnoreCase))
                {
                    typeName = typeName[..^"Component".Length];
                }

                var requestDto = new PricesApiPriceDto
                {
                    Name = component.Name,
                    Type = typeName,
                    Currency = "PLN"
                };

                //Call the External API
                var response = await _httpClient.PostAsJsonAsync(_settings.PriceApiEndpoint, requestDto);

                // Stop timer and record metric
                stopwatch.Stop();
                _requestDuration.Record(stopwatch.Elapsed.TotalSeconds);

                if (!response.IsSuccessStatusCode)
                {
                    //Log the external API failure
                    _requestErrors.Add(1, new KeyValuePair<string, object?>("reason", "http_error"));
                    
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
                stopwatch.Stop();
                _requestDuration.Record(stopwatch.Elapsed.TotalSeconds);
                _requestErrors.Add(1, new KeyValuePair<string, object?>("reason", "exception"));
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
