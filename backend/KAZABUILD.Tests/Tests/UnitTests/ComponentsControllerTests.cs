using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Application.DTOs.Components.Components.CPUComponent;
using KAZABUILD.Application.DTOs.Components.Components.StorageComponent;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Validations.Rules;
using Xunit;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class ComponentsControllerTests : BaseIntegrationTest
{
    private ComponentsControllerClient _componentsClient = null!;
    private CPUComponent _seededCPU = null!;
    private StorageComponent _seededStorage = null!;
    private JsonSerializerOptions _jsonOptions;
    public ComponentsControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        // Get seeded components
        _seededCPU = await _context.Components.OfType<CPUComponent>().FirstAsync();
        _seededStorage = await _context.Components.OfType<StorageComponent>().FirstAsync();

        // Initialize client with admin credentials (Components require Admin policy)
        _componentsClient = new ComponentsControllerClient(_superAdminHttpClient);

        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            Converters = { new JsonStringEnumConverter() }
        };
    }

    #region AddComponent Tests

    [Fact]
    public async Task AddComponent_CPUWithValidData_ReturnsOk()
    {
        // Arrange
        var dto = new CreateCPUComponentDto
        {
            Name = "Intel Core i9-14900K",
            Manufacturer = "Intel",
            Release = new DateTime(2023, 10, 1),
            Type = ComponentType.CPU,
            Series = "Core i9",
            Microarchitecture = "Raptor Lake",
            CoreFamily = "14th Gen",
            SocketType = "LGA1700",
            CoreTotal = 24,
            PerformanceAmount = 8,
            EfficiencyAmount = 16,
            ThreadsAmount = 32,
            BasePerformanceSpeed = 3.0m,
            BoostPerformanceSpeed = 6.0m,
            L2 = 32,
            L3 = 36,
            IncludesCooler = false,
            Lithography = "10nm",
            SupportsSimultaneousMultithreading = true,
            MemoryType = "DDR5",
            PackagingType = "Boxed",
            SupportsECC = false,
            ThermalDesignPower = 125
        };

        // Act
        var response = await _componentsClient.AddComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        var jsonDoc = System.Text.Json.JsonDocument.Parse(content);
        var componentId = Guid.Parse(jsonDoc.RootElement.GetProperty("id").GetString()!);

        var component = await _context.Components.OfType<CPUComponent>().FirstOrDefaultAsync(c => c.Id == componentId);
        Assert.NotNull(component);
        Assert.Equal(dto.Name, component.Name);
        Assert.Equal(dto.Series, component.Series);
        Assert.Equal(dto.SocketType, component.SocketType);
    }

    [Fact]
    public async Task AddComponent_StorageWithValidData_ReturnsOk()
    {
        // Arrange
        var dto = new CreateStorageComponentDto
        {
            Name = "Samsung 990 PRO",
            Manufacturer = "Samsung",
            Release = new DateTime(2023, 1, 1),
            Type = ComponentType.STORAGE,
            Series = "990 PRO",
            Capacity = 2000,
            DriveType = "SSD",
            FormFactor = "M.2",
            Interface = "PCIe 4.0 x4",
            HasNVMe = true
        };

        // Act
        var response = await _componentsClient.AddComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        var jsonDoc = System.Text.Json.JsonDocument.Parse(content);
        var componentId = Guid.Parse(jsonDoc.RootElement.GetProperty("id").GetString()!);

        var component = await _context.Components.OfType<StorageComponent>().FirstOrDefaultAsync(c => c.Id == componentId);
        Assert.NotNull(component);
        Assert.Equal(dto.Name, component.Name);
        Assert.Equal(dto.Capacity, component.Capacity);
        Assert.True(component.HasNVMe);
    }

    [Fact]
    public async Task AddComponent_AsNonAdmin_ReturnsForbidden()
    {
        // Arrange - Create a regular user client
        var regularUser = await _context.Users.FirstAsync(u => u.UserRole == UserRole.USER);
        var userHttpClient = await HttpClientFactory.Create(_factory, regularUser, password: "password123!");
        var userClient = new ComponentsControllerClient(userHttpClient);

        var dto = new CreateStorageComponentDto
        {
            Name = "Test Storage",
            Manufacturer = "Test",
            Type = ComponentType.STORAGE,
            Series = "Test",
            Capacity = 1000,
            DriveType = "SSD",
            FormFactor = "2.5\"",
            Interface = "SATA",
            HasNVMe = false
        };

        // Act
        var response = await userClient.AddComponent(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    #endregion

    #region UpdateComponent Tests

    [Fact]
    public async Task UpdateComponent_CPUFields_ReturnsOk()
    {
        // Arrange
        var cpu = _seededCPU;
        var originalSeries = cpu.Series;
        var originalSocketType = cpu.SocketType;

        var dto = new UpdateCPUComponentDto
        {
            Series = "Updated Series",
            SocketType = "Updated Socket"
        };

        // Act
        var response = await _componentsClient.UpdateComponent(cpu.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Refresh from database
        await _context.Entry(cpu).ReloadAsync();
        Assert.Equal("Updated Series", cpu.Series);
        Assert.Equal("Updated Socket", cpu.SocketType);

        // Restore original values
        var restoreDto = new UpdateCPUComponentDto
        {
            Series = originalSeries,
            SocketType = originalSocketType
        };
        await _componentsClient.UpdateComponent(cpu.Id.ToString(), restoreDto);
    }

    [Fact]
    public async Task UpdateComponent_StorageFields_ReturnsOk()
    {
        // Arrange
        var storage = _seededStorage;
        var originalCapacity = storage.Capacity;
        var originalSeries = storage.Series;

        var dto = new UpdateStorageComponentDto
        {
            Capacity = 4000,
            Series = "Updated Series"
        };

        // Act
        var response = await _componentsClient.UpdateComponent(storage.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Refresh from database
        await _context.Entry(storage).ReloadAsync();
        Assert.Equal(4000, storage.Capacity);
        Assert.Equal("Updated Series", storage.Series);

        // Restore original values
        var restoreDto = new UpdateStorageComponentDto
        {
            Capacity = originalCapacity,
            Series = originalSeries
        };
        await _componentsClient.UpdateComponent(storage.Id.ToString(), restoreDto);
    }

    [Fact]
    public async Task UpdateComponent_BaseFields_ReturnsOk()
    {
        // Arrange
        var component = _seededCPU;
        var originalName = component.Name;
        var originalManufacturer = component.Manufacturer;

        var dto = new UpdateCPUComponentDto
        {
            Name = "Updated Component Name",
            Manufacturer = "Updated Manufacturer"
        };

        // Act
        var response = await _componentsClient.UpdateComponent(component.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Refresh from database
        await _context.Entry(component).ReloadAsync();
        Assert.Equal("Updated Component Name", component.Name);
        Assert.Equal("Updated Manufacturer", component.Manufacturer);

        // Restore original values
        var restoreDto = new UpdateCPUComponentDto
        {
            Name = originalName,
            Manufacturer = originalManufacturer
        };
        await _componentsClient.UpdateComponent(component.Id.ToString(), restoreDto);
    }

    [Fact]
    public async Task UpdateComponent_NonExistentComponent_ReturnsNotFound()
    {
        // Arrange
        var dto = new UpdateCPUComponentDto { Name = "Test" };

        // Act
        var response = await _componentsClient.UpdateComponent(Guid.NewGuid().ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateComponent_AsNonAdmin_ReturnsForbidden()
    {
        // Arrange - Create a regular user client
        var regularUser = await _context.Users.FirstAsync(u => u.UserRole == UserRole.USER);
        var userHttpClient = await HttpClientFactory.Create(_factory, regularUser, password: "password123!");
        var userClient = new ComponentsControllerClient(userHttpClient);

        var dto = new UpdateCPUComponentDto { Name = "Unauthorized Update" };

        // Act
        var response = await userClient.UpdateComponent(_seededCPU.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    #endregion

    #region GetComponent Tests

    [Fact]
    public async Task GetComponent_AsRegularUser_ReturnsBasicInfo()
    {
        // Arrange - Create a regular user client
        var regularUser = await _context.Users.FirstAsync(u => u.UserRole == UserRole.USER);
        var userHttpClient = await HttpClientFactory.Create(_factory, regularUser, password: "password123!");
        var userClient = new ComponentsControllerClient(userHttpClient);

        // Act
        var response = await userClient.GetComponent(_seededCPU.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<CPUComponentResponseDto>(_jsonOptions);
        Assert.NotNull(content);
        Assert.Equal(_seededCPU.Name, content.Name);
        Assert.Equal(_seededCPU.Series, content.Series);
        Assert.Null(content.DatabaseEntryAt); // Regular user shouldn't see this
        Assert.Null(content.Note); // Regular user shouldn't see this
    }

    [Fact]
    public async Task GetComponent_AsAdmin_ReturnsFullDetails()
    {
        // Act
        var response = await _componentsClient.GetComponent(_seededCPU.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<CPUComponentResponseDto>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.Equal(_seededCPU.Name, content.Name);
        Assert.NotNull(content.DatabaseEntryAt); // Admin should see this
        Assert.NotNull(content.LastEditedAt); // Admin should see this
    }

    [Fact]
    public async Task GetComponent_NonExistentComponent_ReturnsNotFound()
    {
        // Act
        var response = await _componentsClient.GetComponent(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetComponents Tests

    [Fact]
    public async Task GetComponents_CPUWithoutFilters_ReturnsComponents()
    {
        // Arrange
        var dto = new GetCPUComponentDto();

        // Act
        var response = await _componentsClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<CPUComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.NotEmpty(content);
        Assert.All(content, c => Assert.Equal(ComponentType.CPU, c.Type));
    }

    [Fact]
    public async Task GetComponents_WithManufacturerFilter_ReturnsFilteredResults()
    {
        // Arrange
        var manufacturer = _seededCPU.Manufacturer;
        var dto = new GetCPUComponentDto
        {
            Manufacturer = new List<string> { manufacturer }
        };

        // Act
        var response = await _componentsClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<CPUComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.All(content, c => Assert.Equal(manufacturer, c.Manufacturer));
    }

    [Fact]
    public async Task GetComponents_StorageWithCapacityRange_ReturnsFilteredResults()
    {
        // Arrange
        var dto = new GetStorageComponentDto
        {
            CapacityStart = 500,
            CapacityEnd = 5000
        };

        // Act
        var response = await _componentsClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<StorageComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.All(content, c =>
        {
            Assert.True(c.Capacity >= 500);
            Assert.True(c.Capacity <= 5000);
        });
    }

    [Fact]
    public async Task GetComponents_WithPagination_ReturnsPaginatedResults()
    {
        // Arrange
        var dto = new GetCPUComponentDto
        {
            Paging = true,
            Page = 1,
            PageLength = 2
        };

        // Act
        var response = await _componentsClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<CPUComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.True(content.Count <= 2);
    }

    [Fact]
    public async Task GetComponents_WithOrderBy_ReturnsSortedResults()
    {
        // Arrange
        var dto = new GetCPUComponentDto
        {
            OrderBy = "Name",
            SortDirection = "asc"
        };

        // Act
        var response = await _componentsClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<CPUComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        if (content.Count > 1)
        {
            for (int i = 0; i < content.Count - 1; i++)
            {
                Assert.True(string.Compare(content[i].Name, content[i + 1].Name, StringComparison.Ordinal) <= 0);
            }
        }
    }

    [Fact]
    public async Task GetComponents_AsAdmin_ReturnsFullDetails()
    {
        // Arrange
        var dto = new GetCPUComponentDto();

        // Act
        var response = await _componentsClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<CPUComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.NotEmpty(content);
        // Admin should see additional fields
        Assert.All(content, c => Assert.NotNull(c.DatabaseEntryAt));
    }

    [Fact]
    public async Task GetComponents_AsRegularUser_ReturnsBasicInfo()
    {
        // Arrange - Create a regular user client
        var regularUser = await _context.Users.FirstAsync(u => u.UserRole == UserRole.USER);
        var userHttpClient = await HttpClientFactory.Create(_factory, regularUser, password: "password123!");
        var userClient = new ComponentsControllerClient(userHttpClient);

        var dto = new GetCPUComponentDto();

        // Act
        var response = await userClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<CPUComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.NotEmpty(content);
        // Regular users should NOT see additional fields
        Assert.All(content, c => Assert.Null(c.DatabaseEntryAt));
    }

    [Fact]
    public async Task GetComponents_CPUWithSocketTypeFilter_ReturnsFilteredResults()
    {
        // Arrange
        var socketType = _seededCPU.SocketType;
        var dto = new GetCPUComponentDto
        {
            SocketType = new List<string> { socketType }
        };

        // Act
        var response = await _componentsClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<CPUComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.All(content, c => Assert.Equal(socketType, c.SocketType));
    }

    [Fact]
    public async Task GetComponents_StorageWithNVMeFilter_ReturnsFilteredResults()
    {
        // Arrange
        var dto = new GetStorageComponentDto
        {
            HasNVMe = true
        };

        // Act
        var response = await _componentsClient.GetComponents(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var raw = await response.Content.ReadAsStringAsync();
        var content = JsonSerializer.Deserialize<List<StorageComponentResponseDto>>(raw, _jsonOptions);
        Assert.NotNull(content);
        Assert.All(content, c => Assert.True(c.HasNVMe));
    }

    #endregion

    #region DeleteComponent Tests

    [Fact]
    public async Task DeleteComponent_AsAdmin_ReturnsOk()
    {
        // Arrange - Create a new component to delete
        var createDto = new CreateStorageComponentDto
        {
            Name = "Component to Delete",
            Manufacturer = "Test",
            Type = ComponentType.STORAGE,
            Series = "Test Series",
            Capacity = 1000,
            DriveType = "SSD",
            FormFactor = "2.5\"",
            Interface = "SATA",
            HasNVMe = false
        };

        var createResponse = await _componentsClient.AddComponent(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createJsonDoc = JsonDocument.Parse(createContent);
        var componentId = Guid.Parse(createJsonDoc.RootElement.GetProperty("id").GetString()!);

        // Act
        var response = await _componentsClient.DeleteComponent(componentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deletedComponent = await _context.Components.FirstOrDefaultAsync(c => c.Id == componentId);
        Assert.Null(deletedComponent);
    }

    [Fact]
    public async Task DeleteComponent_AsNonAdmin_ReturnsForbidden()
    {
        // Arrange - Create a regular user client
        var regularUser = await _context.Users.FirstAsync(u => u.UserRole == UserRole.USER);
        var userHttpClient = await HttpClientFactory.Create(_factory, regularUser, password: "password123!");
        var userClient = new ComponentsControllerClient(userHttpClient);

        // Act
        var response = await userClient.DeleteComponent(_seededStorage.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteComponent_NonExistentComponent_ReturnsNotFound()
    {
        // Act
        var response = await _componentsClient.DeleteComponent(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion
}
