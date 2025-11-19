using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Builds.Build;

namespace KAZABUILD.Tests.ControllerServices;

public class BuildsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddBuild(CreateBuildDto dto)
    {
        return await _client.PostAsJsonAsync("/Builds/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateBuild(String buildId, UpdateBuildDto dto)
    {
        return await _client.PutAsJsonAsync("/Builds/"+buildId, dto);
    }

    public async Task<HttpResponseMessage> DeleteBuild(String buildId)
    {
        return await _client.DeleteAsync("/Builds/"+buildId);
    }

    public async Task<HttpResponseMessage> GetBuilds(GetBuildDto dto)
    {
        return await _client.PostAsJsonAsync("/Builds/get", dto);
    }

    public async Task<HttpResponseMessage> GetBuild(String buildId)
    {
        return await _client.GetAsync("/Builds/"+buildId);
    }
}
