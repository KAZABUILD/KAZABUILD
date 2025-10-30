using System.Net;
using KAZABUILD.Application.DTOs.Users.UserFollow;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class UserFollowsControllerTests : BaseIntegrationTest
{
    private HttpClient _client = null!;
    private UserFollowsControllerClient _api_client = null!;
    private User _user_regular = null!;
    private User _user_other = null!;
    private User _user_admin = null!;

    public UserFollowsControllerTests(KazaWebApplicationFactory factory) : base(factory) { }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        _user_regular = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.USER);
        _user_other = await _context.Users.Where(u => u.UserRole == UserRole.USER && u.Id != _user_regular.Id).FirstOrDefaultAsync();
        _user_admin = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.ADMINISTRATOR);

        Assert.NotNull(_user_regular);
        Assert.NotNull(_user_other);
        Assert.NotNull(_user_admin);

        _client = await HttpClientFactory.Create(_factory, _user_admin);
        _api_client = new UserFollowsControllerClient(_client);
    }

    [Fact]
    public async Task AddUserFollow_ShouldReturnOk_WhenValidData()
    {
        // Arrange
        var dto = new CreateUserFollowDto
        {
            FollowerId = _user_regular.Id,
            FollowedId = _user_other.Id,
            FollowedAt = DateTime.UtcNow
        };

        // Act
        var response = await _api_client.AddUserFollow(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var createdFollow = await _context.UserFollows.FirstOrDefaultAsync(f =>
            f.FollowerId == _user_regular.Id && f.FollowedId == _user_other.Id);
        Assert.NotNull(createdFollow);
    }

    [Fact]
    public async Task AddUserFollow_ShouldReturnBadRequest_WhenUserDoesNotExist()
    {
        // Arrange
        var dto = new CreateUserFollowDto
        {
            FollowerId = Guid.NewGuid(),
            FollowedId = Guid.NewGuid(),
            FollowedAt = DateTime.UtcNow
        };

        // Act
        var response = await _api_client.AddUserFollow(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserFollow_ShouldReturnConflict_WhenAlreadyFollowed()
    {
        // Arrange
        var existingFollow = new UserFollow
        {
            FollowerId = _user_regular.Id,
            FollowedId = _user_other.Id,
            FollowedAt = DateTime.UtcNow
        };
        await _context.UserFollows.AddAsync(existingFollow);
        await _context.SaveChangesAsync();

        var dto = new CreateUserFollowDto
        {
            FollowerId = _user_regular.Id,
            FollowedId = _user_other.Id,
            FollowedAt = DateTime.UtcNow
        };

        // Act
        var response = await _api_client.AddUserFollow(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task AddUserFollow_ShouldReturnForbid_WhenUnauthorizedUserCreatesForOthers()
    {
        var client = await HttpClientFactory.Create(_factory, _user_regular);
        var userClient = new UserFollowsControllerClient(client);

        var dto = new CreateUserFollowDto
        {
            FollowerId = _user_other.Id,
            FollowedId = _user_regular.Id,
            FollowedAt = DateTime.UtcNow
        };

        // Act
        var response = await userClient.AddUserFollow(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetUserFollow_ShouldReturnOk_WhenExists()
    {
        // Arrange
        var follow = new UserFollow
        {
            FollowerId = _user_regular.Id,
            FollowedId = _user_other.Id,
            FollowedAt = DateTime.UtcNow
        };
        await _context.UserFollows.AddAsync(follow);
        await _context.SaveChangesAsync();

        // Act
        var response = await _api_client.GetUserFollow(follow.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetUserFollow_ShouldReturnNotFound_WhenDoesNotExist()
    {
        // Act
        var response = await _api_client.GetUserFollow(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserFollow_ShouldReturnNotFound_WhenInvalidId()
    {
        var dto = new UpdateUserFollowDto { Note = "Nonexistent follow" };
        var response = await _api_client.UpdateUserFollow(Guid.NewGuid().ToString(), dto);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserFollow_ShouldReturnOk_WhenExists()
    {
        // Arrange
        var follow = new UserFollow
        {
            FollowerId = _user_regular.Id,
            FollowedId = _user_other.Id,
            FollowedAt = DateTime.UtcNow
        };
        await _context.UserFollows.AddAsync(follow);
        await _context.SaveChangesAsync();

        // Act
        var response = await _api_client.DeleteUserFollow(follow.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.False(await _context.UserFollows.AnyAsync(f => f.Id == follow.Id));
    }

    [Fact]
    public async Task DeleteUserFollow_ShouldReturnNotFound_WhenDoesNotExist()
    {
        var response = await _api_client.DeleteUserFollow(Guid.NewGuid().ToString());
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetUserFollows_ShouldReturnOk_WithValidRequest()
    {
        // Arrange
        var follow1 = new UserFollow
        {
            FollowerId = _user_regular.Id,
            FollowedId = _user_other.Id,
            FollowedAt = DateTime.UtcNow
        };
        var follow2 = new UserFollow
        {
            FollowerId = _user_regular.Id,
            FollowedId = _user_admin.Id,
            FollowedAt = DateTime.UtcNow
        };
        await _context.UserFollows.AddRangeAsync(follow1, follow2);
        await _context.SaveChangesAsync();

        var dto = new GetUserFollowDto
        {
            FollowerId = new List<Guid> { _user_regular.Id }
        };

        // Act
        var response = await _api_client.GetUserFollows(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
