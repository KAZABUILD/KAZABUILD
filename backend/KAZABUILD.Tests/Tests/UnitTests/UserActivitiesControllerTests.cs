using System.Net;
using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserActivity;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class UserActivitiesControllerTests : BaseIntegrationTest
{
    private UserActivitiesControllerClient _userActivitiesClient = null!;
    private User _testUser1 = null!;
    private User _testUser2 = null!;
    private HttpClient _testUser1HttpClient = null!;
    private Guid _testTargetId = Guid.NewGuid();

    public UserActivitiesControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        // Create test users
        _testUser1 = _context.Users.First(u => u.UserRole == UserRole.USER);
        _testUser2 = _context.Users.First(u => u.UserRole == UserRole.USER && u.Id != _testUser1.Id);

        await _context.SaveChangesAsync();

        // Create HTTP clients for test users
        _testUser1HttpClient = await HttpClientFactory.Create(_factory, _testUser1, password: "password123!");

        // Initialize clients
        _userActivitiesClient = new UserActivitiesControllerClient(_testUser1HttpClient);
    }

    #region AddUserActivity Tests

    [Fact]
    public async Task AddUserActivity_AsRegularUser_UsesCurrentTimestamp()
    {
        // Arrange
        var pastTimestamp = DateTime.UtcNow.AddDays(-5);
        var dto = new CreateUserActivityDto
        {
            ActivityType = "CLICK",
            TargetId = _testTargetId,
            Timestamp = pastTimestamp // Regular user provides past timestamp
        };

        // Act
        var response = await _userActivitiesClient.AddUserActivity(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Verify timestamp was overridden to current time (not the provided past time)
        var userActivity = await _context.UserActivities
            .FirstOrDefaultAsync(ua => ua.UserId == _testUser1.Id && ua.ActivityType == "CLICK");
        Assert.NotNull(userActivity);
        Assert.True((DateTime.UtcNow - userActivity.Timestamp).TotalMinutes < 1); // Should be within last minute
    }

    [Fact]
    public async Task AddUserActivity_AsAdmin_CanSetCustomTimestamp()
    {
        // Arrange
        var adminClient = new UserActivitiesControllerClient(_superAdminHttpClient);
        var pastTimestamp = DateTime.UtcNow.AddDays(-5);
        var dto = new CreateUserActivityDto
        {
            ActivityType = "ADMIN_ACTION",
            TargetId = _testTargetId,
            Timestamp = pastTimestamp
        };

        // Act
        var response = await adminClient.AddUserActivity(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Verify admin can set custom timestamp
        var userActivity = await _context.UserActivities
            .OrderByDescending(ua => ua.DatabaseEntryAt)
            .FirstOrDefaultAsync(ua => ua.ActivityType == "ADMIN_ACTION");
        Assert.NotNull(userActivity);
        Assert.Equal(pastTimestamp.Date, userActivity.Timestamp.Date);
    }

    [Fact]
    public async Task AddUserActivity_WithDifferentActivityTypes_ReturnsOk()
    {
        // Arrange & Act & Assert
        var activityTypes = new[] { "VIEW", "CLICK", "DOWNLOAD", "SHARE", "LIKE", "COMMENT" };

        foreach (var activityType in activityTypes)
        {
            var dto = new CreateUserActivityDto
            {
                ActivityType = activityType,
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow
            };

            var response = await _userActivitiesClient.AddUserActivity(dto);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        }

        // Verify all activities were created
        var activities = await _context.UserActivities
            .Where(ua => ua.UserId == _testUser1.Id)
            .ToListAsync();
        Assert.True(activities.Count >= activityTypes.Length);
    }

    #endregion

    #region UpdateUserActivity Tests

    [Fact]
    public async Task UpdateUserActivity_AsRegularUser_ReturnsForbidden()
    {
        // Arrange
        var userActivity = new UserActivity
        {
            UserId = _testUser1.Id,
            ActivityType = "VIEW",
            TargetId = _testTargetId,
            Timestamp = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserActivities.Add(userActivity);
        await _context.SaveChangesAsync();

        var dto = new UpdateUserActivityDto
        {
            Note = "Trying to add note"
        };

        // Act
        var response = await _userActivitiesClient.UpdateUserActivity(userActivity.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserActivity_NonExistentActivity_ReturnsNotFound()
    {
        // Arrange
        var adminClient = new UserActivitiesControllerClient(_superAdminHttpClient);
        var dto = new UpdateUserActivityDto
        {
            Note = "Test note"
        };

        // Act
        var response = await adminClient.UpdateUserActivity(Guid.NewGuid().ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetUserActivity Tests

    [Fact]
    public async Task GetUserActivity_AsUser_ReturnsOk()
    {
        // Arrange
        var userActivity = new UserActivity
        {
            UserId = _testUser1.Id,
            ActivityType = "VIEW",
            TargetId = _testTargetId,
            Timestamp = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserActivities.Add(userActivity);
        await _context.SaveChangesAsync();

        // Act
        var response = await _userActivitiesClient.GetUserActivity(userActivity.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<UserActivityResponseDto>();
        Assert.NotNull(content);
        Assert.Equal(userActivity.Id, content.Id);
        Assert.Equal("VIEW", content.ActivityType);
        Assert.Null(content.DatabaseEntryAt); // Regular user shouldn't see this
    }

    [Fact]
    public async Task GetUserActivity_AsAdmin_ReturnsFullDetails()
    {
        // Arrange
        var userActivity = new UserActivity
        {
            UserId = _testUser1.Id,
            ActivityType = "VIEW",
            TargetId = _testTargetId,
            Timestamp = DateTime.UtcNow,
            Note = "Admin note",
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserActivities.Add(userActivity);
        await _context.SaveChangesAsync();

        var adminClient = new UserActivitiesControllerClient(_superAdminHttpClient);

        // Act
        var response = await adminClient.GetUserActivity(userActivity.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<UserActivityResponseDto>();
        Assert.NotNull(content);
        Assert.NotNull(content.DatabaseEntryAt); // Admin should see this
        Assert.NotNull(content.LastEditedAt);
        Assert.Equal("Admin note", content.Note);
    }

    [Fact]
    public async Task GetUserActivity_NonExistentActivity_ReturnsNotFound()
    {
        // Act
        var response = await _userActivitiesClient.GetUserActivity(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetUserActivities Tests

    [Fact]
    public async Task GetUserActivities_WithNoFilters_ReturnsActivities()
    {
        // Arrange - Create multiple activities
        var activities = new[]
        {
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "CLICK",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            }
        };
        _context.UserActivities.AddRange(activities);
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto();

        // Act
        var response = await _userActivitiesClient.GetUserActivities(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserActivityResponseDto>>();
        Assert.NotNull(content);
        Assert.True(content.Count >= 2);
    }

    [Fact]
    public async Task GetUserActivities_WithUserIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var userActivity = new UserActivity
        {
            UserId = _testUser1.Id,
            ActivityType = "VIEW",
            TargetId = _testTargetId,
            Timestamp = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserActivities.Add(userActivity);
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto
        {
            UserId = new List<Guid> { _testUser1.Id }
        };

        // Act
        var response = await _userActivitiesClient.GetUserActivities(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserActivityResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, a => Assert.Equal(_testUser1.Id, a.UserId));
    }

    [Fact]
    public async Task GetUserActivities_WithActivityTypeFilter_ReturnsFilteredResults()
    {
        // Arrange
        var activities = new[]
        {
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "CLICK",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            }
        };
        _context.UserActivities.AddRange(activities);
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto
        {
            ActivityType = new List<string> { "VIEW" }
        };

        // Act
        var response = await _userActivitiesClient.GetUserActivities(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserActivityResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, a => Assert.Equal("VIEW", a.ActivityType));
    }

    [Fact]
    public async Task GetUserActivities_WithTargetIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var specificTargetId = Guid.NewGuid();
        var userActivity = new UserActivity
        {
            UserId = _testUser1.Id,
            ActivityType = "VIEW",
            TargetId = specificTargetId,
            Timestamp = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserActivities.Add(userActivity);
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto
        {
            TargetId = new List<Guid> { specificTargetId }
        };

        // Act
        var response = await _userActivitiesClient.GetUserActivities(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserActivityResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, a => Assert.Equal(specificTargetId, a.TargetId));
    }

    [Fact]
    public async Task GetUserActivities_WithTimestampRange_ReturnsFilteredResults()
    {
        // Arrange
        var now = DateTime.UtcNow;
        var activities = new[]
        {
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = now.AddDays(-5),
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = now.AddDays(-2),
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = now,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            }
        };
        _context.UserActivities.AddRange(activities);
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto
        {
            TimestampStart = now.AddDays(-3),
            TimestampEnd = now.AddDays(-1)
        };

        // Act
        var response = await _userActivitiesClient.GetUserActivities(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserActivityResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, a =>
        {
            Assert.True(a.Timestamp >= dto.TimestampStart);
            Assert.True(a.Timestamp <= dto.TimestampEnd);
        });
    }

    [Fact]
    public async Task GetUserActivities_WithPagination_ReturnsPaginatedResults()
    {
        // Arrange - Create multiple activities
        for (int i = 0; i < 5; i++)
        {
            var userActivity = new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = $"ACTION_{i}",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow.AddMinutes(-i),
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.UserActivities.Add(userActivity);
        }
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto
        {
            Paging = true,
            Page = 1,
            PageLength = 2
        };

        // Act
        var response = await _userActivitiesClient.GetUserActivities(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserActivityResponseDto>>();
        Assert.NotNull(content);
        Assert.Equal(2, content.Count);
    }

    [Fact]
    public async Task GetUserActivities_WithSearchQuery_ReturnsMatchingResults()
    {
        // Arrange
        var userActivity = new UserActivity
        {
            UserId = _testUser1.Id,
            ActivityType = "UNIQUE_UNICORN_ACTION",
            TargetId = Guid.NewGuid(),
            Timestamp = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserActivities.Add(userActivity);
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto { Query = "UNICORN" };

        // Act
        var response = await _userActivitiesClient.GetUserActivities(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserActivityResponseDto>>();
        Assert.NotNull(content);
        Assert.Single(content);
        Assert.Contains("UNICORN", content[0].ActivityType);
    }

    [Fact]
    public async Task GetUserActivities_WithOrderBy_ReturnsSortedResults()
    {
        // Arrange
        var activities = new[]
        {
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow.AddDays(-2),
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow.AddDays(-1),
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            }
        };
        _context.UserActivities.AddRange(activities);
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto
        {
            OrderBy = "Timestamp",
            SortDirection = "desc"
        };

        // Act
        var response = await _userActivitiesClient.GetUserActivities(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserActivityResponseDto>>();
        Assert.NotNull(content);
        Assert.True(content.Count >= 2);
        // Verify descending order
        for (int i = 0; i < content.Count - 1; i++)
        {
            Assert.True(content[i].Timestamp >= content[i + 1].Timestamp);
        }
    }

    #endregion

    #region GetUserActivitiesCount Tests

    [Fact]
    public async Task GetUserActivitiesCount_WithNoFilters_ReturnsCount()
    {
        // Arrange - Create multiple activities
        for (int i = 0; i < 3; i++)
        {
            var userActivity = new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.UserActivities.Add(userActivity);
        }
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto
        {
            UserId = new List<Guid> { _testUser1.Id }
        };

        // Act
        var response = await _userActivitiesClient.GetUserActivitiesCount(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var count = await response.Content.ReadFromJsonAsync<int>();
        Assert.True(count >= 3);
    }

    [Fact]
    public async Task GetUserActivitiesCount_WithFilters_ReturnsFilteredCount()
    {
        // Arrange
        var specificTargetId = Guid.NewGuid();
        var activities = new[]
        {
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = specificTargetId,
                Timestamp = DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            },
            new UserActivity
            {
                UserId = _testUser1.Id,
                ActivityType = "VIEW",
                TargetId = Guid.NewGuid(),
                Timestamp = DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            }
        };
        _context.UserActivities.AddRange(activities);
        await _context.SaveChangesAsync();

        var dto = new GetUserActivityDto
        {
            TargetId = new List<Guid> { specificTargetId }
        };

        // Act
        var response = await _userActivitiesClient.GetUserActivitiesCount(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var count = await response.Content.ReadFromJsonAsync<int>();
        Assert.True(count >= 1);
    }

    [Fact]
    public async Task GetUserActivitiesCount_CachesResult()
    {
        // Arrange
        var dto = new GetUserActivityDto
        {
            UserId = new List<Guid> { _testUser1.Id }
        };

        // Act - Call twice
        var response1 = await _userActivitiesClient.GetUserActivitiesCount(dto);
        var response2 = await _userActivitiesClient.GetUserActivitiesCount(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response1.StatusCode);
        Assert.Equal(HttpStatusCode.OK, response2.StatusCode);

        var count1 = await response1.Content.ReadFromJsonAsync<int>();
        var count2 = await response2.Content.ReadFromJsonAsync<int>();
        Assert.Equal(count1, count2);
    }

    #endregion

    #region DeleteUserActivity Tests

    [Fact]
    public async Task DeleteUserActivity_AsAdmin_ReturnsOk()
    {
        // Arrange
        var userActivity = new UserActivity
        {
            UserId = _testUser1.Id,
            ActivityType = "VIEW",
            TargetId = _testTargetId,
            Timestamp = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserActivities.Add(userActivity);
        await _context.SaveChangesAsync();

        var adminClient = new UserActivitiesControllerClient(_superAdminHttpClient);

        // Act
        var response = await adminClient.DeleteUserActivity(userActivity.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deletedActivity = await _context.UserActivities.FirstOrDefaultAsync(ua => ua.Id == userActivity.Id);
        Assert.Null(deletedActivity);
    }

    [Fact]
    public async Task DeleteUserActivity_AsRegularUser_ReturnsForbidden()
    {
        // Arrange
        var userActivity = new UserActivity
        {
            UserId = _testUser1.Id,
            ActivityType = "VIEW",
            TargetId = _testTargetId,
            Timestamp = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserActivities.Add(userActivity);
        await _context.SaveChangesAsync();

        // Act
        var response = await _userActivitiesClient.DeleteUserActivity(userActivity.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserActivity_NonExistentActivity_ReturnsNotFound()
    {
        // Arrange
        var adminClient = new UserActivitiesControllerClient(_superAdminHttpClient);

        // Act
        var response = await adminClient.DeleteUserActivity(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion
}
