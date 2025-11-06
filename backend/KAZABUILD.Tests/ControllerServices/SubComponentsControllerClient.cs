using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Components.SubComponentPart;
using KAZABUILD.Application.DTOs.Components.SubComponents;

namespace KAZABUILD.Tests.ControllerServices;

public class SubComponentsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddSubComponent(CreateSubComponentPartDto dto)
    {
        return await _client.PostAsJsonAsync("/SubComponents/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateSubComponent(String subComponentId, UpdateSubComponentPartDto dto)
    {
        return await _client.PutAsJsonAsync("/SubComponents/"+subComponentId, dto);
    }

    public async Task<HttpResponseMessage> DeleteSubComponent(String subComponentId)
    {
        return await _client.DeleteAsync("/SubComponents/"+subComponentId);
    }

    public async Task<HttpResponseMessage> GetSubComponents(GetSubComponentPartDto dto)
    {
        return await _client.PostAsJsonAsync("/SubComponents/get", dto);
    }

    public async Task<HttpResponseMessage> GetSubComponent(String subComponentId)
    {
        return await _client.GetAsync("/SubComponents/"+subComponentId);
    }
}
