using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Builds.BuildComponent;

namespace KAZABUILD.Tests.ControllerServices;

public class BuildComponentsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddBuildComponent(CreateBuildComponentDto dto)
    {
        return await _client.PostAsJsonAsync("/BuildComponents/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateBuildComponent(String buildComponentId, UpdateBuildComponentDto dto)
    {
        return await _client.PutAsJsonAsync("/BuildComponents/"+buildComponentId, dto);
    }

    public async Task<HttpResponseMessage> DeleteBuildComponent(String buildComponentId)
    {
        return await _client.DeleteAsync("/BuildComponents/"+buildComponentId);
    }

    public async Task<HttpResponseMessage> GetBuildComponents(GetBuildComponentDto dto)
    {
        return await _client.PostAsJsonAsync("/BuildComponents/get", dto);
    }

    public async Task<HttpResponseMessage> GetBuildComponent(String buildComponentId)
    {
        return await _client.GetAsync("/BuildComponents/"+buildComponentId);
    }
}
