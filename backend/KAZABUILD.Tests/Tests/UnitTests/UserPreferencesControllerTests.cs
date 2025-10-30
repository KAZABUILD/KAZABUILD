using System.Net;
using KAZABUILD.Application.DTOs.Users.UserPreference;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class UserPreferencesControllerTests : BaseIntegrationTest
{
    private HttpClient _client = null!;
    private UserPreferencesControllerClient _api_client = null!;
    private User _user_regular = null!;
    private User _user_other = null!;
    private User _user_admin = null!;
    private const string DefaultPassword = "ValidPassword123!";

    public UserPreferencesControllerTests(KazaWebApplicationFactory factory) : base(factory) { }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        _user_regular = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.USER);
        _user_admin = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.ADMINISTRATOR);
        _user_other = await _context.Users.Where(u => u.Id != _user_regular.Id && u.UserRole == UserRole.USER).FirstOrDefaultAsync();

        Assert.NotNull(_user_regular);
        Assert.NotNull(_user_other);

        _client = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false
        });
        _client = await HttpClientFactory.Create(_factory, _user_admin);

        _api_client = new UserPreferencesControllerClient(_client);
    }

    [Fact]
    public async Task AddUserPreference_ShouldReturnOk_WhenValidUserExists()
    {
        // Arrange
        var dto = new CreateUserPreferenceDto { UserId = _user_regular.Id };

        // Act
        var response = await _api_client.AddUserPreference(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var pref = await _context.UserPreferences.FirstOrDefaultAsync(p => p.UserId == _user_regular.Id);
        Assert.NotNull(pref);
    }

    [Fact]
    public async Task AddUserPreference_ShouldReturnBadRequest_WhenUserDoesNotExist()
    {
        // Arrange
        var fakeId = Guid.NewGuid();
        var dto = new CreateUserPreferenceDto { UserId = fakeId };

        // Act
        var response = await _api_client.AddUserPreference(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetUserPreference_ShouldReturnOk_WhenExists()
    {
        // Arrange
        var pref = new UserPreference
        {
            UserId = _user_regular.Id,
            Note = "My preference"
        };
        await _context.UserPreferences.AddAsync(pref);
        await _context.SaveChangesAsync();

        // Act
        var response = await _api_client.GetUserPreference(pref.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetUserPreference_ShouldReturnNotFound_WhenDoesNotExist()
    {
        // Act
        var response = await _api_client.GetUserPreference(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserPreference_ShouldReturnNotFound_WhenInvalidId()
    {
        // Arrange
        var dto = new UpdateUserPreferenceDto { Note = "irrelevant" };

        // Act
        var response = await _api_client.UpdateUserPreference(Guid.NewGuid().ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserPreference_ShouldReturnOk_WhenExists()
    {
        // Arrange
        var pref = new UserPreference { UserId = _user_regular.Id };
        await _context.UserPreferences.AddAsync(pref);
        await _context.SaveChangesAsync();

        // Act
        var response = await _api_client.DeleteUserPreference(pref.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.False(await _context.UserPreferences.AnyAsync(p => p.Id == pref.Id));
    }

    [Fact]
    public async Task DeleteUserPreference_ShouldReturnNotFound_WhenDoesNotExist()
    {
        // Act
        var response = await _api_client.DeleteUserPreference(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
