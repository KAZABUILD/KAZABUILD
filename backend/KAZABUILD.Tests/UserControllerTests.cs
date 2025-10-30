using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Users.User;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.Utils;

namespace KAZABUILD.Tests;

public class UserControllerTests : BaseIntegrationTest
{
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private readonly User admin;
    private readonly User user;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public UserControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
        admin = UserFactory.GenerateUser(login: "temp_admin", role: UserRole.ADMINISTRATOR);
        user = UserFactory.GenerateUser(login: "temp_user", role: UserRole.USER);

        // Configure JsonSerializerOptions to handle enums as strings
        _jsonSerializerOptions = new JsonSerializerOptions
        {
            Converters = { new JsonStringEnumConverter() },
            PropertyNameCaseInsensitive = true
        };
    }

    public override async Task InitializeAsync()
    {
        // Setup from base class
        await base.InitializeAsync();

        // User seeding
        _context.Users.AddRange(admin, user);
        await _context.SaveChangesAsync();

        // Creating user clients
        _client_user = await HttpClientFactory.Create(_factory, user);
        _client_admin = await HttpClientFactory.Create(_factory, admin);
    }

    [Fact]
    public async Task DeleteUser_WithLowerRank_ShouldReturnForbidden()
    {
        // Act
        var response = await _client_user.DeleteAsync($"/Users/{admin.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUser_WithLowerRank_ShouldReturnForbidden()
    {
        // Arrange
        var updateDto = new UpdateUserDto { Login = "newLoginWithCorrectLength" };

        // Act
        var response = await _client_user.PutAsJsonAsync($"/Users/{admin.Id}", updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetUser_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _client_user.GetAsync($"/Users/{nonExistentId}");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetUser_ForSelf_ShouldReturnFullProfile()
    {
        // Act
        var response = await _client_user.GetAsync($"/Users/{user.Id}");

        // Assert
        response.EnsureSuccessStatusCode();
        var responseUser = await response.Content.ReadFromJsonAsync<UserResponseDto>(_jsonSerializerOptions);

        Assert.NotNull(responseUser);
        Assert.Equal(user.Login, responseUser.Login); // Login should be visible for self
        Assert.Equal(user.Email, responseUser.Email); // Email should be visible for self
    }

    [Fact]
    public async Task GetUser_ForOtherUser_ShouldReturnLimitedProfile()
    {
        // Act
        var response = await _client_user.GetAsync($"/Users/{admin.Id}");

        // Assert
        response.EnsureSuccessStatusCode();
        var responseUser = await response.Content.ReadFromJsonAsync<UserResponseDto>(_jsonSerializerOptions);

        Assert.NotNull(responseUser);
        Assert.Null(responseUser.Login);
        Assert.Null(responseUser.Email);
    }


    [Fact]
    public async Task UpdateUser_ForOwnProfile_ShouldSucceed()
    {
        // Arrange
        var newDisplayName = "Updated Name";
        var updateUserDto = new UpdateUserDto { DisplayName = newDisplayName };

        // Act
        var response = await _client_user.PutAsJsonAsync($"/Users/{user.Id}", updateUserDto);

        // Assert
        response.EnsureSuccessStatusCode();
        await _context.Entry(user).ReloadAsync();
        Assert.Equal(newDisplayName, user.DisplayName);
    }

    [Fact]
    public async Task DeleteUser_ByAdmin_ShouldSucceed()
    {
        // Arrange
        var userToDelete = UserFactory.GenerateUser(login: "to_delete", role: UserRole.USER);
        _context.Users.Add(userToDelete);
        await _context.SaveChangesAsync();

        // Act
        var response = await _client_admin.DeleteAsync($"/Users/{userToDelete.Id}");
        response.EnsureSuccessStatusCode();
        var deletedUser = await _context.Users.FindAsync(userToDelete.Id);
        var new_response = await _client_admin.GetAsync($"/Users/{userToDelete.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, new_response.StatusCode);
    }
}
