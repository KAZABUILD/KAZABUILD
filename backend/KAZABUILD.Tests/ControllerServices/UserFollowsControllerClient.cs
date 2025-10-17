using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserFollow;

namespace KAZABUILD.Tests.ControllerServices;

public class UserFollowsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddUserFollow(CreateUserFollowDto dto)
    {
        return await _client.PostAsJsonAsync("/UserFollows/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateUserFollow(String userFollowId, UpdateUserFollowDto dto)
    {
        return await _client.PutAsJsonAsync("/UserFollows/"+userFollowId, dto);
    }

    public async Task<HttpResponseMessage> DeleteUserFollow(String userFollowId)
    {
        return await _client.DeleteAsync("/UserFollows/"+userFollowId);
    }

    public async Task<HttpResponseMessage> GetUserFollows(GetUserFollowDto dto)
    {
        return await _client.PostAsJsonAsync("/UserFollows/get", dto);
    }

    public async Task<HttpResponseMessage> GetUserFollow(String userFollowId)
    {
        return await _client.GetAsync("/UserFollows/"+userFollowId);
    }
}
