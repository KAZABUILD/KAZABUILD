using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Components.ComponentPrice;
using KazaComponent = KAZABUILD.Domain.Entities.Components.Components.BaseComponent;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;
using KAZABUILD.Domain.Entities.Components;

namespace KAZABUILD.Tests;

public class ComponentPricesControllerTests : BaseIntegrationTest
{
    private ComponentPricesControllerClient _api_user_client = null!;
    private ComponentPricesControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;

    private User admin = null!;
    private User user = null!;

    // Entities to use in tests
    private KazaComponent component = null!; // Changed from Component to KazaComponent
    private ComponentPrice price_to_test = null!;
    private ComponentPrice price_to_remove = null!;

    private readonly JsonSerializerOptions _jsonSerializerOptions;

    // Test constants
    private const string TestNote = "This is a test note for admins.";
    private const string TestVendor = "SpecificTestVendor";
    private const string OtherTestVendor = "AnotherVendor";

    public ComponentPricesControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
        // Configure JsonSerializerOptions to handle enums as strings
        _jsonSerializerOptions = new JsonSerializerOptions
        {
            Converters = { new JsonStringEnumConverter() },
            PropertyNameCaseInsensitive = true
        };
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        // Seed users for authentication
        await _dataSeeder.SeedAsync<User, Guid>(50, password: "password123!");

        // Seed prerequisite data for component prices
        await _dataSeeder.SeedAsync<KazaComponent, Guid>(20); // Changed from Component to KazaComponent

        // Find users
        admin = await _context.Users.FirstAsync(u => u.UserRole == UserRole.ADMINISTRATOR);
        user = await _context.Users.FirstAsync(u => u.UserRole == UserRole.USER);

        // Find prerequisite entities
        component = await _context.Components.FirstAsync(c => c.Note != null);

        // Seed component prices
        await _dataSeeder.SeedAsync<ComponentPrice, Guid>(10);

        // Find and update specific prices for testing
        var prices = await _context.ComponentPrices.Take(2).ToListAsync();

        price_to_test = prices[0];
        price_to_test.Note = component.Note;

        price_to_remove = prices[1];

        await _context.SaveChangesAsync();

        // Creating user clients
        _client_user = await HttpClientFactory.Create(_factory, user);
        _client_admin = await HttpClientFactory.Create(_factory, admin);

