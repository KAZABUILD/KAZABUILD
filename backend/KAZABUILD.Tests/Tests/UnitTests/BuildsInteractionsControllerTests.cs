using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Builds.Build;
using KAZABUILD.Application.DTOs.Builds.BuildInteraction;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests.Builds;

[Collection("Sequential")]
public class BuildInteractionControllerTests : BaseIntegrationTest
{
    private BuildInteractionsControllerClient _api_user_client = null!;
    private BuildInteractionsControllerClient _api_admin_client = null!;
    private BuildsControllerClient _api_builds_user_client = null!;
    private BuildsControllerClient _api_builds_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private User another_user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public BuildInteractionControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
        _api_admin_client = new BuildInteractionsControllerClient(_client_admin);
        _api_user_client = new BuildInteractionsControllerClient(_client_user);
        _api_builds_user_client = new BuildsControllerClient(_client_user);
        _api_builds_admin_client = new BuildsControllerClient(_client_admin);
    }

    private async Task<Build> CreatePublicBuild(Guid userId, string name = "Public Test Build")
    {
        var createDto = new CreateBuildDto
        {
            UserId = userId,
            Name = name,
            Description = "Public build description",
            Status = BuildStatus.PUBLISHED
        };
        var response = await _api_builds_admin_client.AddBuild(createDto);
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(content, _jsonSerializerOptions);
        var buildId = data["id"].GetGuid();
        return await _context.Builds.FindAsync(buildId);
    }

    private async Task<Build> CreatePrivateBuild(Guid userId, string name = "Private Test Build")
    {
        var createDto = new CreateBuildDto
        {
            UserId = userId,
            Name = name,
            Description = "Private build description",
            Status = BuildStatus.DRAFT
        };
        var response = await _api_builds_user_client.AddBuild(createDto);
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(content, _jsonSerializerOptions);
        var buildId = data["id"].GetGuid();
        return await _context.Builds.FindAsync(buildId);
    }

    [Fact]
    public async Task AddBuildInteraction_ForSelf_OnPublicBuild_ShouldSucceed()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85,
            UserNote = "Great build!"
        };

        // Act
        var response = await _api_user_client.AddBuildInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildInteraction_ForOtherUser_ShouldReturnForbidden()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = another_user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85
        };

        // Act
        var response = await _api_user_client.AddBuildInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildInteraction_OnOwnPrivateBuild_ShouldSucceed()
    {
        // Arrange
        var privateBuild = await CreatePrivateBuild(user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = privateBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 90
        };

        // Act
        var response = await _api_user_client.AddBuildInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildInteraction_WithNonExistentBuild_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = Guid.NewGuid(),
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85
        };

        // Act
        var response = await _api_user_client.AddBuildInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildInteraction_WithNonExistentUser_ShouldReturnBadRequest()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = Guid.NewGuid(),
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85
        };

        // Act
        var response = await _api_admin_client.AddBuildInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildInteraction_AlreadyExists_ShouldReturnBadRequest()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85
        };

        await _api_user_client.AddBuildInteraction(createDto);

        // Act - Try to create again
        var response = await _api_user_client.AddBuildInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildInteraction_WithInvalidRating_ShouldReturnBadRequest()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 150 // Invalid rating (max 100)
        };

        // Act
        var response = await _api_user_client.AddBuildInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildInteraction_WithLongUserNote_ShouldReturnBadRequest()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85,
            UserNote = new string('A', 256) // Exceeds 255 character limit
        };

        // Act
        var response = await _api_user_client.AddBuildInteraction(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuildInteraction_ForOwnInteraction_ShouldSucceed()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = publicBuild.Id,
            IsLiked = false,
            IsWishlisted = false,
            Rating = 50
        };

        var createResponse = await _api_user_client.AddBuildInteraction(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var interactionId = createData["id"].GetGuid();

        var updateDto = new UpdateBuildInteractionDto
        {
            IsLiked = true,
            IsWishlisted = true,
            Rating = 95,
            UserNote = "Updated: Excellent build!"
        };

        // Act
        var updateResponse = await _api_user_client.UpdateBuildInteraction(interactionId.ToString(), updateDto);

        // Assert
        var response = await _api_user_client.GetBuildInteraction(interactionId.ToString());
        var data = JsonSerializer.Deserialize<BuildInteractionResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        Assert.True(data.IsLiked);
        Assert.True(data.IsWishlisted);
        Assert.Equal(95, data.Rating);
        Assert.Equal("Updated: Excellent build!", data.UserNote);
    }

    [Fact]
    public async Task UpdateBuildInteraction_ForOtherUsersInteraction_ShouldReturnForbidden()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = another_user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85
        };

        var createResponse = await _api_admin_client.AddBuildInteraction(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var interactionId = createData["id"].GetGuid();

        var updateDto = new UpdateBuildInteractionDto
        {
            Rating = 50
        };

        // Act
        var response = await _api_user_client.UpdateBuildInteraction(interactionId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuildInteraction_WithNoteByAdmin_ShouldSucceed()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85
        };

        var createResponse = await _api_user_client.AddBuildInteraction(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var interactionId = createData["id"].GetGuid();

        var adminNote = "Admin reviewing this interaction";
        var updateDto = new UpdateBuildInteractionDto
        {
            Note = adminNote
        };

        // Act
        var updateResponse = await _api_admin_client.UpdateBuildInteraction(interactionId.ToString(), updateDto);

        // Assert
        var response = await _api_admin_client.GetBuildInteraction(interactionId.ToString());
        var data = JsonSerializer.Deserialize<BuildInteractionResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        Assert.Equal(adminNote, data.Note);
    }

    [Fact]
    public async Task UpdateBuildInteraction_OnPrivateBuildByOwner_ShouldSucceed()
    {
        // Arrange
        var privateBuild = await CreatePrivateBuild(user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = privateBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85
        };

        var createResponse = await _api_user_client.AddBuildInteraction(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var interactionId = createData["id"].GetGuid();

        var updateDto = new UpdateBuildInteractionDto
        {
            Rating = 95
        };

        // Act
        var response = await _api_user_client.UpdateBuildInteraction(interactionId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuildInteraction_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateDto = new UpdateBuildInteractionDto
        {
            Rating = 85
        };

        // Act
        var response = await _api_user_client.UpdateBuildInteraction(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetBuildInteraction_ForOwnInteraction_ShouldSucceedWithPrivateAccess()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = true,
            Rating = 85,
            UserNote = "My personal note"
        };

        var createResponse = await _api_user_client.AddBuildInteraction(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var interactionId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.GetBuildInteraction(interactionId.ToString());
        var data = JsonSerializer.Deserialize<BuildInteractionResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(user.Id, data.UserId); // Should see own UserId
        Assert.Equal("My personal note", data.UserNote); // Should see own UserNote
        Assert.Null(data.Note); // Users shouldn't see admin notes
        Assert.Null(data.DatabaseEntryAt); // Users shouldn't see timestamps
    }

    [Fact]
    public async Task GetBuildInteraction_ForPublicInteraction_ShouldSucceedWithPublicAccess()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = another_user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85,
            UserNote = "Private note"
        };

        var createResponse = await _api_admin_client.AddBuildInteraction(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var interactionId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.GetBuildInteraction(interactionId.ToString());
        var data = JsonSerializer.Deserialize<BuildInteractionResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(data.UserId); // Public access shouldn't see UserId
        Assert.Null(data.UserNote); // Public access shouldn't see UserNote
        Assert.True(data.IsLiked);
        Assert.Equal(85, data.Rating);
    }

    [Fact]
    public async Task GetBuildInteraction_ByAdmin_ShouldSucceedWithAdminAccess()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id);

        var createDto = new CreateBuildInteractionDto
        {
            UserId = user.Id,
            BuildId = publicBuild.Id,
            IsLiked = true,
            IsWishlisted = false,
            Rating = 85
        };

        var createResponse = await _api_user_client.AddBuildInteraction(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var interactionId = createData["id"].GetGuid();

        // Act
        var response = await _api_admin_client.GetBuildInteraction(interactionId.ToString());
        var data = JsonSerializer.Deserialize<BuildInteractionResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data.UserId); // Admin should see UserId
        Assert.NotNull(data.DatabaseEntryAt); // Admin should see timestamps
        Assert.NotNull(data.LastEditedAt);
    }


    [Fact]
    public async Task GetBuildInteraction_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetBuildInteraction(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetBuildInteractions_ByAdmin_ShouldReturnAllInteractions()
    {
        // Arrange
        var getDto = new GetBuildInteractionDto();

        // Act
        var response = await _api_admin_client.GetBuildInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<BuildInteractionResponseDto>>(
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
    public async Task GetBuildInteractions_WithUserIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetBuildInteractionDto
        {
            UserId = new List<Guid> { user.Id }
        };

        // Act
        var response = await _api_admin_client.GetBuildInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<BuildInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, interaction => Assert.Equal(user.Id, interaction.UserId));
    }

    [Fact]
    public async Task GetBuildInteractions_WithBuildIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var publicBuild = await CreatePublicBuild(another_user.Id, "Specific Build for Filter");

        var getDto = new GetBuildInteractionDto
        {
            BuildId = new List<Guid> { publicBuild.Id }
        };

        // Act
        var response = await _api_admin_client.GetBuildInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<BuildInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, interaction => Assert.Equal(publicBuild.Id, interaction.BuildId));
    }

    [Fact]
    public async Task GetBuildInteractions_WithIsLikedFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetBuildInteractionDto
        {
            IsLiked = true
        };

        // Act
        var response = await _api_admin_client.GetBuildInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<BuildInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, interaction => Assert.True(interaction.IsLiked));
    }

    [Fact]
    public async Task GetBuildInteractions_WithIsWishlistedFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetBuildInteractionDto
        {
            IsWishlisted = true
        };

        // Act
        var response = await _api_admin_client.GetBuildInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<BuildInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, interaction => Assert.True(interaction.IsWishlisted));
    }

    [Fact]
    public async Task GetBuildInteractions_WithRatingRangeFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetBuildInteractionDto
        {
            RatingStart = 80,
            RatingEnd = 100
        };

        // Act
        var response = await _api_admin_client.GetBuildInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<BuildInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, interaction =>
        {
            Assert.True(interaction.Rating >= 80);
            Assert.True(interaction.Rating <= 100);
        });
    }

    [Fact]
    public async Task GetBuildInteractions_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetBuildInteractionDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetBuildInteractions(getDto);
        var data = JsonSerializer.Deserialize<List<BuildInteractionResponseDto>>(
            response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }
}
