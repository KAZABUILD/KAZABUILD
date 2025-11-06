using System.Net;
using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Builds.BuildComponent;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests.Builds;

[Collection("Sequential")]
public class BuildComponentsControllerTests : BaseIntegrationTest
{
    private BuildComponentsControllerClient _buildComponentsClient = null!;
    private User _testUser1 = null!;
    private User _testUser2 = null!;
    private HttpClient _testUser1HttpClient = null!;
    private HttpClient _testUser2HttpClient = null!;
    private Build _testBuild1 = null!;
    private Build _testBuild2 = null!;
    private BaseComponent _testComponent1 = null!;
    private BaseComponent _testComponent2 = null!;

    public BuildComponentsControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
            Status = BuildStatus.PUBLISHED,
            PublishedAt = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Builds.AddRange(_testBuild1, _testBuild2);

        // Create test components
        _testComponent1 = new BaseComponent
        {
            Name = "Test CPU",
            Manufacturer = "TestCorp",
            Type = ComponentType.CPU,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _testComponent2 = new BaseComponent
        {
            Name = "Test GPU",
            Manufacturer = "TestCorp",
            Type = ComponentType.GPU,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Components.AddRange(_testComponent1, _testComponent2);
        await _context.SaveChangesAsync();

        // Create HTTP clients for test users
        _testUser1HttpClient = await HttpClientFactory.Create(_factory, _testUser1, password: "password123!");
        _testUser2HttpClient = await HttpClientFactory.Create(_factory, _testUser2, password: "password123!");

        // Initialize clients
        _buildComponentsClient = new BuildComponentsControllerClient(_testUser1HttpClient);
    }

    #region AddBuildComponent Tests

    [Fact]
    public async Task AddBuildComponent_WithValidData_ReturnsOk()
    {
        // Arrange
        var dto = new CreateBuildComponentDto
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1
        };

        // Act
        var response = await _buildComponentsClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("id", content);

        // Verify build component was created in database
        var buildComponent = await _context.BuildComponents
            .FirstOrDefaultAsync(bc => bc.BuildId == _testBuild1.Id && bc.ComponentId == _testComponent1.Id);
        Assert.NotNull(buildComponent);
        Assert.Equal(1, buildComponent.Quantity);
    }

    [Fact]
    public async Task AddBuildComponent_WithMultipleQuantity_ReturnsOk()
    {
        // Arrange
        var dto = new CreateBuildComponentDto
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 5
        };

