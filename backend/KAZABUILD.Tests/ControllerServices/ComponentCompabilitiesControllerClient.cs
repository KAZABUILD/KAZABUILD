using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.ComponentCompatibility;

namespace KAZABUILD.Tests.ControllerServices;

public class ComponentCompabilitiesControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddComponentCompability(CreateComponentCompatibilityDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentCompabilities/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateComponentCompability(String componentCompabilityId, UpdateComponentCompatibilityDto dto)
    {
        return await _client.PutAsJsonAsync("/ComponentCompabilities/"+componentCompabilityId, dto);
    }

    public async Task<HttpResponseMessage> DeleteComponentCompability(String componentCompabilityId)
    {
        return await _client.DeleteAsync("/ComponentCompabilities/"+componentCompabilityId);
    }

    public async Task<HttpResponseMessage> GetComponentCompabilities(GetComponentCompatibilityDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentCompabilities/get", dto);
    }

    public async Task<HttpResponseMessage> GetComponentCompability(String componentCompabilityId)
    {
        return await _client.GetAsync("/ComponentCompabilities/"+componentCompabilityId);
    }
}
