using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserCommentInteraction;

namespace KAZABUILD.Tests.ControllerServices;

public class UserCommentInteractionsControllerClient(HttpClient _client): BaseApiControllerService
{
    public async Task<HttpResponseMessage> AddUserCommentInteraction(CreateUserCommentInteractionDto dto)
    {
        return await _client.PostAsJsonAsync("/UserCommentInteractions/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateUserCommentInteraction(String userCommentInteractionId, UpdateUserCommentInteractionDto dto)
    {
        return await _client.PutAsJsonAsync("/UserCommentInteractions/" + userCommentInteractionId, dto);
    }

    public async Task<HttpResponseMessage> DeleteUserCommentInteraction(String userCommentInteractionId)
    {
        return await _client.DeleteAsync("/UserCommentInteractions/" + userCommentInteractionId);
    }

    public async Task<HttpResponseMessage> GetUserCommentInteractions(GetUserCommentInteractionDto dto)
    {
        return await _client.PostAsJsonAsync("/UserCommentInteractions/get", dto);
    }

    public async Task<HttpResponseMessage> GetUserCommentInteractionsCount(GetUserCommentInteractionDto dto)
    {
        return await _client.PostAsJsonAsync("/UserCommentInteractions/get-count", dto);
    }

    public async Task<HttpResponseMessage> GetUserCommentInteraction(String userCommentInteractionId)
    {
        return await _client.GetAsync("/UserCommentInteractions/" + userCommentInteractionId);
    }
}