        // Act
        var response = await _buildComponentsClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var buildComponent = await _context.BuildComponents
            .FirstOrDefaultAsync(bc => bc.BuildId == _testBuild1.Id && bc.ComponentId == _testComponent1.Id);
        Assert.NotNull(buildComponent);
        Assert.Equal(5, buildComponent.Quantity);
    }

    [Fact]
    public async Task AddBuildComponent_WithNonExistentBuild_ReturnsBadRequest()
    {
        // Arrange
        var dto = new CreateBuildComponentDto
        {
            BuildId = Guid.NewGuid(), // Non-existent build
            ComponentId = _testComponent1.Id,
            Quantity = 1
        };

        // Act
        var response = await _buildComponentsClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildComponent_WithNonExistentComponent_ReturnsBadRequest()
    {
        // Arrange
        var dto = new CreateBuildComponentDto
        {
            BuildId = _testBuild1.Id,
            ComponentId = Guid.NewGuid(), // Non-existent component
            Quantity = 1
        };

        // Act
        var response = await _buildComponentsClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildComponent_DuplicateComponent_ReturnsBadRequest()
    {
        // Arrange - Create initial build component
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        var dto = new CreateBuildComponentDto
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 2
        };

        // Act
        var response = await _buildComponentsClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildComponent_ToOtherUsersBuild_ReturnsForbidden()
    {
        // Arrange
        var dto = new CreateBuildComponentDto
        {
            BuildId = _testBuild2.Id, // Belongs to testUser2
            ComponentId = _testComponent1.Id,
            Quantity = 1
        };

        // Act
        var response = await _buildComponentsClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildComponent_AsAdmin_CanAddToAnyBuild()
    {
        // Arrange
        var adminClient = new BuildComponentsControllerClient(_superAdminHttpClient);
        var dto = new CreateBuildComponentDto
        {
            BuildId = _testBuild2.Id, // Belongs to testUser2
            ComponentId = _testComponent1.Id,
            Quantity = 1
        };

        // Act
        var response = await adminClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildComponent_ToGeneratedBuild_AsUser_ReturnsBadRequest()
    {
        // Arrange - Create a generated build
        var generatedBuild = new Build
        {
            UserId = _testUser1.Id,
            Name = "Generated Build",
            Description = "Auto-generated",
            Status = BuildStatus.GENERATED,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Builds.Add(generatedBuild);
        await _context.SaveChangesAsync();

        var dto = new CreateBuildComponentDto
        {
            BuildId = generatedBuild.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1
        };

        // Act
        var response = await _buildComponentsClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddBuildComponent_ToGeneratedBuild_AsAdmin_ReturnsOk()
    {
        // Arrange
        var generatedBuild = new Build
        {
            UserId = _testUser1.Id,
            Name = "Generated Build",
            Description = "Auto-generated",
            Status = BuildStatus.GENERATED,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Builds.Add(generatedBuild);
        await _context.SaveChangesAsync();

        var adminClient = new BuildComponentsControllerClient(_superAdminHttpClient);
        var dto = new CreateBuildComponentDto
        {
            BuildId = generatedBuild.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1
        };

        // Act
        var response = await adminClient.AddBuildComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    #endregion

    #region UpdateBuildComponent Tests

    [Fact]
    public async Task UpdateBuildComponent_AsUser_CannotUpdateNote()
    {
        // Arrange
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        var dto = new UpdateBuildComponentDto
        {
            Note = "User note attempt"
        };

        // Act
        var response = await _buildComponentsClient.UpdateBuildComponent(buildComponent.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var updated = await _context.BuildComponents.FirstOrDefaultAsync(bc => bc.Id == buildComponent.Id);
        Assert.Null(updated!.Note); // Note should not be updated
    }

    [Fact]
    public async Task UpdateBuildComponent_AsOtherUser_ReturnsForbidden()
    {
        // Arrange
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild2.Id, // Belongs to testUser2
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        var dto = new UpdateBuildComponentDto
        {
            Quantity = 5
        };

        // Act
        var response = await _buildComponentsClient.UpdateBuildComponent(buildComponent.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuildComponent_NonExistent_ReturnsNotFound()
    {
        // Arrange
        var dto = new UpdateBuildComponentDto
        {
            Quantity = 2
        };

        // Act
        var response = await _buildComponentsClient.UpdateBuildComponent(Guid.NewGuid().ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateBuildComponent_InGeneratedBuild_AsUser_ReturnsBadRequest()
    {
        // Arrange
        var generatedBuild = new Build
        {
            UserId = _testUser1.Id,
            Name = "Generated Build",
            Description = "Auto-generated",
            Status = BuildStatus.GENERATED,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Builds.Add(generatedBuild);
        await _context.SaveChangesAsync();

        var buildComponent = new BuildComponent
        {
            BuildId = generatedBuild.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        var dto = new UpdateBuildComponentDto
        {
            Quantity = 3
        };

        // Act
        var response = await _buildComponentsClient.UpdateBuildComponent(buildComponent.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    #endregion

    #region GetBuildComponent Tests

    [Fact]
    public async Task GetBuildComponent_AsOwner_ReturnsOk()
    {
        // Arrange
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 2,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        // Act
        var response = await _buildComponentsClient.GetBuildComponent(buildComponent.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<BuildComponentResponseDto>();
        Assert.NotNull(content);
        Assert.Equal(buildComponent.Id, content.Id);
        Assert.Equal(2, content.Quantity);
        Assert.Null(content.DatabaseEntryAt); // Regular user shouldn't see this
    }

    [Fact]
    public async Task GetBuildComponent_AsAdmin_ReturnsFullDetails()
    {
        // Arrange
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 2,
            Note = "Admin note",
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        var adminClient = new BuildComponentsControllerClient(_superAdminHttpClient);

        // Act
        var response = await adminClient.GetBuildComponent(buildComponent.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<BuildComponentResponseDto>();
        Assert.NotNull(content);
        Assert.NotNull(content.DatabaseEntryAt); // Admin should see this
        Assert.Equal("Admin note", content.Note);
    }

    [Fact]
    public async Task GetBuildComponent_PublishedBuild_AsOtherUser_ReturnsOk()
    {
        // Arrange
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild2.Id, // Published build
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        // Act
        var response = await _buildComponentsClient.GetBuildComponent(buildComponent.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetBuildComponent_DraftBuild_AsOtherUser_ReturnsForbidden()
    {
        // Arrange
        var draftBuild = new Build
        {
            UserId = _testUser2.Id,
            Name = "Draft Build",
            Description = "Private draft",
            Status = BuildStatus.DRAFT,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Builds.Add(draftBuild);
        await _context.SaveChangesAsync();

        var buildComponent = new BuildComponent
        {
            BuildId = draftBuild.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        // Act
        var response = await _buildComponentsClient.GetBuildComponent(buildComponent.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetBuildComponent_NonExistent_ReturnsNotFound()
    {
        // Act
        var response = await _buildComponentsClient.GetBuildComponent(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetBuildComponents Tests

    [Fact]
    public async Task GetBuildComponents_WithNoFilters_ReturnsComponents()
    {
        // Arrange
        var buildComponents = new[]
        {
            new BuildComponent
            {
                BuildId = _testBuild1.Id,
                ComponentId = _testComponent1.Id,
                Quantity = 1,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new BuildComponent
            {
                BuildId = _testBuild1.Id,
                ComponentId = _testComponent2.Id,
                Quantity = 2,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            }
        };
        _context.BuildComponents.AddRange(buildComponents);
        await _context.SaveChangesAsync();

        var dto = new GetBuildComponentDto();

        // Act
        var response = await _buildComponentsClient.GetBuildComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildComponentResponseDto>>();
        Assert.NotNull(content);
        Assert.True(content.Count >= 2);
    }

    [Fact]
    public async Task GetBuildComponents_WithBuildIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        var dto = new GetBuildComponentDto
        {
            BuildId = new List<Guid> { _testBuild1.Id }
        };

        // Act
        var response = await _buildComponentsClient.GetBuildComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildComponentResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, bc => Assert.Equal(_testBuild1.Id, bc.BuildId));
    }

    [Fact]
    public async Task GetBuildComponents_WithComponentIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        var dto = new GetBuildComponentDto
        {
            ComponentId = new List<Guid> { _testComponent1.Id }
        };

        // Act
        var response = await _buildComponentsClient.GetBuildComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildComponentResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, bc => Assert.Equal(_testComponent1.Id, bc.ComponentId));
    }

    [Fact]
    public async Task GetBuildComponents_WithQuantityRange_ReturnsFilteredResults()
    {
        // Arrange
        var buildComponents = new[]
        {
            new BuildComponent
            {
                BuildId = _testBuild1.Id,
                ComponentId = _testComponent1.Id,
                Quantity = 2,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new BuildComponent
            {
                BuildId = _testBuild1.Id,
                ComponentId = _testComponent2.Id,
                Quantity = 5,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            }
        };
        _context.BuildComponents.AddRange(buildComponents);
        await _context.SaveChangesAsync();

        var dto = new GetBuildComponentDto
        {
            QuantityStart = 2,
            QuantityEnd = 4
        };

        // Act
        var response = await _buildComponentsClient.GetBuildComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildComponentResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, bc =>
        {
            Assert.True(bc.Quantity >= 2);
            Assert.True(bc.Quantity <= 4);
        });
    }

    [Fact]
    public async Task GetBuildComponents_WithPagination_ReturnsPaginatedResults()
    {
        // Arrange - Create multiple components
        for (int i = 0; i < 5; i++)
        {
            var component = new BaseComponent
            {
                Name = $"Component {i}",
                Manufacturer = "TestCorp",
                Type = ComponentType.CPU,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.Components.Add(component);
            await _context.SaveChangesAsync();

            var buildComponent = new BuildComponent
            {
                BuildId = _testBuild1.Id,
                ComponentId = component.Id,
                Quantity = i + 1,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.BuildComponents.Add(buildComponent);
        }

        await _context.SaveChangesAsync();

        var dto = new GetBuildComponentDto
        {
            Paging = true,
            Page = 1,
            PageLength = 2
        };

        // Act
        var response = await _buildComponentsClient.GetBuildComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildComponentResponseDto>>();
        Assert.NotNull(content);
        Assert.Equal(2, content.Count);
    }

    [Fact]
    public async Task GetBuildComponents_WithSearchQuery_ReturnsMatchingResults()
    {
        // Arrange
        var uniqueBuild = new Build
        {
            UserId = _testUser1.Id,
            Name = "Unicorn Gaming Build",
            Description = "Special build",
            Status = BuildStatus.PUBLISHED,
            PublishedAt = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Builds.Add(uniqueBuild);
        await _context.SaveChangesAsync();

        var buildComponent = new BuildComponent
        {
            BuildId = uniqueBuild.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        var dto = new GetBuildComponentDto { Query = "Unicorn" };

        // Act
        var response = await _buildComponentsClient.GetBuildComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildComponentResponseDto>>();
        Assert.NotNull(content);
        Assert.Single(content);
    }

    [Fact]
    public async Task GetBuildComponents_ExcludesDraftBuilds_ForOtherUsers()
    {
        // Arrange
        var draftBuild = new Build
        {
            UserId = _testUser2.Id,
            Name = "Private Draft",
            Description = "Should not be visible",
            Status = BuildStatus.DRAFT,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Builds.Add(draftBuild);
        await _context.SaveChangesAsync();

        var buildComponent = new BuildComponent
        {
            BuildId = draftBuild.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);

        await _context.SaveChangesAsync();

        var dto = new GetBuildComponentDto();

        // Act
        var response = await _buildComponentsClient.GetBuildComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<BuildComponentResponseDto>>();
        Assert.NotNull(content);
        Assert.DoesNotContain(content, bc => bc.BuildId == draftBuild.Id);
    }

    #endregion

    [Fact]
    public async Task DeleteBuildComponent_AsOwner_ReturnsOk()
    {
        // Arrange
        var buildComponent = new BuildComponent
        {
            BuildId = _testBuild1.Id,
            ComponentId = _testComponent1.Id,
            Quantity = 1,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.BuildComponents.Add(buildComponent);
        await _context.SaveChangesAsync();

        // Act
        var response = await _buildComponentsClient.DeleteBuildComponent(buildComponent.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deleted = await _context.BuildComponents.FirstOrDefaultAsync(bc => bc.Id == buildComponent.Id);
        Assert.Null(deleted);
    }
}
