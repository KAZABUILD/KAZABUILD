using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserActivity;

namespace KAZABUILD.Tests.ControllerServices;

public class UserActivitiesControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddUserActivity(CreateUserActivityDto dto)
    {
        return await _client.PostAsJsonAsync("/UserActivities/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateUserActivity(string userActivityId, UpdateUserActivityDto dto)
    {
        return await _client.PutAsJsonAsync($"/UserActivities/{userActivityId}", dto);
    }

    public async Task<HttpResponseMessage> GetUserActivity(string userActivityId)
    {
        return await _client.GetAsync($"/UserActivities/{userActivityId}");
    }

    public async Task<HttpResponseMessage> GetUserActivities(GetUserActivityDto dto)
    {
        return await _client.PostAsJsonAsync("/UserActivities/get", dto);
    }

    public async Task<HttpResponseMessage> GetUserActivitiesCount(GetUserActivityDto dto)
    {
        return await _client.PostAsJsonAsync("/UserActivities/get-count", dto);
    }

    public async Task<HttpResponseMessage> DeleteUserActivity(string userActivityId)
    {
        return await _client.DeleteAsync($"/UserActivities/{userActivityId}");
    }
}
