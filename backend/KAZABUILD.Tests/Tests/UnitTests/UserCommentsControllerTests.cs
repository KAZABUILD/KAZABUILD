using System.Net;
using KAZABUILD.Application.DTOs.Users.UserComment;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class UserCommentsControllerTests : BaseIntegrationTest
{
    private HttpClient _client = null!;
    private UserCommentsControllerClient _api_client = null!;
    private User _user_regular = null!;
    private User _user_other = null!;
    private User _user_admin = null!;
    private Guid _existingBuildId;
    private Guid _existingComponentId;

    public UserCommentsControllerTests(KazaWebApplicationFactory factory) : base(factory) { }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        _user_regular = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.USER);
        _user_other = await _context.Users.Where(u => u.UserRole == UserRole.USER && u.Id != _user_regular.Id).FirstOrDefaultAsync();
        _user_admin = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.ADMINISTRATOR);

        Assert.NotNull(_user_regular);
        Assert.NotNull(_user_other);
        Assert.NotNull(_user_admin);

        // Load real entities from database
        var build = await _context.Builds.FirstOrDefaultAsync();
        Assert.NotNull(build);
        _existingBuildId = build.Id;

        var component = await _context.Components.FirstOrDefaultAsync();
        Assert.NotNull(component);
        _existingComponentId = component.Id;

        _client = await HttpClientFactory.Create(_factory, _user_admin);
        _api_client = new UserCommentsControllerClient(_client);
    }

    [Fact]
    public async Task AddUserComment_ShouldReturnOk_WhenValidData()
    {
        var dto = new CreateUserCommentDto
        {
            UserId = _user_regular.Id,
            Content = "Test Comment",
            PostedAt = DateTime.UtcNow,
            CommentTargetType = CommentTargetType.BUILD,
            TargetId = _existingBuildId
        };

        var response = await _api_client.AddUserComment(dto);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var createdComment = await _context.UserComments.FirstOrDefaultAsync(c => c.UserId == _user_regular.Id && c.Content == "Test Comment");
        Assert.NotNull(createdComment);
    }

    [Fact]
    public async Task AddUserComment_ShouldReturnBadRequest_WhenUserDoesNotExist()
    {
        var dto = new CreateUserCommentDto
        {
            UserId = Guid.NewGuid(),
            Content = "Test Comment",
            PostedAt = DateTime.UtcNow,
            CommentTargetType = CommentTargetType.BUILD,
            TargetId = _existingBuildId
        };

        var response = await _api_client.AddUserComment(dto);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserComment_ShouldReturnForbid_WhenUnauthorizedUserPostsForOthers()
    {
        var client = await HttpClientFactory.Create(_factory, _user_regular);
        var apiClient = new UserCommentsControllerClient(client);

        var dto = new CreateUserCommentDto
        {
            UserId = _user_other.Id,
            Content = "Unauthorized Comment",
            PostedAt = DateTime.UtcNow,
            CommentTargetType = CommentTargetType.BUILD,
            TargetId = _existingBuildId
        };

        var response = await apiClient.AddUserComment(dto);
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddUserComment_WithComponentTarget_ShouldReturnOk_WhenValidData()
    {
        var dto = new CreateUserCommentDto
        {
            UserId = _user_regular.Id,
            Content = "Comment on Component",
            PostedAt = DateTime.UtcNow,
            CommentTargetType = CommentTargetType.COMPONENT,
            TargetId = _existingComponentId
        };

        var response = await _api_client.AddUserComment(dto);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var createdComment = await _context.UserComments.FirstOrDefaultAsync(c => c.UserId == _user_regular.Id && c.Content == "Comment on Component");
        Assert.NotNull(createdComment);
    }

    [Fact]
    public async Task GetUserComment_ShouldReturnOk_WhenExists()
    {
        var comment = new UserComment
        {
            UserId = _user_regular.Id,
            Content = "Existing Comment",
            PostedAt = DateTime.UtcNow,
            CommentTargetType = CommentTargetType.BUILD,
            BuildId = _existingBuildId,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.UserComments.AddAsync(comment);
        await _context.SaveChangesAsync();

        var response = await _api_client.GetUserComment(comment.Id.ToString());
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetUserComment_ShouldReturnNotFound_WhenDoesNotExist()
    {
        var response = await _api_client.GetUserComment(Guid.NewGuid().ToString());
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserComment_ShouldReturnOk_WhenExists()
    {
        var comment = new UserComment
        {
            UserId = _user_regular.Id,
            Content = "To be deleted",
            PostedAt = DateTime.UtcNow,
            CommentTargetType = CommentTargetType.BUILD,
            BuildId = _existingBuildId,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.UserComments.AddAsync(comment);
        await _context.SaveChangesAsync();

        var response = await _api_client.DeleteUserComment(comment.Id.ToString());
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var deleted = await _api_client.GetUserComment(comment.Id.ToString());
        Assert.Equal(HttpStatusCode.NotFound, deleted.StatusCode);
    }
}
