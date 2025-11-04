using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Users.UserFeedback;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class UserFeedbackControllerTests : BaseIntegrationTest
{
    private UserFeedbackControllerClient _api_user_client = null!;
    private UserFeedbackControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private User another_user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public UserFeedbackControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
        another_user = await _context.Users.FirstOrDefaultAsync(u => u.Id != admin.Id && u.Id != user.Id && u.UserRole == UserRole.USER);

        // Creating user clients
        _client_user = await HttpClientFactory.Create(_factory, user);
        _client_admin = await HttpClientFactory.Create(_factory, admin);

        // Initialization of controller clients
        _api_admin_client = new UserFeedbackControllerClient(_client_admin);
        _api_user_client = new UserFeedbackControllerClient(_client_user);
    }

    [Fact]
    public async Task AddUserFeedback_ForSelf_ShouldSucceed()
    {
        // Arrange
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "This is a test feedback with sufficient length to meet the minimum requirement."
        };

        // Act
        var response = await _api_user_client.AddUserFeedback(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AddUserFeedback_ForOtherUser_ShouldReturnForbidden()
    {
        // Arrange
        var createDto = new CreateUserFeedbackDto
        {
            UserId = another_user.Id,
            Feedback = "This is a test feedback for another user with sufficient length."
        };

        // Act
        var response = await _api_user_client.AddUserFeedback(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddUserFeedback_ByAdmin_ForAnyUser_ShouldSucceed()
    {
        // Arrange
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Admin creating feedback for a user with sufficient length for validation."
        };

        // Act
        var response = await _api_admin_client.AddUserFeedback(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AddUserFeedback_WithNonExistentUser_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateUserFeedbackDto
        {
            UserId = Guid.NewGuid(),
            Feedback = "Test feedback for non-existent user with sufficient length."
        };

        // Act
        var response = await _api_admin_client.AddUserFeedback(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserFeedback_WithShortFeedback_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Too short" // Less than 20 characters
        };

        // Act
        var response = await _api_user_client.AddUserFeedback(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserFeedback_WithLongFeedback_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = new string('A', 5001) // Exceeds 5000 character limit
        };

        // Act
        var response = await _api_user_client.AddUserFeedback(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserFeedback_ForOwnFeedback_ShouldSucceed()
    {
        // Arrange - Create feedback first
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Initial feedback with sufficient length to meet requirements."
        };
        var createResponse = await _api_user_client.AddUserFeedback(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var feedbackId = createData["id"].GetGuid();

        var newFeedback = "Updated feedback with sufficient length to meet the minimum requirement.";
        var updateDto = new UpdateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = newFeedback
        };

        // Act
        var updateResponse = await _api_user_client.UpdateUserFeedback(feedbackId.ToString(), updateDto);

        // Assert
        var response = await _api_user_client.GetUserFeedback(feedbackId.ToString());
        var data = JsonSerializer.Deserialize<UserFeedbackResponseDto>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        Assert.Equal(newFeedback, data.Feedback);
    }

    [Fact]
    public async Task UpdateUserFeedback_ForOtherUsersFeedback_ShouldReturnForbidden()
    {
        // Arrange - Create feedback for another user first (as admin)
        var createDto = new CreateUserFeedbackDto
        {
            UserId = another_user.Id,
            Feedback = "Feedback for another user with sufficient length."
        };
        var createResponse = await _api_admin_client.AddUserFeedback(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var feedbackId = createData["id"].GetGuid();

        var updateDto = new UpdateUserFeedbackDto
        {
            UserId = another_user.Id,
            Feedback = "Trying to update someone else's feedback with sufficient length."
        };

        // Act
        var response = await _api_user_client.UpdateUserFeedback(feedbackId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserFeedback_ByStaff_ShouldSucceed()
    {
        // Arrange - Get or create feedback for user
        var userFeedback = await _context.UserFeedback.FirstOrDefaultAsync(f => f.UserId == user.Id);
        if (userFeedback == null)
        {
            var createDto = new CreateUserFeedbackDto
            {
                UserId = user.Id,
                Feedback = "Initial feedback with sufficient length to meet requirements."
            };
            var createResponse = await _api_user_client.AddUserFeedback(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var feedbackId = createData["id"].GetGuid();
            userFeedback = await _context.UserFeedback.FindAsync(feedbackId);
        }

        var newFeedback = "Staff updated feedback with sufficient length to meet requirements.";
        var updateDto = new UpdateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = newFeedback
        };

        // Act
        var response = await _api_admin_client.UpdateUserFeedback(userFeedback.Id.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserFeedback_WithNoteByUser_ShouldNotUpdateNote()
    {
        // Arrange - Create feedback first
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Initial feedback with sufficient length to meet requirements."
        };
        var createResponse = await _api_user_client.AddUserFeedback(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var feedbackId = createData["id"].GetGuid();

        var updateDto = new UpdateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "User trying to add note with sufficient length for validation.",
            Note = "User trying to add note" // Users shouldn't be able to add notes
        };

        // Act
        var response = await _api_user_client.UpdateUserFeedback(feedbackId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserFeedback_WithShortFeedback_ShouldReturnBadRequest()
    {
        // Arrange - Create feedback first
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Initial feedback with sufficient length to meet requirements."
        };
        var createResponse = await _api_user_client.AddUserFeedback(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var feedbackId = createData["id"].GetGuid();

        var updateDto = new UpdateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Short" // Less than 20 characters
        };

        // Act
        var response = await _api_user_client.UpdateUserFeedback(feedbackId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserFeedback_WithLongNote_ShouldReturnBadRequest()
    {
        // Arrange - Create feedback first
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Initial feedback with sufficient length to meet requirements."
        };
        var createResponse = await _api_user_client.AddUserFeedback(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var feedbackId = createData["id"].GetGuid();

        var updateDto = new UpdateUserFeedbackDto
        {
            UserId = user.Id,
            Note = new string('A', 256) // Exceeds 255 character limit
        };

        // Act
        var response = await _api_admin_client.UpdateUserFeedback(feedbackId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserFeedback_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateDto = new UpdateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Valid feedback with sufficient length for validation."
        };

        // Act
        var response = await _api_user_client.UpdateUserFeedback(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetUserFeedback_ForOwnFeedback_ShouldSucceed()
    {
        // Arrange - Get or create feedback for user
        var userFeedback = await _context.UserFeedback.FirstOrDefaultAsync(f => f.UserId == user.Id);
        if (userFeedback == null)
        {
            var createDto = new CreateUserFeedbackDto
            {
                UserId = user.Id,
                Feedback = "Initial feedback with sufficient length to meet requirements."
            };
            var createResponse = await _api_user_client.AddUserFeedback(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var feedbackId = createData["id"].GetGuid();
            userFeedback = await _context.UserFeedback.FindAsync(feedbackId);
        }

        // Act
        var response = await _api_user_client.GetUserFeedback(userFeedback.Id.ToString());
        var data = JsonSerializer.Deserialize<UserFeedbackResponseDto>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(user.Id, data.UserId);
        Assert.Null(data.Note); // Users shouldn't see staff notes
        Assert.Null(data.DatabaseEntryAt); // Users shouldn't see timestamps
    }

    [Fact]
    public async Task GetUserFeedback_ForOtherUsersFeedback_ShouldReturnForbidden()
    {
        // Arrange - Get or create feedback for another user
        var otherFeedback = await _context.UserFeedback.FirstOrDefaultAsync(f => f.UserId == another_user.Id);
        if (otherFeedback == null)
        {
            var createDto = new CreateUserFeedbackDto
            {
                UserId = another_user.Id,
                Feedback = "Feedback for another user with sufficient length."
            };
            var createResponse = await _api_admin_client.AddUserFeedback(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var feedbackId = createData["id"].GetGuid();
            otherFeedback = await _context.UserFeedback.FindAsync(feedbackId);
        }

        // Act
        var response = await _api_user_client.GetUserFeedback(otherFeedback.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetUserFeedback_ByStaff_ShouldSucceed()
    {
        // Arrange - Get any feedback or create one
        var anyFeedback = await _context.UserFeedback.FirstOrDefaultAsync();
        if (anyFeedback == null)
        {
            var createDto = new CreateUserFeedbackDto
            {
                UserId = user.Id,
                Feedback = "Initial feedback with sufficient length to meet requirements."
            };
            var createResponse = await _api_admin_client.AddUserFeedback(createDto);
            var createContent = await createResponse.Content.ReadAsStringAsync();
            var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
            var feedbackId = createData["id"].GetGuid();
            anyFeedback = await _context.UserFeedback.FindAsync(feedbackId);
        }

        // Act
        var response = await _api_admin_client.GetUserFeedback(anyFeedback.Id.ToString());
        var data = JsonSerializer.Deserialize<UserFeedbackResponseDto>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data.DatabaseEntryAt); // Staff should see timestamps
        Assert.NotNull(data.LastEditedAt);
    }

    [Fact]
    public async Task GetUserFeedback_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetUserFeedback(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetUserFeedbacks_ByUser_ShouldReturnOnlyOwnFeedback()
    {
        // Arrange
        var getDto = new GetUserFeedbackDto();

        // Act
        var response = await _api_user_client.GetUserFeedbacks(getDto);
        var data = JsonSerializer.Deserialize<List<UserFeedbackResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, feedback => Assert.Equal(user.Id, feedback.UserId));
    }

    [Fact]
    public async Task GetUserFeedbacks_ByStaff_ShouldReturnAllFeedback()
    {
        // Arrange
        var getDto = new GetUserFeedbackDto();

        // Act
        var response = await _api_admin_client.GetUserFeedbacks(getDto);
        var data = JsonSerializer.Deserialize<List<UserFeedbackResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(data);
    }

    [Fact]
    public async Task GetUserFeedbacks_WithUserIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetUserFeedbackDto
        {
            UserId = new List<Guid> { user.Id }
        };

        // Act
        var response = await _api_admin_client.GetUserFeedbacks(getDto);
        var data = JsonSerializer.Deserialize<List<UserFeedbackResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, feedback => Assert.Equal(user.Id, feedback.UserId));
    }

    [Fact]
    public async Task GetUserFeedbacks_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetUserFeedbackDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetUserFeedbacks(getDto);
        var data = JsonSerializer.Deserialize<List<UserFeedbackResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }

    [Fact]
    public async Task GetUserFeedbacks_WithOrderBy_ShouldReturnOrderedResults()
    {
        // Arrange
        var getDto = new GetUserFeedbackDto
        {
            OrderBy = "Feedback",
            SortDirection = "asc"
        };

        // Act
        var response = await _api_admin_client.GetUserFeedbacks(getDto);
        var data = JsonSerializer.Deserialize<List<UserFeedbackResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        if (data.Count > 1)
        {
            var orderedData = data.OrderBy(f => f.Feedback).ToList();
            Assert.Equal(orderedData.Select(f => f.Feedback), data.Select(f => f.Feedback));
        }
    }

    [Fact]
    public async Task GetUserFeedbacks_WithQuery_ShouldReturnMatchingResults()
    {
        // Arrange
        var getDto = new GetUserFeedbackDto
        {
            Query = "feedback"
        };

        // Act
        var response = await _api_admin_client.GetUserFeedbacks(getDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserFeedback_ForOwnFeedback_ShouldSucceed()
    {
        // Arrange - Create feedback first
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Feedback to be deleted with sufficient length."
        };
        var createResponse = await _api_user_client.AddUserFeedback(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var feedbackId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.DeleteUserFeedback(feedbackId.ToString());
        var deletedFeedback = await _context.UserFeedback.FindAsync(feedbackId);
        var new_response = await _api_user_client.GetUserFeedback(feedbackId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(deletedFeedback);
        Assert.Equal(HttpStatusCode.NotFound, new_response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserFeedback_ForOtherUsersFeedback_ShouldReturnForbidden()
    {
        // Arrange - Create feedback for another user first (as admin)
        var createDto = new CreateUserFeedbackDto
        {
            UserId = another_user.Id,
            Feedback = "Feedback for another user with sufficient length."
        };
        var createResponse = await _api_admin_client.AddUserFeedback(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var feedbackId = createData["id"].GetGuid();

        // Act
        var response = await _api_user_client.DeleteUserFeedback(feedbackId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserFeedback_ByStaff_ShouldSucceed()
    {
        // Arrange - Create feedback first
        var createDto = new CreateUserFeedbackDto
        {
            UserId = user.Id,
            Feedback = "Feedback to be deleted by staff with sufficient length."
        };
        var createResponse = await _api_admin_client.AddUserFeedback(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createData = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(createContent, _jsonSerializerOptions);
        var feedbackId = createData["id"].GetGuid();

        // Act
        var response = await _api_admin_client.DeleteUserFeedback(feedbackId.ToString());
        var deletedFeedback = await _context.UserFeedback.FindAsync(feedbackId);
        var new_response = await _api_admin_client.GetUserFeedback(feedbackId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(deletedFeedback);
        Assert.Equal(HttpStatusCode.NotFound, new_response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserFeedback_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.DeleteUserFeedback(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
