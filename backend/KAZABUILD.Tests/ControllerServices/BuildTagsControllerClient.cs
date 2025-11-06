using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Builds.BuildTag;

namespace KAZABUILD.Tests.ControllerServices;

public class BuildTagsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddBuildTag(CreateBuildTagDto dto)
    {
        return await _client.PostAsJsonAsync("/BuildTags/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateBuildTag(String buildTagId, UpdateBuildTagDto dto)
    {
        return await _client.PutAsJsonAsync("/BuildTags/"+buildTagId, dto);
    }

    public async Task<HttpResponseMessage> DeleteBuildTag(String buildTagId)
    {
        return await _client.DeleteAsync("/BuildTags/"+buildTagId);
    }

    public async Task<HttpResponseMessage> GetBuildTags(GetBuildTagDto dto)
    {
        return await _client.PostAsJsonAsync("/BuildTags/get", dto);
    }

    public async Task<HttpResponseMessage> GetBuildTag(String buildTagId)
    {
        return await _client.GetAsync("/BuildTags/"+buildTagId);
    }
}
