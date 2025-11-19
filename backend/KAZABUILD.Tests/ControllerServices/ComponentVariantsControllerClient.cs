using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.ComponentVariant;

namespace KAZABUILD.Tests.ControllerServices;

public class ComponentVariantsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddComponentVariant(CreateComponentVariantDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentVariants/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateComponentVariant(String componentVariantId, UpdateComponentVariantDto dto)
    {
        return await _client.PutAsJsonAsync("/ComponentVariants/"+componentVariantId, dto);
    }

    public async Task<HttpResponseMessage> DeleteComponentVariant(String componentVariantId)
    {
        return await _client.DeleteAsync("/ComponentVariants/"+componentVariantId);
    }

    public async Task<HttpResponseMessage> GetComponentVariants(GetComponentVariantDto dto)
    {
        return await _client.PostAsJsonAsync("/ComponentVariants/get", dto);
    }

    public async Task<HttpResponseMessage> GetComponentVariant(String componentVariantId)
    {
        return await _client.GetAsync("/ComponentVariants/"+componentVariantId);
    }
}
