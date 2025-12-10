using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserBlock;

namespace KAZABUILD.Tests.ControllerServices;

public class UserBlocksControllerClient(HttpClient _client): BaseApiControllerService
{
    public async Task<HttpResponseMessage> AddUserBlock(CreateUserBlockDto dto)
    {
        return await _client.PostAsJsonAsync("/UserBlocks/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateUserBlock(string userBlockId, UpdateUserBlockDto dto)
    {
        return await _client.PutAsJsonAsync($"/UserBlocks/{userBlockId}", dto);
    }

    public async Task<HttpResponseMessage> GetUserBlock(string userBlockId)
    {
        return await _client.GetAsync($"/UserBlocks/{userBlockId}");
    }

    public async Task<HttpResponseMessage> GetUserBlocks(GetUserBlockDto dto)
    {
        return await _client.PostAsJsonAsync("/UserBlocks/get", dto);
    }

    public async Task<HttpResponseMessage> DeleteUserBlock(string userBlockId)
    {
        return await _client.DeleteAsync($"/UserBlocks/{userBlockId}");
    }
}
