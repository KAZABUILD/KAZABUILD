using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Users.UserCommentInteraction;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class UserCommentInteractionControllerTests : BaseIntegrationTest
{
    private UserCommentInteractionsControllerClient _api_user_client = null!;
    private UserCommentInteractionsControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private User another_user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public UserCommentInteractionControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
        _jsonSerializerOptions = new JsonSerializerOptions
        {
            Converters = { new JsonStringEnumConverter() },
            PropertyNameCaseInsensitive = true
        };
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        admin = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.ADMINISTRATOR);
        user = await _context.Users.FirstOrDefaultAsync(u => u.Id != admin.Id && u.UserRole == UserRole.USER);
        another_user =
            await _context.Users.FirstOrDefaultAsync(u =>
                u.Id != admin.Id && u.Id != user.Id && u.UserRole == UserRole.USER);

        // Creating user clients
        _client_user = await HttpClientFactory.Create(_factory, user);
        _client_admin = await HttpClientFactory.Create(_factory, admin);

        // Initialization of controller clients
        _api_admin_client = new UserCommentInteractionsControllerClient(_client_admin);
        _api_user_client = new UserCommentInteractionsControllerClient(_client_user);
    }

    [Fact]
    public async Task AddUserCommentInteraction_WithBothLikedAndDisliked_ShouldReturnBadRequest()
    {
        // Arrange - Get a public comment
        var publicComment = await _context.UserComments
            .Include(c => c.Build)
            .FirstOrDefaultAsync(c => c.Build != null && c.Build.Status == BuildStatus.PUBLISHED);

        if (publicComment == null)
        {
            Assert.True(false, "No public comment available for testing");
        }

        var createDto = new CreateUserCommentInteractionDto
        {
            UserId = user.Id,
            UserCommentId = publicComment.Id,
            IsLiked = true,
            IsDisliked = true // Both set to true - should fail
        };

        // Act
        var response = await _api_user_client.AddUserCommentInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserCommentInteraction_OnPrivateBuild_ShouldReturnBadRequest()
    {
        // Arrange - Get or create a private comment (build with DRAFT status)
        var privateComment = await _context.UserComments
            .Include(c => c.Build)
            .FirstOrDefaultAsync(c => c.Build != null && c.Build.Status == BuildStatus.DRAFT && c.UserId != user.Id);

        if (privateComment == null)
        {
            var privateBuild = new Build
            {
                Id = Guid.NewGuid(),
                UserId = another_user.Id,
                Name = "Private Build for Testing",
                Description = "Test description",
                Status = BuildStatus.DRAFT,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.Builds.Add(privateBuild);
            await _context.SaveChangesAsync();

            privateComment = new UserComment
            {
                Id = Guid.NewGuid(),
                UserId = another_user.Id,
                BuildId = privateBuild.Id,
                Content = "Test private comment",
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.UserComments.Add(privateComment);
            await _context.SaveChangesAsync();
        }

        var createDto = new CreateUserCommentInteractionDto
        {
            UserId = user.Id,
            UserCommentId = privateComment.Id,
            IsLiked = true,
            IsDisliked = false
        };

        // Act
        var response = await _api_user_client.AddUserCommentInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserCommentInteraction_WithNonExistentComment_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateUserCommentInteractionDto
        {
            UserId = user.Id,
            UserCommentId = Guid.NewGuid(),
            IsLiked = true,
            IsDisliked = false
        };

        // Act
        var response = await _api_user_client.AddUserCommentInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserCommentInteraction_AlreadyExists_ShouldReturnBadRequest()
    {
        // Arrange - Create an interaction first
        var publicComment = await _context.UserComments
            .Include(c => c.Build)
            .FirstOrDefaultAsync(c => c.Build != null && c.Build.Status == BuildStatus.PUBLISHED);

        if (publicComment == null)
        {
            Assert.True(false, "No public comment available for testing");
        }

        var createDto = new CreateUserCommentInteractionDto
        {
            UserId = user.Id,
            UserCommentId = publicComment.Id,
            IsLiked = true,
            IsDisliked = false
        };

        await _api_user_client.AddUserCommentInteraction(createDto);

        // Act - Try to create again
        var response = await _api_user_client.AddUserCommentInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserCommentInteraction_WithNoteByAdmin_ShouldSucceed()
    {
        // Arrange - Get or create an interaction
        var interaction = await _context.UserCommentInteractions
            .Include(i => i.UserComment)
            .ThenInclude(c => c.Build)
            .FirstOrDefaultAsync(i =>
                i.UserComment != null && i.UserComment.Build != null &&
                i.UserComment.Build.Status == BuildStatus.PUBLISHED);

        if (interaction == null)
        {
            var publicComment = await _context.UserComments
                .Include(c => c.Build)
                .FirstOrDefaultAsync(c => c.Build != null && c.Build.Status == BuildStatus.PUBLISHED);

            var createDto = new CreateUserCommentInteractionDto
            {
                UserId = user.Id,
                UserCommentId = publicComment.Id,
                IsLiked = true,
                IsDisliked = false
            };

            var createResponse = await _api_user_client.AddUserCommentInteraction(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData =
                JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var interactionId = createData["id"].GetGuid();
            interaction = await _context.UserCommentInteractions.FindAsync(interactionId);
        }

        var adminNote = "Admin note for this interaction";
        var updateDto = new UpdateUserCommentInteractionDto
        {
            Note = adminNote
        };

        // Act
        var updateResponse = await _api_admin_client.UpdateUserCommentInteraction(interaction.Id.ToString(), updateDto);

        // Assert
        var response = await _api_admin_client.GetUserCommentInteraction(interaction.Id.ToString());
        var data = JsonSerializer.Deserialize<UserCommentInteractionResponseDto>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        Assert.Equal(adminNote, data.Note);
    }

    [Fact]
    public async Task UpdateUserCommentInteraction_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateDto = new UpdateUserCommentInteractionDto
        {
            IsLiked = true
        };

        // Act
        var response = await _api_user_client.UpdateUserCommentInteraction(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetUserCommentInteraction_ForPublicInteraction_ShouldSucceedWithPublicAccess()
    {
        // Arrange - Create an interaction for another user
        var publicComment = await _context.UserComments
            .Include(c => c.Build)
            .FirstOrDefaultAsync(c => c.Build != null && c.Build.Status == BuildStatus.PUBLISHED);

        if (publicComment == null)
        {
            Assert.True(false, "No public comment available for testing");
        }

        var createDto = new CreateUserCommentInteractionDto
        {
            UserId = another_user.Id,
            UserCommentId = publicComment.Id,
            IsLiked = true,
            IsDisliked = false
        };

        var createResponse = await _api_admin_client.AddUserCommentInteraction(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var interactionId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.GetUserCommentInteraction(interactionId.ToString());
        var data = JsonSerializer.Deserialize<UserCommentInteractionResponseDto>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(data.UserId); // Public access shouldn't see UserId
        Assert.True(data.IsLiked);
    }

    [Fact]
    public async Task GetUserCommentInteraction_ByAdmin_ShouldSucceedWithAdminAccess()
    {
        // Arrange - Get any interaction
        var interaction = await _context.UserCommentInteractions
            .Include(i => i.UserComment)
            .ThenInclude(c => c.Build)
            .FirstOrDefaultAsync(i =>
                i.UserComment != null && i.UserComment.Build != null &&
                i.UserComment.Build.Status == BuildStatus.PUBLISHED);

        if (interaction == null)
        {
            Assert.True(false, "No interaction available for testing");
        }

        // Act
        var response = await _api_admin_client.GetUserCommentInteraction(interaction.Id.ToString());
        var data = JsonSerializer.Deserialize<UserCommentInteractionResponseDto>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data.UserId); // Admin should see UserId
        Assert.NotNull(data.DatabaseEntryAt); // Admin should see timestamps
        Assert.NotNull(data.LastEditedAt);
    }

    [Fact]
    public async Task GetUserCommentInteraction_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetUserCommentInteraction(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetUserCommentInteractions_ByUser_ShouldReturnAccessibleInteractions()
    {
        // Arrange
        var getDto = new GetUserCommentInteractionDto();

        // Act
        var response = await _api_user_client.GetUserCommentInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<UserCommentInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
    }

    [Fact]
    public async Task GetUserCommentInteractions_ByAdmin_ShouldReturnAllInteractions()
    {
        // Arrange
        var getDto = new GetUserCommentInteractionDto();

        // Act
        var response = await _api_admin_client.GetUserCommentInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<UserCommentInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
        Assert.All(data, interaction =>
        {
            Assert.NotNull(interaction.DatabaseEntryAt); // Admin should see all fields
            Assert.NotNull(interaction.UserId);
        });
    }

    [Fact]
    public async Task GetUserCommentInteractions_WithUserIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetUserCommentInteractionDto
        {
            UserId = new List<Guid> { user.Id }
        };

        // Act
        var response = await _api_admin_client.GetUserCommentInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<UserCommentInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, interaction => Assert.Equal(user.Id, interaction.UserId));
    }

    [Fact]
    public async Task GetUserCommentInteractions_WithIsLikedFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetUserCommentInteractionDto
        {
            IsLiked = true
        };

        // Act
        var response = await _api_admin_client.GetUserCommentInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<UserCommentInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, interaction => Assert.True(interaction.IsLiked));
    }

    [Fact]
    public async Task GetUserCommentInteractions_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetUserCommentInteractionDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetUserCommentInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<UserCommentInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }

    [Fact]
    public async Task GetUserCommentInteractionsCount_ShouldReturnCount()
    {
        // Arrange
        var getDto = new GetUserCommentInteractionDto
        {
            IsLiked = true
        };

        // Act
        var response = await _api_admin_client.GetUserCommentInteractionsCount(getDto);
        var content = await response.Content.ReadAsStringAsync();
        var count = JsonSerializer.Deserialize<int>(content, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(count >= 0);
    }

}
