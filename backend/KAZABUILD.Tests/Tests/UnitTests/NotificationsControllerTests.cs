using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Users.Notification;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class NotificationsControllerTests : BaseIntegrationTest
{
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private HttpClient _client_other_user = null!;
    private NotificationsControllerClient _api_user_client = null!;
    private NotificationsControllerClient _api_admin_client = null!;
    private NotificationsControllerClient _api_other_user_client = null!;
    private User _user_regular = null!;
    private User _user_other = null!;
    private User _user_admin = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public NotificationsControllerTests(KazaWebApplicationFactory factory) : base(factory)
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

        _user_regular = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.USER);
        _user_other = await _context.Users.Where(u => u.UserRole == UserRole.USER && u.Id != _user_regular.Id).FirstOrDefaultAsync();
        _user_admin = await _context.Users.FirstOrDefaultAsync(u => u.UserRole == UserRole.ADMINISTRATOR);

        Assert.NotNull(_user_regular);
        Assert.NotNull(_user_other);
        Assert.NotNull(_user_admin);

        _client_user = await HttpClientFactory.Create(_factory, _user_regular);
        _client_admin = await HttpClientFactory.Create(_factory, _user_admin);
        _client_other_user = await HttpClientFactory.Create(_factory, _user_other);

        _api_user_client = new NotificationsControllerClient(_client_user);
        _api_admin_client = new NotificationsControllerClient(_client_admin);
        _api_other_user_client = new NotificationsControllerClient(_client_other_user);
    }

    [Fact]
    public async Task AddNotification_ForSelf_ShouldReturnOk()
    {
        // Arrange
        var dto = new CreateNotificationDto
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Test notification body",
            Title = "Test Notification",
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        // Act
        var response = await _api_user_client.AddNotification(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var createdNotification = await _context.Notifications.FirstOrDefaultAsync(
            n => n.UserId == _user_regular.Id && n.Title == "Test Notification");
        Assert.NotNull(createdNotification);
    }

    [Fact]
    public async Task AddNotification_ByAdminForOtherUser_ShouldReturnOk()
    {
        // Arrange
        var dto = new CreateNotificationDto
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.OFFER,
            Body = "Admin notification body",
            Title = "Admin Notification",
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        // Act
        var response = await _api_admin_client.AddNotification(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var createdNotification = await _context.Notifications.FirstOrDefaultAsync(
            n => n.UserId == _user_regular.Id && n.Title == "Admin Notification");
        Assert.NotNull(createdNotification);
    }

    [Fact]
    public async Task AddNotification_ForOtherUserByNonAdmin_ShouldReturnForbidden()
    {
        // Arrange
        var dto = new CreateNotificationDto
        {
            UserId = _user_other.Id,
            NotificationType = NotificationType.ADMIN,
            Body = "Unauthorized notification",
            Title = "Unauthorized",
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        // Act
        var response = await _api_user_client.AddNotification(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddNotification_WithNonExistentUser_ShouldReturnBadRequest()
    {
        // Arrange
        var dto = new CreateNotificationDto
        {
            UserId = Guid.NewGuid(),
            NotificationType = NotificationType.REMINDER,
            Body = "Test body",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false
        };

        // Act
        var response = await _api_admin_client.AddNotification(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetNotification_OwnNotification_ShouldReturnOk()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Test body",
            Title = "Test notification",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        // Act
        var response = await _api_user_client.GetNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var data = JsonSerializer.Deserialize<NotificationResponseDto>(
            await response.Content.ReadAsStringAsync(),
            _jsonSerializerOptions);
        Assert.NotNull(data);
        Assert.Equal(notification.Id, data.Id);
    }

    [Fact]
    public async Task GetNotification_OthersNotificationByNonAdmin_ShouldReturnForbidden()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_other.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Other user's notification",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        // Act
        var response = await _api_user_client.GetNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetNotification_OthersNotificationByAdmin_ShouldReturnOk()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "User's notification",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        // Act
        var response = await _api_admin_client.GetNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var data = JsonSerializer.Deserialize<NotificationResponseDto>(
            await response.Content.ReadAsStringAsync(),
            _jsonSerializerOptions);
        Assert.NotNull(data);
        Assert.NotNull(data.DatabaseEntryAt);
        Assert.NotNull(data.LastEditedAt);
    }

    [Fact]
    public async Task GetNotification_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetNotification(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateNotification_MarkAsRead_ShouldSucceed()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Unread notification",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        var updateDto = new UpdateNotificationDto
        {
            IsRead = true
        };

        // Act
        await _api_user_client.UpdateNotification(notification.Id.ToString(), updateDto);
        var response = await _api_user_client.GetNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var data = JsonSerializer.Deserialize<NotificationResponseDto>(
            await response.Content.ReadAsStringAsync(),
            _jsonSerializerOptions);
        Assert.NotNull(data);
        Assert.True(data.IsRead);
    }

    [Fact]
    public async Task UpdateNotification_OthersNotificationByNonAdmin_ShouldReturnForbidden()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_other.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Other's notification",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        var updateDto = new UpdateNotificationDto
        {
            IsRead = true
        };

        // Act
        var response = await _api_user_client.UpdateNotification(notification.Id.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateNotification_BodyByAdmin_ShouldSucceed()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Original body",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        var updateDto = new UpdateNotificationDto
        {
            Body = "Updated body by admin"
        };

        // Act
        await _api_admin_client.UpdateNotification(notification.Id.ToString(), updateDto);
        var response = await _api_admin_client.GetNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var data = JsonSerializer.Deserialize<NotificationResponseDto>(
            await response.Content.ReadAsStringAsync(),
            _jsonSerializerOptions);
        Assert.NotNull(data);
        Assert.Equal("Updated body by admin", data.Body);
    }

    [Fact]
    public async Task UpdateNotification_BodyByNonAdmin_ShouldNotUpdateBody()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Original body",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        var updateDto = new UpdateNotificationDto
        {
            Body = "Attempted update"
        };

        // Act
        await _api_user_client.UpdateNotification(notification.Id.ToString(), updateDto);
        var response = await _api_user_client.GetNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var data = JsonSerializer.Deserialize<NotificationResponseDto>(
            await response.Content.ReadAsStringAsync(),
            _jsonSerializerOptions);
        Assert.NotNull(data);
        Assert.Equal("Original body", data.Body);
    }

    [Fact]
    public async Task DeleteNotification_OwnNotification_ShouldSucceed()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "To be deleted",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        // Act
        await _api_user_client.DeleteNotification(notification.Id.ToString());
        var response = await _api_user_client.GetNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteNotification_OthersNotificationByNonAdmin_ShouldReturnForbidden()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_other.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Other's notification",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        // Act
        var response = await _api_user_client.DeleteNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteNotification_ByAdmin_ShouldSucceed()
    {
        // Arrange
        var notification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "To be deleted by admin",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        // Act
        await _api_admin_client.DeleteNotification(notification.Id.ToString());
        var response = await _api_admin_client.GetNotification(notification.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetNotifications_UserShouldSeeOnlyOwn()
    {
        // Arrange
        var notification1 = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "User's notification 1",
            Title = "Test 1",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        var notification2 = new Notification
        {
            UserId = _user_other.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Other user's notification",
            Title = "Test 2",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddRangeAsync(notification1, notification2);
        await _context.SaveChangesAsync();

        var getDto = new GetNotificationDto();

        // Act
        var response = await _api_user_client.GetNotifications(getDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var data = JsonSerializer.Deserialize<List<NotificationResponseDto>>(
            await response.Content.ReadAsStringAsync(),
            _jsonSerializerOptions);
        Assert.NotNull(data);
        Assert.All(data, n => Assert.Equal(_user_regular.Id, n.UserId));
    }

    [Fact]
    public async Task GetNotifications_AdminShouldSeeAll()
    {
        // Arrange
        var notification1 = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "User's notification",
            Title = "Test 1",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        var notification2 = new Notification
        {
            UserId = _user_other.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Other user's notification",
            Title = "Test 2",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddRangeAsync(notification1, notification2);
        await _context.SaveChangesAsync();

        var getDto = new GetNotificationDto();

        // Act
        var response = await _api_admin_client.GetNotifications(getDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var data = JsonSerializer.Deserialize<List<NotificationResponseDto>>(
            await response.Content.ReadAsStringAsync(),
            _jsonSerializerOptions);
        Assert.NotNull(data);
        Assert.True(data.Count >= 2);
    }

    [Fact]
    public async Task GetNotifications_FilterByIsRead_ShouldReturnOnlyUnread()
    {
        // Arrange
        var readNotification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Read notification",
            Title = "Read",
            SentAt = DateTime.UtcNow,
            IsRead = true,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        var unreadNotification = new Notification
        {
            UserId = _user_regular.Id,
            NotificationType = NotificationType.REMINDER,
            Body = "Unread notification",
            Title = "Unread",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        await _context.Notifications.AddRangeAsync(readNotification, unreadNotification);
        await _context.SaveChangesAsync();

        var getDto = new GetNotificationDto
        {
            IsRead = false
        };

        // Act
        var response = await _api_user_client.GetNotifications(getDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var data = JsonSerializer.Deserialize<List<NotificationResponseDto>>(
            await response.Content.ReadAsStringAsync(),
            _jsonSerializerOptions);
        Assert.NotNull(data);
        Assert.All(data, n => Assert.False(n.IsRead));
    }
}
