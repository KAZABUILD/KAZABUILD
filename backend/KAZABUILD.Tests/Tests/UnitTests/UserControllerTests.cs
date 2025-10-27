using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Users.User;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

public class UserControllerTests : BaseIntegrationTest
{
    private UsersControllerClient _api_user_client = null!;
    private UsersControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private User user_to_remove = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public UserControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
        // Configure JsonSerializerOptions to handle enums as strings
        _jsonSerializerOptions = new JsonSerializerOptions
        {
            Converters = { new JsonStringEnumConverter() },
            PropertyNameCaseInsensitive = true
        };
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();
        await _dataSeeder.SeedAsync<User, Guid>(30, password: "password123!");

        admin = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.ADMINISTRATOR);
        user = await _context.Users.FirstOrDefaultAsync(u => u.Id != admin.Id && u.UserRole==UserRole.USER);
        user_to_remove = await _context.Users.FirstOrDefaultAsync(u => u.Id != admin.Id && u.Id != user.Id && u.UserRole == UserRole.USER);

        // Creating user clients - this logic remains the same
        _client_user = await HttpClientFactory.Create(_factory, user);
        _client_admin = await HttpClientFactory.Create(_factory, admin);

        // Initialization of controller clients - this logic remains the same
        _api_admin_client = new UsersControllerClient(_client_admin);
        _api_user_client = new UsersControllerClient(_client_user);
    }

    [Fact]
    public async Task RemoveUser_ByAdmin_ShouldBeAccepted()
    {
        // Act
        await _api_admin_client.DeleteUser(user_to_remove.Id.ToString());
        var response = await _api_admin_client.GetUser(user_to_remove.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUser_WithHigherRank_ShouldReturnForbidden()
    {
        // Arrange
        var updateDto = new UpdateUserDto { Login = "newLoginWithCorrectLength" };

        // Act
        var response = await _api_user_client.UpdateUser(admin.Id.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetUser_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetUser(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUser_ForOwnProfile_ShouldSucceed()
    {
        // Arrange
        var newDisplayName = "Updated Name";
        var updateUserDto = new UpdateUserDto { DisplayName = newDisplayName };

        // Act
        await _api_user_client.UpdateUser(user.Id.ToString(), updateUserDto);

        // Assert
        var response = await _api_admin_client.GetUser(user.Id.ToString());
        var data = JsonSerializer.Deserialize<User>(response.Content.ReadAsStringAsync().Result);

        Assert.Equal(newDisplayName, data.DisplayName);
    }

    [Fact]
    public async Task DeleteUser_ByAdmin_ShouldSucceed()
    {
        // Act
        var response = await _api_admin_client.DeleteUser(user_to_remove.Id.ToString());
        var deletedUser = await _context.Users.FindAsync(user_to_remove.Id);
        var new_response = await _api_admin_client.GetUser(user_to_remove.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, new_response.StatusCode);
    }
}
