using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Components.Color;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests.Components;

[Collection("Sequential")]
public class ColorControllerTests : BaseIntegrationTest
{
    private ColorsControllerClient _api_user_client = null!;
    private ColorsControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public ColorControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
        _api_admin_client = new ColorsControllerClient(_client_admin);
        _api_user_client = new ColorsControllerClient(_client_user);
    }

    [Fact]
    public async Task AddColor_ByUser_ShouldReturnForbidden()
    {
        // Arrange
        var createDto = new CreateColorDto
        {
            ColorCode = "#00FF00",
            ColorName = "Green"
        };

        // Act
        var response = await _api_user_client.AddColor(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddColor_WithInvalidHexCode_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateColorDto
        {
            ColorCode = "FF5733", // Missing # prefix
            ColorName = "Orange"
        };

        // Act
        var response = await _api_admin_client.AddColor(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddColor_WithInvalidHexCharacters_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateColorDto
        {
            ColorCode = "#GGGGGG", // Invalid hex characters
            ColorName = "Invalid Color"
        };

        // Act
        var response = await _api_admin_client.AddColor(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddColor_WithShortName_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateColorDto
        {
            ColorCode = "#FFFFFF",
            ColorName = "AB" // Too short (minimum 3 characters)
        };

        // Act
        var response = await _api_admin_client.AddColor(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddColor_WithLongName_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateColorDto
        {
            ColorCode = "#FFFFFF",
            ColorName = new string('A', 31) // Exceeds 30 character limit
        };

        // Act
        var response = await _api_admin_client.AddColor(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddColor_DuplicateColorCode_ShouldReturnConflict()
    {
        // Arrange
        var createDto = new CreateColorDto
        {
            ColorCode = "#123ABC",
            ColorName = "Unique Blue"
        };

        // Create first color
        await _api_admin_client.AddColor(createDto);

        // Try to create duplicate
        var duplicateDto = new CreateColorDto
        {
            ColorCode = "#123ABC",
            ColorName = "Another Blue"
        };

        // Act
        var response = await _api_admin_client.AddColor(duplicateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }


    [Fact]
    public async Task UpdateColor_WithNonExistentColorCode_ShouldReturnNotFound()
    {
        // Arrange
        var updateDto = new UpdateColorDto
        {
            ColorName = "Test Update"
        };

        // Act
        var response = await _api_admin_client.UpdateColor("#ZZZZZZ", updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetColor_WithNonExistentColorCode_ShouldReturnNotFound()
    {
        // Act
        var response = await _api_user_client.GetColor("#NONEXIST");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetColors_ByUser_ShouldSucceedWithLimitedInfo()
    {
        // Arrange
        var getDto = new GetColorDto();

        // Act
        var response = await _api_user_client.GetColors(getDto);
        var data = JsonSerializer.Deserialize<List<ColorResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
        Assert.All(data, color =>
        {
            Assert.NotNull(color.ColorCode);
            Assert.NotNull(color.ColorName);
            Assert.Null(color.DatabaseEntryAt); // Users shouldn't see timestamps
        });
    }

    [Fact]
    public async Task GetColors_ByAdmin_ShouldSucceedWithFullInfo()
    {
        // Arrange
        var getDto = new GetColorDto();

        // Act
        var response = await _api_admin_client.GetColors(getDto);
        var data = JsonSerializer.Deserialize<List<ColorResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
        Assert.All(data, color =>
        {
            Assert.NotNull(color.ColorCode);
            Assert.NotNull(color.ColorName);
            Assert.NotNull(color.DatabaseEntryAt); // Admin should see timestamps
        });
    }

    [Fact]
    public async Task GetColors_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetColorDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetColors(getDto);
        var data = JsonSerializer.Deserialize<List<ColorResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }

    [Fact]
    public async Task GetColors_WithOrderBy_ShouldReturnOrderedResults()
    {
        // Arrange
        var getDto = new GetColorDto
        {
            OrderBy = "ColorName",
            SortDirection = "asc"
        };

        // Act
        var response = await _api_admin_client.GetColors(getDto);
        var data = JsonSerializer.Deserialize<List<ColorResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        if (data.Count > 1)
        {
            var orderedData = data.OrderBy(c => c.ColorName).ToList();
            Assert.Equal(orderedData.Select(c => c.ColorName), data.Select(c => c.ColorName));
        }
    }

    [Fact]
    public async Task DeleteColor_WithNonExistentColorCode_ShouldReturnNotFound()
    {
        // Act
        var response = await _api_admin_client.DeleteColor("#NOCOLOR");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetColors_WithDescendingOrder_ShouldReturnCorrectOrder()
    {
        // Arrange
        var getDto = new GetColorDto
        {
            OrderBy = "ColorName",
            SortDirection = "desc"
        };

        // Act
        var response = await _api_admin_client.GetColors(getDto);
        var data = JsonSerializer.Deserialize<List<ColorResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        if (data.Count > 1)
        {
            var orderedData = data.OrderByDescending(c => c.ColorName).ToList();
            Assert.Equal(orderedData.Select(c => c.ColorName), data.Select(c => c.ColorName));
        }
    }
}
