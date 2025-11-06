using System.Net;
using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Builds.BuildTag;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace KAZABUILD.Tests.Builds;

[Collection("Sequential")]
public class BuildTagsControllerTests : BaseIntegrationTest
{
    private BuildTagsControllerClient _buildTagsClient = null!;
    private User _testUser1 = null!;
    private User _testUser2 = null!;
    private HttpClient _testUser1HttpClient = null!;
    private HttpClient _testUser2HttpClient = null!;
    private Build _testBuild1 = null!;
    private Build _testBuild2 = null!;
    private Build _publishedBuild = null!;
    private Tag _testTag1 = null!;
    private Tag _testTag2 = null!;

    public BuildTagsControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        // Create test users
        _testUser1 = _context.Users.First(u => u.UserRole == UserRole.USER);
        _testUser2 = _context.Users.First(u => u.UserRole == UserRole.USER && u.Id != _testUser1.Id);

        // Create test builds
        _testBuild1 = new Build
        {
            UserId = _testUser1.Id,
            Name = "Test Build 1",
            Description = "First test build",
            Status = BuildStatus.DRAFT,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _testBuild2 = new Build
        {
            UserId = _testUser2.Id,
            Name = "Test Build 2",
            Description = "Second test build",
            Status = BuildStatus.DRAFT,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _publishedBuild = new Build
        {
            UserId = _testUser1.Id,
            Name = "Published Build",
            Description = "Public build",
            Status = BuildStatus.PUBLISHED,
            PublishedAt = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Builds.AddRange(_testBuild1, _testBuild2, _publishedBuild);

        // Create test tags
        _testTag1 = new Tag
        {
            Name = "Gaming",
            Description = "For gaming builds",
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _testTag2 = new Tag
        {
            Name = "Workstation",
            Description = "For workstation builds",
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Tags.AddRange(_testTag1, _testTag2);
        await _context.SaveChangesAsync();

        // Create HTTP clients for test users
        _testUser1HttpClient = await HttpClientFactory.Create(_factory, _testUser1, password: "password123!");
        _testUser2HttpClient = await HttpClientFactory.Create(_factory, _testUser2, password: "password123!");

        // Initialize clients
        _buildTagsClient = new BuildTagsControllerClient(_testUser1HttpClient);
    }

    #region AddBuildTag Tests

    [Fact]
    public async Task AddBuildTag_ToPublishedBuild_AsOwner_ReturnsOk()
    {
        // Arrange
        var dto = new CreateBuildTagDto
        {
            BuildId = _publishedBuild.Id,
            TagId = _testTag1.Id
        };

        // Act
        var response = await _buildTagsClient.AddBuildTag(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("id", content);

        // Verify build tag was created in database
        var buildTag = await _context.BuildTags
            .FirstOrDefaultAsync(bt => bt.BuildId == _publishedBuild.Id && bt.TagId == _testTag1.Id);
        Assert.NotNull(buildTag);
    }

    [Fact]
    public async Task AddBuildTag_ToDraftBuild_AsOwner_ReturnsForbidden()
    {
        // Arrange - Users can only tag published builds
        var dto = new CreateBuildTagDto
        {
            BuildId = _testBuild1.Id, // Draft build
            TagId = _testTag1.Id
        };

        // Act
        var response = await _buildTagsClient.AddBuildTag(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildTag_AsAdmin_CanTagAnyBuild()
    {
        // Arrange
        var adminClient = new BuildTagsControllerClient(_superAdminHttpClient);
        var dto = new CreateBuildTagDto
        {
            BuildId = _testBuild1.Id, // Draft build
            TagId = _testTag1.Id
        };

        // Act
        var response = await adminClient.AddBuildTag(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildTag_WithNonExistentBuild_ReturnsBadRequest()
    {
        // Arrange
        var dto = new CreateBuildTagDto
        {
            BuildId = Guid.NewGuid(), // Non-existent build
            TagId = _testTag1.Id
        };

        // Act
        var response = await _buildTagsClient.AddBuildTag(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildTag_WithNonExistentTag_ReturnsBadRequest()
    {
        // Arrange
        var dto = new CreateBuildTagDto
        {
            BuildId = _publishedBuild.Id,
            TagId = Guid.NewGuid() // Non-existent tag
        };

        // Act
        var response = await _buildTagsClient.AddBuildTag(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildTag_ToOtherUsersBuild_ReturnsForbidden()
    {
        // Arrange
        var otherUserPublishedBuild = new Build
        {
            UserId = _testUser2.Id,
            Name = "Other User Published Build",
            Description = "Public",
            Status = BuildStatus.PUBLISHED,
            PublishedAt = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Builds.Add(otherUserPublishedBuild);
        await _context.SaveChangesAsync();

        var dto = new CreateBuildTagDto
        {
            BuildId = otherUserPublishedBuild.Id,
            TagId = _testTag1.Id
        };

        // Act
        var response = await _buildTagsClient.AddBuildTag(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildTag_MultipleTagsToSameBuild_ReturnsOk()
    {
        // Arrange & Act
        var dto1 = new CreateBuildTagDto
        {
            BuildId = _publishedBuild.Id,
            TagId = _testTag1.Id
        };
        var response1 = await _buildTagsClient.AddBuildTag(dto1);

        var dto2 = new CreateBuildTagDto
        {
            BuildId = _publishedBuild.Id,
            TagId = _testTag2.Id
        };
        var response2 = await _buildTagsClient.AddBuildTag(dto2);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response1.StatusCode);
        Assert.Equal(HttpStatusCode.OK, response2.StatusCode);

        var buildTags = await _context.BuildTags
            .Where(bt => bt.BuildId == _publishedBuild.Id)
            .ToListAsync();
        Assert.Equal(2, buildTags.Count);
    }

    #endregion

    #region UpdateBuildTag Tests


    [Fact]
    public async Task UpdateBuildTag_AsRegularUser_ReturnsForbidden()
    {
        // Arrange
        var buildTag = new BuildTag
        {
            BuildId = _publishedBuild.Id,
            TagId = _testTag1.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildTags.Add(buildTag);
        await _context.SaveChangesAsync();

        var dto = new UpdateBuildTagDto
        {
            Note = "Trying to add note"
        };

        // Act
        var response = await _buildTagsClient.UpdateBuildTag(buildTag.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuildTag_NonExistent_ReturnsNotFound()
    {
        // Arrange
        var adminClient = new BuildTagsControllerClient(_superAdminHttpClient);
        var dto = new UpdateBuildTagDto
        {
            Note = "Test note"
        };

        // Act
        var response = await adminClient.UpdateBuildTag(Guid.NewGuid().ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetBuildTag Tests

    [Fact]
    public async Task GetBuildTag_NonExistent_ReturnsNotFound()
    {
        // Act
        var response = await _buildTagsClient.GetBuildTag(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetBuildTags Tests

    [Fact]
    public async Task GetBuildTags_WithNoFilters_ReturnsAccessibleTags()
    {
        // Arrange
        var buildTags = new[]
        {
            new BuildTag
            {
                BuildId = _publishedBuild.Id,
                TagId = _testTag1.Id,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new BuildTag
            {
                BuildId = _publishedBuild.Id,
                TagId = _testTag2.Id,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            }
        };
        _context.BuildTags.AddRange(buildTags);
        await _context.SaveChangesAsync();

        var dto = new GetBuildTagDto();

        // Act
        var response = await _buildTagsClient.GetBuildTags(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildTagResponseDto>>();
        Assert.NotNull(content);
        Assert.True(content.Count >= 2);
    }

    [Fact]
    public async Task GetBuildTags_WithBuildIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var buildTag = new BuildTag
        {
            BuildId = _publishedBuild.Id,
            TagId = _testTag1.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildTags.Add(buildTag);
        await _context.SaveChangesAsync();

        var dto = new GetBuildTagDto
        {
            BuildId = new List<Guid> { _publishedBuild.Id }
        };

        // Act
        var response = await _buildTagsClient.GetBuildTags(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildTagResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, bt => Assert.Equal(_publishedBuild.Id, bt.BuildId));
    }

    [Fact]
    public async Task GetBuildTags_WithTagIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var buildTag = new BuildTag
        {
            BuildId = _publishedBuild.Id,
            TagId = _testTag1.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildTags.Add(buildTag);
        await _context.SaveChangesAsync();

        var dto = new GetBuildTagDto
        {
            TagId = new List<Guid> { _testTag1.Id }
        };

        // Act
        var response = await _buildTagsClient.GetBuildTags(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildTagResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, bt => Assert.Equal(_testTag1.Id, bt.TagId));
    }

    [Fact]
    public async Task GetBuildTags_WithPagination_ReturnsPaginatedResults()
    {
        // Arrange - Create multiple build tags
        for (int i = 0; i < 5; i++)
        {
            var tag = new Tag
            {
                Name = $"Tag {i}",
                Description = $"Description {i}",
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.Tags.Add(tag);
            await _context.SaveChangesAsync();

            var buildTag = new BuildTag
            {
                BuildId = _publishedBuild.Id,
                TagId = tag.Id,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.BuildTags.Add(buildTag);
        }
        await _context.SaveChangesAsync();

        var dto = new GetBuildTagDto
        {
            Paging = true,
            Page = 1,
            PageLength = 2
        };

        // Act
        var response = await _buildTagsClient.GetBuildTags(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildTagResponseDto>>();
        Assert.NotNull(content);
        Assert.Equal(2, content.Count);
    }

    [Fact]
    public async Task GetBuildTags_WithSearchQuery_ReturnsMatchingResults()
    {
        // Arrange
        var uniqueTag = new Tag
        {
            Name = "Unicorn Special",
            Description = "Unique tag",
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Tags.Add(uniqueTag);
        await _context.SaveChangesAsync();

        var buildTag = new BuildTag
        {
            BuildId = _publishedBuild.Id,
            TagId = uniqueTag.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildTags.Add(buildTag);
        await _context.SaveChangesAsync();

        var dto = new GetBuildTagDto { Query = "Unicorn" };

        // Act
        var response = await _buildTagsClient.GetBuildTags(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildTagResponseDto>>();
        Assert.NotNull(content);
        Assert.Single(content);
    }

    [Fact]
    public async Task GetBuildTags_ExcludesDraftBuilds_ForOtherUsers()
    {
        // Arrange
        var buildTag = new BuildTag
        {
            BuildId = _testBuild2.Id, // Draft build owned by testUser2
            TagId = _testTag1.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildTags.Add(buildTag);
        await _context.SaveChangesAsync();

        var dto = new GetBuildTagDto();

        // Act - testUser1 querying
        var response = await _buildTagsClient.GetBuildTags(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildTagResponseDto>>();
        Assert.NotNull(content);
        Assert.DoesNotContain(content, bt => bt.BuildId == _testBuild2.Id);
    }

    [Fact]
    public async Task GetBuildTags_AsAdmin_SeesAllTags()
    {
        // Arrange
        var draftBuildTag = new BuildTag
        {
            BuildId = _testBuild1.Id, // Draft build
            TagId = _testTag1.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildTags.Add(draftBuildTag);
        await _context.SaveChangesAsync();

        var adminClient = new BuildTagsControllerClient(_superAdminHttpClient);
        var dto = new GetBuildTagDto();

        // Act
        var response = await adminClient.GetBuildTags(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildTagResponseDto>>();
        Assert.NotNull(content);
        Assert.Contains(content, bt => bt.BuildId == _testBuild1.Id);
    }

    #endregion

    #region DeleteBuildTag Tests

    [Fact]
    public async Task DeleteBuildTag_NonExistent_ReturnsNotFound()
    {
        // Act
        var response = await _buildTagsClient.DeleteBuildTag(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion
}
