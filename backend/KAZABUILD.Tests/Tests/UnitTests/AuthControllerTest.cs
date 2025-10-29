using System.Net;
using KAZABUILD.Application.DTOs.Auth;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

public class AuthControllerTests : BaseIntegrationTest
{
    private AuthControllerClient _api_client = null!;
    private HttpClient _client = null!;
    private User _user_verified = null!;
    private User _user_unverified = null!;
    private User _user_banned = null!;
    private const string DefaultPassword = "ValidPassword123!";

    public AuthControllerTests(KazaWebApplicationFactory factory) : base(factory) { }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        // Seed the database with a pool of 30 random users
        await _dataSeeder.SeedAsync<User, Guid>(30, password: DefaultPassword);

        // Query the seeded data to find users with specific roles required for tests
        _user_verified = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.USER);
        _user_unverified = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.UNVERIFIED);
        _user_banned = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.BANNED);

        // Ensure that the seeder created the necessary user types for the tests to run
        Assert.NotNull(_user_verified);
        Assert.NotNull(_user_unverified);
        Assert.NotNull(_user_banned);

        // Create an anonymous client. Redirects are disabled to test redirect responses.
        _client = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false
        });
        _api_client = new AuthControllerClient(_client, "127.0.0.1");
    }

    [Fact]
    public async Task Login_WithValidCredentials_ShouldReturnOk()
    {
        // Arrange
        var loginDto = new LoginDto { Email = _user_verified.Email, Password = DefaultPassword };

        // Act
        var response = await _api_client.Login(loginDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(response.Content);
    }

    [Fact]
    public async Task Login_WithInvalidPassword_ShouldReturnUnauthorized()
    {
        // Arrange
        var loginDto = new LoginDto { Email = _user_verified.Email, Password = "wrong-password" };

        // Act
        var response = await _api_client.Login(loginDto);

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Login_WithUnverifiedUser_ShouldReturnUnauthorized()
    {
        // Arrange
        var loginDto = new LoginDto { Email = _user_unverified.Email, Password = DefaultPassword };

        // Act
        var response = await _api_client.Login(loginDto);

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Login_WithBannedUser_ShouldReturnUnauthorized()
    {
        // Arrange
        var loginDto = new LoginDto { Email = _user_banned.Email, Password = DefaultPassword };

        // Act
        var response = await _api_client.Login(loginDto);

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Register_WithValidData_ShouldCreateUnverifiedUser()
    {
        // Arrange
        var registerDto = new RegisterDto
        {
            Email = "newuser@example.com",
            Login = "new_user_login",
            DisplayName = "NewUseraa",
            Password = DefaultPassword,
            RedirectUrl = "/test.com",
            Birth = DateTime.Today.Subtract(TimeSpan.FromDays(365*20)),
            RegisteredAt = DateTime.Now,
        };

        // Act
        var response = await _api_client.Register(registerDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var newUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == registerDto.Email);
        Assert.NotNull(newUser);
        Assert.Equal(UserRole.UNVERIFIED, newUser.UserRole);

        var token = await _context.UserTokens.FirstOrDefaultAsync(t => t.UserId == newUser.Id && t.TokenType == TokenType.CONFIRM_REGISTER);
        Assert.NotNull(token);
    }

    [Fact]
    public async Task Register_WithExistingEmail_ShouldReturnConflict()
    {
        // Arrange
        var registerDto = new RegisterDto
        {
            Email = _user_verified.Email,
            Login = "another_new_login",
            DisplayName = "Another User",
            Password = DefaultPassword,
            RedirectUrl = "/test.com",
            Birth = DateTime.Today.Subtract(TimeSpan.FromDays(365*20)),
            RegisteredAt = DateTime.Now,
        };

        // Act
        var response = await _api_client.Register(registerDto);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task ConfirmRegister_WithValidToken_ShouldVerifyUserAndRedirect()
    {
        // Arrange
        var token = new UserToken
        {
            UserId = _user_unverified.Id,
            Token = Guid.NewGuid().ToString("N"),
            TokenType = TokenType.CONFIRM_REGISTER,
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            RedirectUrl = "/welcome",
            IpAddress = "127.0.0.1"
        };
        await _context.UserTokens.AddAsync(token);
        await _context.SaveChangesAsync();
        var confirmDto = new ConfirmRegisterDto { Token = token.Token };

        // Act
        var response = await _api_client.ConfirmRegister(confirmDto);

        // Assert
        Assert.Equal(HttpStatusCode.Redirect, response.StatusCode);

        var verifiedUser = await _context.Users.FindAsync(_user_unverified.Id);
        Assert.NotNull(verifiedUser);
        Assert.Equal(UserRole.USER, verifiedUser.UserRole);

        var usedToken = await _context.UserTokens.FindAsync(token.Id);
        Assert.NotNull(usedToken?.UsedAt);
    }

    [Fact]
    public async Task ResetPassword_ForExistingUser_ShouldCreateToken()
    {
        // Arrange
        var resetDto = new ResetPasswordDto { Email = _user_verified.Email, RedirectUrl = "/new-password" };

        // Act
        var response = await _api_client.ResetPassword(resetDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var token = await _context.UserTokens.FirstOrDefaultAsync(t => t.UserId == _user_verified.Id && t.TokenType == TokenType.RESET_PASSWORD);
        Assert.NotNull(token);
    }

    [Fact]
    public async Task ConfirmResetPassword_WithValidToken_ShouldChangePassword()
    {
        // Arrange
        var originalHash = _user_verified.PasswordHash;
        var token = new UserToken
        {
            UserId = _user_verified.Id,
            Token = Guid.NewGuid().ToString("N"),
            TokenType = TokenType.RESET_PASSWORD,
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            RedirectUrl = "/login",
            IpAddress = "127.0.0.1"
        };
        await _context.UserTokens.AddAsync(token);
        await _context.SaveChangesAsync();

        var newPassword = "aDifferentStrongPassword123!";
        var confirmDto = new ConfirmPasswordResetDto { Token = token.Token, NewPassword = newPassword };

        // Act
        var response = await _api_client.ConfirmResetPassword(confirmDto);

        // Assert
        Assert.Equal(HttpStatusCode.Redirect, response.StatusCode);

        var updatedUser = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == _user_verified.Id);
        Assert.NotNull(updatedUser);
        Assert.NotEqual(originalHash, updatedUser.PasswordHash);
    }
}
