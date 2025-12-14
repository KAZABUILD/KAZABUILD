using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Builds.Tag;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests.Builds;

[Collection("Sequential")]
public class TagsControllerTests : BaseIntegrationTest
{
    private TagsControllerClient _api_user_client = null!;
    private TagsControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public TagsControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
        _api_admin_client = new TagsControllerClient(_client_admin);
        _api_user_client = new TagsControllerClient(_client_user);
    }

    [Fact]
    public async Task AddTag_ByUser_ShouldReturnForbidden()
    {
        // Arrange
        var createDto = new CreateTagDto
        {
            Name = "Workstation",
            Description = "Tags for workstation builds"
        };

        // Act
        var response = await _api_user_client.AddTag(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddTag_WithShortName_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateTagDto
        {
            Name = "AB", // Too short (minimum 3 characters)
            Description = "Valid description"
        };

        // Act
        var response = await _api_admin_client.AddTag(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddTag_WithLongName_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateTagDto
        {
            Name = new string('A', 51), // Exceeds 50 character limit
            Description = "Valid description"
        };

        // Act
        var response = await _api_admin_client.AddTag(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddTag_WithLongDescription_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateTagDto
        {
            Name = "Valid Name",
            Description = new string('A', 501) // Exceeds 500 character limit
        };

        // Act
        var response = await _api_admin_client.AddTag(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddTag_DuplicateName_ShouldReturnConflict()
    {
        // Arrange
        var createDto = new CreateTagDto
        {
            Name = "Unique Tag Name",
            Description = "First tag with this name"
        };

        // Create first tag
        await _api_admin_client.AddTag(createDto);

        // Try to create duplicate
        var duplicateDto = new CreateTagDto
        {
            Name = "Unique Tag Name",
            Description = "Attempting to create duplicate"
        };

        // Act
        var response = await _api_admin_client.AddTag(duplicateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task UpdateTag_ByUser_ShouldReturnForbidden()
    {
        // Arrange - Get any existing tag
        var tag = await _context.Tags.FirstOrDefaultAsync();
        if (tag == null)
        {
            var createDto = new CreateTagDto
            {
                Name = "Test Tag",
                Description = "Test description"
            };
            var createResponse = await _api_admin_client.AddTag(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var tagId = createData["id"].GetGuid();
            tag = await _context.Tags.FindAsync(tagId);
        }

        var updateDto = new UpdateTagDto
        {
            Name = "Trying to Update"
        };

        // Act
        var response = await _api_user_client.UpdateTag(tag.Id.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateTag_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateDto = new UpdateTagDto
        {
            Name = "Test Update"
        };

        // Act
        var response = await _api_admin_client.UpdateTag(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetTag_ByUser_ShouldSucceedWithLimitedInfo()
    {
        // Arrange - Get or create a tag
        var tag = await _context.Tags.FirstOrDefaultAsync();
        if (tag == null)
        {
            var createDto = new CreateTagDto
            {
                Name = "Test Tag",
                Description = "Test description"
            };
            var createResponse = await _api_admin_client.AddTag(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var tagId = createData["id"].GetGuid();
            tag = await _context.Tags.FindAsync(tagId);
        }

        // Act
        var response = await _api_user_client.GetTag(tag.Id.ToString());
        var data = JsonSerializer.Deserialize<TagResponseDto>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data.Name);
        Assert.NotNull(data.Description);
        Assert.Null(data.Note); // Users shouldn't see admin notes
        Assert.Null(data.DatabaseEntryAt); // Users shouldn't see timestamps
    }

    [Fact]
    public async Task GetTag_ByAdmin_ShouldSucceedWithFullInfo()
    {
        // Arrange - Get or create a tag
        var tag = await _context.Tags.FirstOrDefaultAsync();
        if (tag == null)
        {
            var createDto = new CreateTagDto
            {
                Name = "Test Tag",
                Description = "Test description"
            };
            var createResponse = await _api_admin_client.AddTag(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var tagId = createData["id"].GetGuid();
            tag = await _context.Tags.FindAsync(tagId);
        }

        // Act
        var response = await _api_admin_client.GetTag(tag.Id.ToString());
        var data = JsonSerializer.Deserialize<TagResponseDto>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data.Name);
        Assert.NotNull(data.Description);
        Assert.NotNull(data.DatabaseEntryAt); // Admin should see timestamps
        Assert.NotNull(data.LastEditedAt);
    }

    [Fact]
    public async Task GetTag_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetTag(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetTags_ByUser_ShouldSucceedWithLimitedInfo()
    {
        // Arrange
        var getDto = new GetTagDto();

        // Act
        var response = await _api_user_client.GetTags(getDto);
        var data = JsonSerializer.Deserialize<List<TagResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
        Assert.All(data, tag =>
        {
            Assert.NotNull(tag.Name);
            Assert.NotNull(tag.Description);
            Assert.Null(tag.DatabaseEntryAt); // Users shouldn't see timestamps
        });
    }

    [Fact]
    public async Task GetTags_ByAdmin_ShouldSucceedWithFullInfo()
    {
        // Arrange
        var getDto = new GetTagDto();

        // Act
        var response = await _api_admin_client.GetTags(getDto);
        var data = JsonSerializer.Deserialize<List<TagResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
        Assert.All(data, tag =>
        {
            Assert.NotNull(tag.Name);
            Assert.NotNull(tag.Description);
            Assert.NotNull(tag.DatabaseEntryAt); // Admin should see timestamps
        });
    }

    [Fact]
    public async Task GetTags_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetTagDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetTags(getDto);
        var data = JsonSerializer.Deserialize<List<TagResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }

    [Fact]
    public async Task GetTags_WithOrderBy_ShouldReturnOrderedResults()
    {
        // Arrange
        var getDto = new GetTagDto
        {
            OrderBy = "Name",
            SortDirection = "asc"
        };

        // Act
        var response = await _api_admin_client.GetTags(getDto);
        var data = JsonSerializer.Deserialize<List<TagResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        if (data.Count > 1)
        {
            var orderedData = data.OrderBy(t => t.Name).ToList();
            Assert.Equal(orderedData.Select(t => t.Name), data.Select(t => t.Name));
        }
    }

    [Fact]
    public async Task DeleteTag_ByUser_ShouldReturnForbidden()
    {
        // Arrange - Get or create a tag
        var tag = await _context.Tags.FirstOrDefaultAsync();
        if (tag == null)
        {
            var createDto = new CreateTagDto
            {
                Name = "Test Tag",
                Description = "Test description"
            };
            var createResponse = await _api_admin_client.AddTag(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var tagId = createData["id"].GetGuid();
            tag = await _context.Tags.FindAsync(tagId);
        }

        // Act
        var response = await _api_user_client.DeleteTag(tag.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteTag_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_admin_client.DeleteTag(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetTags_WithDescendingOrder_ShouldReturnCorrectOrder()
    {
        // Arrange
        var getDto = new GetTagDto
        {
            OrderBy = "Name",
            SortDirection = "desc"
        };

        // Act
        var response = await _api_admin_client.GetTags(getDto);
        var data = JsonSerializer.Deserialize<List<TagResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        if (data.Count > 1)
        {
            var orderedData = data.OrderByDescending(t => t.Name).ToList();
            Assert.Equal(orderedData.Select(t => t.Name), data.Select(t => t.Name));
        }
    }

    [Fact]
    public async Task GetTags_WithMultiplePagesValidation()
    {
        // Arrange - Ensure we have enough tags
        for (int i = 0; i < 10; i++)
        {
            var createDto = new CreateTagDto
            {
                Name = $"Paging Test Tag {i}",
                Description = $"Description {i}"
            };
            await _api_admin_client.AddTag(createDto);
        }

        var getDto1 = new GetTagDto
        {
            Paging = true,
            Page = 1,
            PageLength = 3
        };

        var getDto2 = new GetTagDto
        {
            Paging = true,
            Page = 2,
            PageLength = 3
        };

        // Act
        var response1 = await _api_admin_client.GetTags(getDto1);
        var data1 = JsonSerializer.Deserialize<List<TagResponseDto>>(response1.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        var response2 = await _api_admin_client.GetTags(getDto2);
        var data2 = JsonSerializer.Deserialize<List<TagResponseDto>>(response2.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response1.StatusCode);
        Assert.Equal(HttpStatusCode.OK, response2.StatusCode);
        Assert.True(data1.Count <= 3);
        Assert.True(data2.Count <= 3);
        // Ensure different pages return different results
        if (data1.Any() && data2.Any())
        {
            Assert.NotEqual(data1.First().Name, data2.First().Name);
        }
    }
}
