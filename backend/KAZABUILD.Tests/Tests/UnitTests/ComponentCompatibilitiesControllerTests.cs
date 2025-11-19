using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Components.ComponentCompatibility;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests.Components;

[Collection("Sequential")]
public class ComponentCompatibilityControllerTests : BaseIntegrationTest
{
    private ComponentCompatibilitiesControllerClient _api_user_client = null!;
    private ComponentCompatibilitiesControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public ComponentCompatibilityControllerTests(KazaWebApplicationFactory factory) : base(factory)
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

        // Creating user clients
        _client_user = await HttpClientFactory.Create(_factory, user);
        _client_admin = await HttpClientFactory.Create(_factory, admin);

        // Initialization of controller clients
        _api_admin_client = new ComponentCompatibilitiesControllerClient(_client_admin);
        _api_user_client = new ComponentCompatibilitiesControllerClient(_client_user);
    }

    [Fact]
    public async Task AddComponentCompatibility_ByUser_ShouldReturnForbidden()
    {
        // Arrange - Get two different components
        var components = await _context.Components.Take(2).ToListAsync();
        if (components.Count < 2)
        {
            Assert.Fail("Not enough components in database for test");
        }

        var createDto = new CreateComponentCompatibilityDto
        {
            ComponentId = components[0].Id,
            CompatibleComponentId = components[1].Id
        };

        // Act
        var response = await _api_user_client.AddComponentCompatibility(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddComponentCompatibility_WithNonExistentComponent_ShouldReturnBadRequest()
    {
        // Arrange
        var component = await _context.Components.FirstOrDefaultAsync();
        var createDto = new CreateComponentCompatibilityDto
        {
            ComponentId = Guid.NewGuid(), // Non-existent component
            CompatibleComponentId = component!.Id
        };

        // Act
        var response = await _api_admin_client.AddComponentCompatibility(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddComponentCompatibility_WithNonExistentCompatibleComponent_ShouldReturnBadRequest()
    {
        // Arrange
        var component = await _context.Components.FirstOrDefaultAsync();
        var createDto = new CreateComponentCompatibilityDto
        {
            ComponentId = component!.Id,
            CompatibleComponentId = Guid.NewGuid() // Non-existent component
        };

        // Act
        var response = await _api_admin_client.AddComponentCompatibility(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddComponentCompatibility_AlreadyCompatible_ShouldReturnBadRequest()
    {
        // Arrange - Create a compatibility first
        var components = await _context.Components.Take(2).ToListAsync();
        if (components.Count < 2)
        {
            Assert.Fail("Not enough components in database for test");
        }

        var createDto = new CreateComponentCompatibilityDto
        {
            ComponentId = components[0].Id,
            CompatibleComponentId = components[1].Id
        };
        await _api_admin_client.AddComponentCompatibility(createDto);

        // Act - Try to create the same compatibility again
        var response = await _api_admin_client.AddComponentCompatibility(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateComponentCompatibility_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateDto = new UpdateComponentCompatibilityDto
        {
            Note = "Test Update"
        };

        // Act
        var response = await _api_admin_client.UpdateComponentCompatibility(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetComponentCompatibility_ByAdmin_ShouldSucceedWithAdminFields()
    {
        // Arrange - Create a compatibility with note
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentCompatibilityDto
        {
            ComponentId = components[0].Id,
            CompatibleComponentId = components[1].Id
        };
        var createResponse = await _api_admin_client.AddComponentCompatibility(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var compatibilityId = createData["id"].GetGuid();

        var adminNote = "Admin note";
        await _api_admin_client.UpdateComponentCompatibility(compatibilityId.ToString(),
            new UpdateComponentCompatibilityDto { Note = adminNote });

        // Act
        var response = await _api_admin_client.GetComponentCompatibility(compatibilityId.ToString());
        var data = JsonSerializer.Deserialize<ComponentCompatibilityResponseDto>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data.DatabaseEntryAt); // Admin should see timestamps
        Assert.NotNull(data.LastEditedAt);
        Assert.Equal(adminNote, data.Note); // Admin should see notes
    }

    [Fact]
    public async Task GetComponentCompatibility_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetComponentCompatibility(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetComponentCompatibilities_WithComponentIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange - Create a compatibility
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentCompatibilityDto
        {
            ComponentId = components[0].Id,
            CompatibleComponentId = components[1].Id
        };
        await _api_admin_client.AddComponentCompatibility(createDto);

        var getDto = new GetComponentCompatibilityDto
        {
            ComponentId = new List<Guid> { components[0].Id }
        };

        // Act
        var response = await _api_admin_client.GetComponentCompatibilities(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentCompatibilityResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, compatibility => Assert.Equal(components[0].Id, compatibility.ComponentId));
    }

    [Fact]
    public async Task GetComponentCompatibilities_WithCompatibleComponentIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange - Create a compatibility
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentCompatibilityDto
        {
            ComponentId = components[0].Id,
            CompatibleComponentId = components[1].Id
        };
        await _api_admin_client.AddComponentCompatibility(createDto);

        var getDto = new GetComponentCompatibilityDto
        {
            CompatibleComponentId = new List<Guid> { components[1].Id }
        };

        // Act
        var response = await _api_admin_client.GetComponentCompatibilities(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentCompatibilityResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, compatibility => Assert.Equal(components[1].Id, compatibility.CompatibleComponentId));
    }

    [Fact]
    public async Task GetComponentCompatibilities_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetComponentCompatibilityDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetComponentCompatibilities(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentCompatibilityResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }

    [Fact]
    public async Task GetComponentCompatibilities_WithOrderBy_ShouldReturnOrderedResults()
    {
        // Arrange
        var getDto = new GetComponentCompatibilityDto
        {
            OrderBy = "ComponentId",
            SortDirection = "asc"
        };

        // Act
        var response = await _api_admin_client.GetComponentCompatibilities(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentCompatibilityResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        if (data.Count > 1)
        {
            var orderedData = data.OrderBy(c => c.ComponentId).ToList();
            Assert.Equal(orderedData.Select(c => c.ComponentId), data.Select(c => c.ComponentId));
        }
    }

    [Fact]
    public async Task GetComponentCompatibilities_WithQuery_ShouldReturnMatchingResults()
    {
        // Arrange
        var getDto = new GetComponentCompatibilityDto
        {
            Query = "component"
        };

        // Act
        var response = await _api_admin_client.GetComponentCompatibilities(getDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task DeleteComponentCompatibility_ByAdmin_ShouldSucceed()
    {
        // Arrange - Create a compatibility
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentCompatibilityDto
        {
            ComponentId = components[0].Id,
            CompatibleComponentId = components[1].Id
        };
        var createResponse = await _api_admin_client.AddComponentCompatibility(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var compatibilityId = createData["id"].GetGuid();

        // Act
        var response = await _api_admin_client.DeleteComponentCompatibility(compatibilityId.ToString());
        var deletedCompatibility = await _context.ComponentCompatibilities.FindAsync(compatibilityId);
        var getResponse = await _api_admin_client.GetComponentCompatibility(compatibilityId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(deletedCompatibility);
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);
    }

    [Fact]
    public async Task DeleteComponentCompatibility_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_admin_client.DeleteComponentCompatibility(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