        // Initialization of controller clients
        _api_admin_client = new ComponentPricesControllerClient(_client_admin);
        _api_user_client = new ComponentPricesControllerClient(_client_user);
    }

    [Fact]
    public async Task AddComponentPrice_ByAdmin_ShouldSucceed()
    {
        // Arrange
        var createDto = new CreateComponentPriceDto
        {
            Price = 199.99m,
            ComponentId = component.Id,
            VendorName = "NewVendor",
            Currency = "USD",
            SourceUrl = "http://example.com"
        };

        // Act
        var response = await _api_admin_client.AddComponentPrice(createDto);
        var content = await response.Content.ReadAsStringAsync();

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Verify the response body contains the new ID
        var responseObject = JsonSerializer.Deserialize<JsonElement>(content, _jsonSerializerOptions);
        Assert.True(responseObject.TryGetProperty("id", out var idElement));
        Assert.NotEqual(Guid.Empty, idElement.GetGuid());
    }

    [Fact]
    public async Task AddComponentPrice_ByAdmin_WithNonExistentComponent_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateComponentPriceDto
        {
            Price = 199.99m,
            ComponentId = Guid.NewGuid(), // Non-existent Component ID
            VendorName = "NewVendor",
            Currency = "USD"
        };

        // Act
        var response = await _api_admin_client.AddComponentPrice(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddComponentPrice_ByUser_ShouldReturnForbidden()
    {
        // Arrange
        var createDto = new CreateComponentPriceDto
        {
            Price = 99.99m,
            ComponentId = component.Id,
            VendorName = "UserVendor",
            Currency = "EUR"
        };

        // Act
        var response = await _api_user_client.AddComponentPrice(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }


    [Fact]
    public async Task UpdateComponentPrice_ByAdmin_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var newPrice = 123.45m;
        var updateDto = new UpdateComponentPriceDto { Price = newPrice };
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_admin_client.UpdateComponentPrice(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateComponentPrice_ByUser_ShouldReturnForbidden()
    {
        // Arrange
        var updateDto = new UpdateComponentPriceDto { Price = 1.00m };

        // Act
        var response = await _api_user_client.UpdateComponentPrice(price_to_test.Id.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteComponentPrice_ByAdmin_ShouldSucceed()
    {
        // Act
        var response = await _api_admin_client.DeleteComponentPrice(price_to_remove.Id.ToString());
        var new_response = await _api_admin_client.GetComponentPrice(price_to_remove.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, new_response.StatusCode);
    }

    [Fact]
    public async Task DeleteComponentPrice_ByAdmin_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_admin_client.DeleteComponentPrice(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteComponentPrice_ByUser_ShouldReturnForbidden()
    {
        // Act
        var response = await _api_user_client.DeleteComponentPrice(price_to_remove.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetComponentPrice_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetComponentPrice(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetComponentPrice_ByUser_ShouldSucceedAndMaskAdminFields()
    {
        // Act
        var response = await _api_user_client.GetComponentPrice(price_to_test.Id.ToString());
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<ComponentPriceResponseDto>(content, _jsonSerializerOptions);

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        Assert.NotNull(data);
        Assert.Equal(price_to_test.Id, data.Id);
        Assert.Equal(price_to_test.Price, data.Price);

        // Verify admin fields are masked (null)
        Assert.Null(data.Note);
        Assert.Null(data.DatabaseEntryAt);
        Assert.Null(data.LastEditedAt);
    }

    [Fact]
    public async Task GetComponentPrice_ByAdmin_ShouldSucceedAndReturnAllFields()
    {
        // Act
        var response = await _api_admin_client.GetComponentPrice(price_to_test.Id.ToString());
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<ComponentPriceResponseDto>(content, _jsonSerializerOptions);

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        Assert.NotNull(data);
        Assert.Equal(price_to_test.Id, data.Id);

        // Verify admin fields are visible
        Assert.Equal(TestNote, data.Note);
        Assert.NotNull(data.DatabaseEntryAt);
        Assert.NotNull(data.LastEditedAt);
    }

    [Fact]
    public async Task GetComponentPrices_ByUser_ShouldSucceedAndMaskAdminFields()
    {
        // Arrange
        var getDto = new GetComponentPriceDto();

        // Act
        var response = await _api_user_client.GetComponentPrices(getDto);
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<List<ComponentPriceResponseDto>>(content, _jsonSerializerOptions);

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        Assert.NotNull(data);
        Assert.True(data.Count > 0);

        // Find the specific item and check for masked fields
        var specificPrice = data.FirstOrDefault(p => p.Id == price_to_test.Id);
        Assert.NotNull(specificPrice);
        Assert.Null(specificPrice.Note);
        Assert.Null(specificPrice.DatabaseEntryAt);
    }

    [Fact]
    public async Task GetComponentPrices_ByAdmin_ShouldSucceedAndReturnAllFields()
    {
        // Arrange
        var getDto = new GetComponentPriceDto();

        // Act
        var response = await _api_admin_client.GetComponentPrices(getDto);
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<List<ComponentPriceResponseDto>>(content, _jsonSerializerOptions);

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        Assert.NotNull(data);
        Assert.True(data.Count > 0);

        // Find the specific item and check for admin fields
        var specificPrice = data.FirstOrDefault(p => p.Id == price_to_test.Id);
        Assert.NotNull(specificPrice);
    }

    [Fact]
    public async Task GetComponentPrices_WithFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        // Filter for the specific vendor we set in InitializeAsync
        var getDto = new GetComponentPriceDto
        {
            VendorName = new List<string> { TestVendor }
        };

        // Act
        var response = await _api_admin_client.GetComponentPrices(getDto);
        var content = await response.Content.ReadAsStringAsync();
        var data = JsonSerializer.Deserialize<List<ComponentPriceResponseDto>>(content, _jsonSerializerOptions);

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        Assert.NotNull(data);
        Assert.True(data.Count > 0);
        // All returned items must match the filter
        Assert.True(data.All(p => p.VendorName == TestVendor));
        // Ensure the other vendor is not in the list
        Assert.False(data.Any(p => p.VendorName == OtherTestVendor));
    }
}


