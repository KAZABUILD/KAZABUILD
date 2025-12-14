using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Components.ComponentPart;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests.Components;

[Collection("Sequential")]
public class ComponentPartControllerTests : BaseIntegrationTest
{
    private ComponentPartsControllerClient _api_user_client = null!;
    private ComponentPartsControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public ComponentPartControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
        _api_admin_client = new ComponentPartsControllerClient(_client_admin);
        _api_user_client = new ComponentPartsControllerClient(_client_user);
    }

    [Fact]
    public async Task AddComponentPart_ByUser_ShouldReturnForbidden()
    {
        // Arrange - Get two different components
        var components = await _context.Components.Take(2).ToListAsync();
        if (components.Count < 2)
        {
            Assert.Fail("Not enough components in database for test");
        }

        var createDto = new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 1
        };

        // Act
        var response = await _api_user_client.AddComponentPart(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddComponentPart_WithNonExistentComponent_ShouldReturnBadRequest()
    {
        // Arrange
        var component = await _context.Components.FirstOrDefaultAsync();
        var createDto = new CreateComponentPartDto
        {
            ComponentId = Guid.NewGuid(), // Non-existent component
            SubComponentId = component!.Id,
            Amount = 1
        };

        // Act
        var response = await _api_admin_client.AddComponentPart(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddComponentPart_AlreadyExists_ShouldReturnBadRequest()
    {
        // Arrange - Create a part first
        var components = await _context.Components.Take(2).ToListAsync();
        if (components.Count < 2)
        {
            Assert.Fail("Not enough components in database for test");
        }

        var createDto = new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 1
        };
        await _api_admin_client.AddComponentPart(createDto);

        // Act - Try to create the same part again
        var response = await _api_admin_client.AddComponentPart(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddComponentPart_WithAmountBelowMinimum_ShouldReturnBadRequest()
    {
        // Arrange
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 0 // Below minimum
        };

        // Act
        var response = await _api_admin_client.AddComponentPart(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddComponentPart_WithAmountAboveMaximum_ShouldReturnBadRequest()
    {
        // Arrange
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 51 // Above maximum
        };

        // Act
        var response = await _api_admin_client.AddComponentPart(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateComponentPart_ByUser_ShouldReturnForbidden()
    {
        // Arrange - Create a part
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 5
        };
        var createResponse = await _api_admin_client.AddComponentPart(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData =
            JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var partId = createData["id"].GetGuid();

        var updateDto = new UpdateComponentPartDto
        {
            Note = "Trying to update as user"
        };

        // Act
        var response = await _api_user_client.UpdateComponentPart(partId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateComponentPart_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateDto = new UpdateComponentPartDto
        {
            Amount = 10
        };

        // Act
        var response = await _api_admin_client.UpdateComponentPart(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetComponentPart_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetComponentPart(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetComponentParts_ByAdmin_ShouldReturnAllWithAdminFields()
    {
        // Arrange
        var getDto = new GetComponentPartDto();

        // Act
        var response = await _api_admin_client.GetComponentParts(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentPartResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
        Assert.All(data, part =>
        {
            Assert.NotNull(part.DatabaseEntryAt); // Admin should see all fields
            Assert.NotNull(part.LastEditedAt);
        });
    }

    [Fact]
    public async Task GetComponentParts_ByUser_ShouldReturnWithoutAdminFields()
    {
        // Arrange
        var getDto = new GetComponentPartDto();

        // Act
        var response = await _api_user_client.GetComponentParts(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentPartResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
        Assert.All(data, part =>
        {
            Assert.Null(part.DatabaseEntryAt); // Users shouldn't see timestamps
            Assert.Null(part.LastEditedAt);
            Assert.Null(part.Note); // Users shouldn't see notes
        });
    }

    [Fact]
    public async Task GetComponentParts_WithComponentIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange - Create a part
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 2
        };
        await _api_admin_client.AddComponentPart(createDto);

        var getDto = new GetComponentPartDto
        {
            ComponentId = new List<Guid> { components[0].Id }
        };

        // Act
        var response = await _api_admin_client.GetComponentParts(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentPartResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, part => Assert.Equal(components[0].Id, part.ComponentId));
    }

    [Fact]
    public async Task GetComponentParts_WithSubComponentIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange - Create a part
        var components = await _context.Components.Take(2).ToListAsync();
        var createDto = new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 2
        };
        await _api_admin_client.AddComponentPart(createDto);

        var getDto = new GetComponentPartDto
        {
            SubComponentId = new List<Guid> { components[1].Id }
        };

        // Act
        var response = await _api_admin_client.GetComponentParts(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentPartResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, part => Assert.Equal(components[1].Id, part.SubComponentId));
    }

    [Fact]
    public async Task GetComponentParts_WithAmountStartFilter_ShouldReturnFilteredResults()
    {
        // Arrange - Create parts with different amounts
        var components = await _context.Components.Take(3).ToListAsync();
        await _api_admin_client.AddComponentPart(new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 5
        });
        await _api_admin_client.AddComponentPart(new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[2].Id,
            Amount = 15
        });

        var getDto = new GetComponentPartDto
        {
            AmountStart = 10
        };

        // Act
        var response = await _api_admin_client.GetComponentParts(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentPartResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, part => Assert.True(part.Amount >= 10));
    }

    [Fact]
    public async Task GetComponentParts_WithAmountEndFilter_ShouldReturnFilteredResults()
    {
        // Arrange - Create parts with different amounts
        var components = await _context.Components.Take(3).ToListAsync();
        await _api_admin_client.AddComponentPart(new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 5
        });
        await _api_admin_client.AddComponentPart(new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[2].Id,
            Amount = 25
        });

        var getDto = new GetComponentPartDto
        {
            AmountEnd = 10
        };

        // Act
        var response = await _api_admin_client.GetComponentParts(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentPartResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, part => Assert.True(part.Amount <= 10));
    }

    [Fact]
    public async Task GetComponentParts_WithAmountRangeFilter_ShouldReturnFilteredResults()
    {
        // Arrange - Create parts with different amounts
        var components = await _context.Components.Take(4).ToListAsync();
        await _api_admin_client.AddComponentPart(new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[1].Id,
            Amount = 5
        });
        await _api_admin_client.AddComponentPart(new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[2].Id,
            Amount = 15
        });
        await _api_admin_client.AddComponentPart(new CreateComponentPartDto
        {
            ComponentId = components[0].Id,
            SubComponentId = components[3].Id,
            Amount = 25
        });

        var getDto = new GetComponentPartDto
        {
            AmountStart = 10,
            AmountEnd = 20
        };

        // Act
        var response = await _api_admin_client.GetComponentParts(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentPartResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, part =>
        {
            Assert.True(part.Amount >= 10);
            Assert.True(part.Amount <= 20);
        });
    }

    [Fact]
    public async Task GetComponentParts_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetComponentPartDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetComponentParts(getDto);
        var data = JsonSerializer.Deserialize<List<ComponentPartResponseDto>>(
            response.Content.ReadAsStringAsync().Result,
            _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }
}
