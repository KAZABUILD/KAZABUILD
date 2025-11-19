using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Builds.Build;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests.Builds;

[Collection("Sequential")]
public class BuildControllerTests : BaseIntegrationTest
{
    private BuildsControllerClient _api_user_client = null!;
    private BuildsControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private User another_user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public BuildControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
        _api_admin_client = new BuildsControllerClient(_client_admin);
        _api_user_client = new BuildsControllerClient(_client_user);
    }

    [Fact]
    public async Task AddBuild_ForSelf_ShouldSucceedWithDraftStatus()
    {
        // Arrange
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Test Build",
            Description = "Test build description",
            Status = BuildStatus.DRAFT
        };

        // Act
        var response = await _api_user_client.AddBuild(createDto);
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(content, _jsonSerializerOptions);
        var buildId = data["id"].GetGuid();

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var build = await _context.Builds.FindAsync(buildId);
        Assert.NotNull(build);
        Assert.Equal(BuildStatus.DRAFT, build.Status);
    }

    [Fact]
    public async Task AddBuild_ForSelfWithPublishedStatus_ShouldCreateAsDraft()
    {
        // Arrange - Users can't create published builds directly
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Test Published Build",
            Description = "Test build description",
            Status = BuildStatus.PUBLISHED
        };

        // Act
        var response = await _api_user_client.AddBuild(createDto);
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(content, _jsonSerializerOptions);
        var buildId = data["id"].GetGuid();

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var build = await _context.Builds.FindAsync(buildId);
        Assert.NotNull(build);
        Assert.Equal(BuildStatus.DRAFT, build.Status); // Should be overridden to DRAFT
    }

    [Fact]
    public async Task AddBuild_ForOtherUser_ShouldReturnForbidden()
    {
        // Arrange
        var createDto = new CreateBuildDto
        {
            UserId = another_user.Id,
            Name = "Test Build",
            Description = "Test build description",
            Status = BuildStatus.DRAFT
        };

        // Act
        var response = await _api_user_client.AddBuild(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddBuild_ByAdminWithPublishedStatus_ShouldSucceed()
    {
        // Arrange
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Admin Published Build",
            Description = "Test build description",
            Status = BuildStatus.PUBLISHED,
            PublishedAt = DateTime.UtcNow
        };

        // Act
        var response = await _api_admin_client.AddBuild(createDto);
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(content, _jsonSerializerOptions);
        var buildId = data["id"].GetGuid();

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var build = await _context.Builds.FindAsync(buildId);
        Assert.NotNull(build);
        Assert.Equal(BuildStatus.PUBLISHED, build.Status);
        Assert.NotNull(build.PublishedAt);
    }

    [Fact]
    public async Task AddBuild_WithShortName_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Ab", // Too short (minimum 3 characters)
            Description = "Test build description",
            Status = BuildStatus.DRAFT
        };

        // Act
        var response = await _api_user_client.AddBuild(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuild_WithLongName_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = new string('A', 51), // Exceeds 50 character limit
            Description = "Test build description",
            Status = BuildStatus.DRAFT
        };

        // Act
        var response = await _api_user_client.AddBuild(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuild_WithNonExistentUser_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateBuildDto
        {
            UserId = Guid.NewGuid(),
            Name = "Test Build",
            Description = "Test build description",
            Status = BuildStatus.DRAFT
        };

        // Act
        var response = await _api_admin_client.AddBuild(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuild_ForOwnBuild_ShouldSucceed()
    {
        // Arrange - Create a build first
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Original Build",
            Description = "Original description",
            Status = BuildStatus.DRAFT
        };
        var createResponse = await _api_user_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        var newName = "Updated Build Name";
        var updateDto = new UpdateBuildDto
        {
            Name = newName,
            Description = "Updated description"
        };

        // Act
        var updateResponse = await _api_user_client.UpdateBuild(buildId.ToString(), updateDto);

        // Assert
        var response = await _api_user_client.GetBuild(buildId.ToString());
        var data = JsonSerializer.Deserialize<BuildResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        Assert.Equal(newName, data.Name);
    }

    [Fact]
    public async Task UpdateBuild_ForOtherUsersBuild_ShouldReturnForbidden()
    {
        // Arrange - Create a build for another user
        var createDto = new CreateBuildDto
        {
            UserId = another_user.Id,
            Name = "Another User Build",
            Description = "Description",
            Status = BuildStatus.DRAFT
        };
        var createResponse = await _api_admin_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        var updateDto = new UpdateBuildDto
        {
            Name = "Trying to update"
        };

        // Act
        var response = await _api_user_client.UpdateBuild(buildId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuild_PublishingDraftBuild_ShouldSucceed()
    {
        // Arrange - Create a draft build
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Draft Build",
            Description = "Draft description",
            Status = BuildStatus.DRAFT
        };
        var createResponse = await _api_user_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        var updateDto = new UpdateBuildDto
        {
            Status = BuildStatus.PUBLISHED
        };

        // Act
        var updateResponse = await _api_user_client.UpdateBuild(buildId.ToString(), updateDto);

        // Assert
        var response = await _api_user_client.GetBuild(buildId.ToString());
        var data = JsonSerializer.Deserialize<BuildResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        Assert.Equal(BuildStatus.PUBLISHED, data.Status);
        Assert.NotNull(data.PublishedAt);
    }

    [Fact]
    public async Task UpdateBuild_GeneratedBuildByUser_ShouldReturnBadRequest()
    {
        // Arrange - Create a generated build (admin only)
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Generated Build",
            Description = "Generated description",
            Status = BuildStatus.GENERATED
        };
        var createResponse = await _api_admin_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        var updateDto = new UpdateBuildDto
        {
            Name = "Trying to update generated build"
        };

        // Act
        var response = await _api_user_client.UpdateBuild(buildId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuild_GeneratedBuildByAdmin_ShouldSucceed()
    {
        // Arrange - Create a generated build
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Generated Build",
            Description = "Generated description",
            Status = BuildStatus.GENERATED
        };
        var createResponse = await _api_admin_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        var updateDto = new UpdateBuildDto
        {
            Name = "Admin updating generated build"
        };

        // Act
        var response = await _api_admin_client.UpdateBuild(buildId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuild_WithNoteByAdmin_ShouldSucceed()
    {
        // Arrange - Get or create a build
        var build = await _context.Builds.FirstOrDefaultAsync(b => b.UserId == user.Id);
        if (build == null)
        {
            var createDto = new CreateBuildDto
            {
                UserId = user.Id,
                Name = "Test Build",
                Description = "Test description",
                Status = BuildStatus.DRAFT
            };
            var createResponse = await _api_user_client.AddBuild(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData =
                JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var buildId = createData["id"].GetGuid();
            build = await _context.Builds.FindAsync(buildId);
        }

        var adminNote = "Admin note for this build";
        var updateDto = new UpdateBuildDto
        {
            Note = adminNote
        };

        // Act
        var updateResponse = await _api_admin_client.UpdateBuild(build.Id.ToString(), updateDto);

        // Assert
        var response = await _api_admin_client.GetBuild(build.Id.ToString());
        var data = JsonSerializer.Deserialize<BuildResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        Assert.Equal(adminNote, data.Note);
    }

    [Fact]
    public async Task UpdateBuild_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateDto = new UpdateBuildDto
        {
            Name = "Test Update"
        };

        // Act
        var response = await _api_user_client.UpdateBuild(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetBuild_ForOwnDraftBuild_ShouldSucceed()
    {
        // Arrange - Create a draft build
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Draft Build",
            Description = "Draft description",
            Status = BuildStatus.DRAFT
        };
        var createResponse = await _api_user_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.GetBuild(buildId.ToString());
        var data = JsonSerializer.Deserialize<BuildResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(user.Id, data.UserId);
        Assert.Null(data.Note); // Users shouldn't see admin notes
        Assert.Null(data.DatabaseEntryAt); // Users shouldn't see timestamps
    }

    [Fact]
    public async Task GetBuild_ForOtherUsersDraftBuild_ShouldReturnForbidden()
    {
        // Arrange - Create a draft build for another user
        var createDto = new CreateBuildDto
        {
            UserId = another_user.Id,
            Name = "Another Draft Build",
            Description = "Description",
            Status = BuildStatus.DRAFT
        };
        var createResponse = await _api_admin_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.GetBuild(buildId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetBuild_ForPublicBuild_ShouldSucceed()
    {
        // Arrange - Get or create a published build
        var publicBuild = await _context.Builds.FirstOrDefaultAsync(b => b.Status == BuildStatus.PUBLISHED);
        if (publicBuild == null)
        {
            var createDto = new CreateBuildDto
            {
                UserId = another_user.Id,
                Name = "Public Build",
                Description = "Public description",
                Status = BuildStatus.PUBLISHED
            };
            var createResponse = await _api_admin_client.AddBuild(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData =
                JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var buildId = createData["id"].GetGuid();
            publicBuild = await _context.Builds.FindAsync(buildId);
        }

        // Act
        var response = await _api_user_client.GetBuild(publicBuild.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetBuild_ByAdmin_ShouldSucceedWithAdminAccess()
    {
        // Arrange - Get any build
        var build = await _context.Builds.FirstOrDefaultAsync();
        if (build == null)
        {
            var createDto = new CreateBuildDto
            {
                UserId = user.Id,
                Name = "Test Build",
                Description = "Test description",
                Status = BuildStatus.DRAFT
            };
            var createResponse = await _api_admin_client.AddBuild(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData =
                JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var buildId = createData["id"].GetGuid();
            build = await _context.Builds.FindAsync(buildId);
        }

        // Act
        var response = await _api_admin_client.GetBuild(build.Id.ToString());
        var data = JsonSerializer.Deserialize<BuildResponseDto>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data.DatabaseEntryAt); // Admin should see timestamps
        Assert.NotNull(data.LastEditedAt);
    }

    [Fact]
    public async Task GetBuild_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetBuild(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetBuilds_ByAdmin_ShouldReturnAllBuilds()
    {
        // Arrange
        var getDto = new GetBuildDto();

        // Act
        var response = await _api_admin_client.GetBuilds(getDto);
        var data = JsonSerializer.Deserialize<List<BuildResponseDto>>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
        Assert.All(data, build =>
        {
            Assert.NotNull(build.DatabaseEntryAt); // Admin should see all fields
        });
    }

    [Fact]
    public async Task GetBuilds_WithUserIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetBuildDto
        {
            UserId = new List<Guid> { user.Id }
        };

        // Act
        var response = await _api_admin_client.GetBuilds(getDto);
        var data = JsonSerializer.Deserialize<List<BuildResponseDto>>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, build => Assert.Equal(user.Id, build.UserId));
    }

    [Fact]
    public async Task GetBuilds_WithStatusFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetBuildDto
        {
            Status = new List<BuildStatus> { BuildStatus.PUBLISHED }
        };

        // Act
        var response = await _api_admin_client.GetBuilds(getDto);
        var data = JsonSerializer.Deserialize<List<BuildResponseDto>>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, build => Assert.Equal(BuildStatus.PUBLISHED, build.Status));
    }

    [Fact]
    public async Task GetBuilds_WithNameFilter_ShouldReturnFilteredResults()
    {
        // Arrange - Create a build with specific name
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "UniqueTestName123",
            Description = "Test description",
            Status = BuildStatus.DRAFT
        };
        await _api_user_client.AddBuild(createDto);

        var getDto = new GetBuildDto
        {
            Name = new List<string> { "UniqueTestName123" }
        };

        // Act
        var response = await _api_user_client.GetBuilds(getDto);
        var data = JsonSerializer.Deserialize<List<BuildResponseDto>>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, build => Assert.Equal("UniqueTestName123", build.Name));
    }

    [Fact]
    public async Task GetBuilds_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetBuildDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetBuilds(getDto);
        var data = JsonSerializer.Deserialize<List<BuildResponseDto>>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }

    [Fact]
    public async Task GetBuilds_WithOrderBy_ShouldReturnOrderedResults()
    {
        // Arrange
        var getDto = new GetBuildDto
        {
            OrderBy = "Name",
            SortDirection = "asc"
        };

        // Act
        var response = await _api_admin_client.GetBuilds(getDto);
        var data = JsonSerializer.Deserialize<List<BuildResponseDto>>(response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        if (data.Count > 1)
        {
            var orderedData = data.OrderBy(b => b.Name).ToList();
            Assert.Equal(orderedData.Select(b => b.Name), data.Select(b => b.Name));
        }
    }

    [Fact]
    public async Task GetBuilds_WithQuery_ShouldReturnMatchingResults()
    {
        // Arrange
        var getDto = new GetBuildDto
        {
            Query = "build"
        };

        // Act
        var response = await _api_admin_client.GetBuilds(getDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task DeleteBuild_ForOwnBuild_ShouldSucceed()
    {
        // Arrange - Create a build first
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Build to Delete",
            Description = "Description",
            Status = BuildStatus.DRAFT
        };
        var createResponse = await _api_user_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.DeleteBuild(buildId.ToString());
        var deletedBuild = await _context.Builds.FindAsync(buildId);
        var new_response = await _api_user_client.GetBuild(buildId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(deletedBuild);
        Assert.Equal(HttpStatusCode.NotFound, new_response.StatusCode);
    }

    [Fact]
    public async Task DeleteBuild_ForOtherUsersBuild_ShouldReturnForbidden()
    {
        // Arrange - Create a build for another user
        var createDto = new CreateBuildDto
        {
            UserId = another_user.Id,
            Name = "Another User's Build",
            Description = "Description",
            Status = BuildStatus.DRAFT
        };
        var createResponse = await _api_admin_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.DeleteBuild(buildId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteBuild_ByAdmin_ShouldSucceed()
    {
        // Arrange - Create a build
        var createDto = new CreateBuildDto
        {
            UserId = user.Id,
            Name = "Build for Admin to Delete",
            Description = "Description",
            Status = BuildStatus.DRAFT
        };
        var createResponse = await _api_admin_client.AddBuild(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var buildId = createData["id"].GetGuid();

        // Act
        var response = await _api_admin_client.DeleteBuild(buildId.ToString());
        var deletedBuild = await _context.Builds.FindAsync(buildId);
        var new_response = await _api_admin_client.GetBuild(buildId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(deletedBuild);
        Assert.Equal(HttpStatusCode.NotFound, new_response.StatusCode);
    }
}
