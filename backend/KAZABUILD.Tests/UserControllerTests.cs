using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Auth;
using KAZABUILD.Application.DTOs.User;

namespace KAZABUILD.Tests;

using System.Net;
using Domain.Entities;
using Domain.Enums;
using Utils;

public class UserControllerTests : BaseIntegrationTest
{
    private HttpClient _client_user = null!;
    private readonly User admin;
    private readonly User user;

    public UserControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
        admin = UserFactory.GenerateUser(login: "temp_admin", role: UserRole.ADMINISTRATOR);
        user = UserFactory.GenerateUser(login: "temp_user", role: UserRole.USER);
    }

    public override async Task InitializeAsync()
    {
        //Setup from base class
        await base.InitializeAsync();
        //User seeding
        _context.Users.AddRange(admin, user);
        await _context.SaveChangesAsync();

        //Creating user client
        _client_user = await HttpClientFactory.Create(_factory, user);
    }

    [Fact]
    public async Task UserWithLowerRankShouldntDeleteUserWithHigherRank()
    {
        // Act
        var response = await _client_user.DeleteAsync($"/Users/{admin.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UserWithLowerRankShouldntUpdateUserWithHigherRank()
    {
        // Given
        UpdateUserDto updateDto = new() { Login = "newLoginWithCorrectLength" };

        // When
        var response = await _client_user.PutAsJsonAsync($"/Users/{admin.Id}", updateDto);

        // Then
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UserShouldBeAbleToRegister()
    {
        // Act
        var response = await _client_user.DeleteAsync($"/Users/{admin.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UserShould()
    {
        // Act
        var response = await _client_user.DeleteAsync($"/Users/{admin.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
