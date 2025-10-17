namespace KAZABUILD.Tests.ControllerServices;

using System.Net.Http.Json;
using Application.DTOs.Users.ForumPost;

public class ForumPostsControllerClient
{
    private readonly HttpClient _client;

    public ForumPostsControllerClient(HttpClient client)
    {
        _client = client;
    }

    public async Task<HttpResponseMessage> AddForumPost(CreateForumPostDto dto)
    {
        return await _client.PostAsJsonAsync("/ForumPosts/add", dto);
    }

    public async Task<HttpResponseMessage> UpdateForumPost(String forumPostId, UpdateForumPostDto dto)
    {
        return await _client.PutAsJsonAsync("/ForumPosts/"+forumPostId, dto);
    }

    public async Task<HttpResponseMessage> GetForumPost(String forumPostId)
    {
        return await _client.GetAsync("/ForumPosts/"+forumPostId);
    }

    public async Task<HttpResponseMessage> DeleteForumPost(String forumPostId)
    {
        return await _client.DeleteAsync("/ForumPosts/"+forumPostId);
    }

    public async Task<HttpResponseMessage> GetPosts(GetForumPostDto dto)
    {
        return await _client.PostAsJsonAsync("/ForumPosts/get", dto);
    }
}
