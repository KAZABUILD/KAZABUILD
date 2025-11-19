using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserComment;

namespace KAZABUILD.Tests.ControllerServices;

public class UserCommentsControllerClient(HttpClient _client)
{
    public async Task<HttpResponseMessage> AddUserComment(CreateUserCommentDto dto)
    {
        return await _client.PostAsJsonAsync("/UserComments/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateUserComment(String notificationId, UpdateUserCommentDto dto)
    {
        return await _client.PutAsJsonAsync("/UserComments/"+notificationId, dto);
    }

    public async Task<HttpResponseMessage> DeleteUserComment(String notificationId)
    {
        return await _client.DeleteAsync("/UserComments/"+notificationId);
    }

    public async Task<HttpResponseMessage> GetUserComments(GetUserCommentDto dto)
    {
        return await _client.PostAsJsonAsync("/UserComments/get", dto);
    }

    public async Task<HttpResponseMessage> GetUserComment(String userCommentId)
    {
        return await _client.GetAsync("/UserComments/"+userCommentId);
    }
}
