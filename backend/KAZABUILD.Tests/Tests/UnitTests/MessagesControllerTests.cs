using System.Net;
using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.Message;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace KAZABUILD.Tests.Controllers.Users;


[Collection("Sequential")]
public class MessagesControllerTests : BaseIntegrationTest
{
    private MessagesControllerClient _messagesClient = null!;
    private User _testUser1 = null!;
    private User _testUser2 = null!;
    private HttpClient _testUser1HttpClient = null!;
    private HttpClient _testUser2HttpClient = null!;

    public MessagesControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
        _testUser2HttpClient = await HttpClientFactory.Create(_factory, _testUser2, password: "password123!");

        // Initialize clients
        _messagesClient = new MessagesControllerClient(_testUser1HttpClient);
    }

    #region AddMessage Tests

    [Fact]
    public async Task AddMessage_WithValidData_ReturnsOk()
    {
        // Arrange
        var dto = new CreateMessageDto
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Hello, this is a test message!",
            Title = "Test Message",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER
        };

        // Act
        var response = await _messagesClient.SendMessage(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        Assert.NotNull(content);

        // Parse response to get message ID
        var jsonDoc = System.Text.Json.JsonDocument.Parse(content);
        var messageId = Guid.Parse(jsonDoc.RootElement.GetProperty("id").GetString()!);

        // Verify message was created in database
        var message = await _context.Messages.FirstOrDefaultAsync(m => m.Id == messageId);
        Assert.NotNull(message);
        Assert.Equal(dto.Content, message.Content);
        Assert.Equal(dto.Title, message.Title);
        Assert.Equal(_testUser1.Id, message.SenderId);
        Assert.Equal(_testUser2.Id, message.ReceiverId);
    }

    [Fact]
    public async Task AddMessage_WithNonExistentReceiver_ReturnsBadRequest()
    {
        // Arrange
        var dto = new CreateMessageDto
        {
            SenderId = _testUser1.Id,
            ReceiverId = Guid.NewGuid(), // Non-existent user
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            MessageType = MessageType.USER
        };

        // Act
        var response = await _messagesClient.SendMessage(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddMessage_AsOtherUser_ReturnsForbidden()
    {
        // Arrange
        var dto = new CreateMessageDto
        {
            SenderId = _testUser2.Id, // Trying to send as different user
            ReceiverId = _testUser1.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            MessageType = MessageType.USER
        };

        // Act
        var response = await _messagesClient.SendMessage(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddMessage_AsAdmin_CanSendForOtherUser()
    {
        // Arrange
        var adminClient = new MessagesControllerClient(_superAdminHttpClient);
        var dto = new CreateMessageDto
        {
            SenderId = _testUser2.Id,
            ReceiverId = _testUser1.Id,
            Content = "Admin sending for another user",
            Title = "Admin Message",
            SentAt = DateTime.UtcNow,
            MessageType = MessageType.ADMIN
        };

        // Act
        var response = await adminClient.SendMessage(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AddMessage_WithReplyToParentMessage_ReturnsOk()
    {
        // Arrange - Create parent message first
        var parentDto = new CreateMessageDto
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Parent message",
            Title = "Parent",
            SentAt = DateTime.UtcNow,
            MessageType = MessageType.USER
        };
        var parentResponse = await _messagesClient.SendMessage(parentDto);
        var parentContent = await parentResponse.Content.ReadAsStringAsync();
        var parentJsonDoc = System.Text.Json.JsonDocument.Parse(parentContent);
        var parentMessageId = Guid.Parse(parentJsonDoc.RootElement.GetProperty("id").GetString()!);

        // Create reply message
        var replyDto = new CreateMessageDto
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "This is a reply",
            Title = "Reply",
            SentAt = DateTime.UtcNow,
            ParentMessageId = parentMessageId,
            MessageType = MessageType.USER
        };

        // Act
        var response = await _messagesClient.SendMessage(replyDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var replyContent = await response.Content.ReadAsStringAsync();
        var replyJsonDoc = System.Text.Json.JsonDocument.Parse(replyContent);
        var replyMessageId = Guid.Parse(replyJsonDoc.RootElement.GetProperty("id").GetString()!);

        var replyMessage = await _context.Messages.FirstOrDefaultAsync(m => m.Id == replyMessageId);
        Assert.NotNull(replyMessage);
        Assert.Equal(parentMessageId, replyMessage.ParentMessageId);
    }

    #endregion

    #region UpdateMessage Tests

    [Fact]
    public async Task UpdateMessage_MarkAsRead_ReturnsOk()
    {
        // Arrange - Create a message
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var user2Client = new MessagesControllerClient(_testUser2HttpClient);
        var dto = new UpdateMessageDto { IsRead = true };

        // Act
        var response = await user2Client.UpdateMessage(message.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var updatedMessage = await _context.Messages.FirstOrDefaultAsync(m => m.Id == message.Id);
        Assert.True(updatedMessage!.IsRead);
    }

    [Fact]
    public async Task UpdateMessage_AsNonReceiver_ReturnsForbidden()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var dto = new UpdateMessageDto { IsRead = true };

        // Act - Try to update as sender (not receiver)
        var response = await _messagesClient.UpdateMessage(message.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateMessage_ContentAsAdmin_ReturnsOk()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Original content",
            Title = "Original title",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var adminClient = new MessagesControllerClient(_superAdminHttpClient);
        var dto = new UpdateMessageDto
        {
            Content = "Updated content",
            Title = "Updated title"
        };

        // Act
        var response = await adminClient.UpdateMessage(message.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var updatedMessage = await _context.Messages.FirstOrDefaultAsync(m => m.Id == message.Id);
        Assert.Equal("Updated content", updatedMessage!.Content);
        Assert.Equal("Updated title", updatedMessage.Title);
    }

    [Fact]
    public async Task UpdateMessage_ContentAsRegularUser_OnlyUpdatesIsRead()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Original content",
            Title = "Original title",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var user2Client = new MessagesControllerClient(_testUser2HttpClient);
        var dto = new UpdateMessageDto
        {
            Content = "Attempted update",
            Title = "Attempted title update",
            IsRead = true
        };

        // Act
        var response = await user2Client.UpdateMessage(message.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var updatedMessage = await _context.Messages.FirstOrDefaultAsync(m => m.Id == message.Id);
        Assert.True(updatedMessage!.IsRead); // This should be updated
        Assert.Equal("Original content", updatedMessage.Content); // This should NOT be updated
        Assert.Equal("Original title", updatedMessage.Title); // This should NOT be updated
    }

    [Fact]
    public async Task UpdateMessage_NonExistentMessage_ReturnsNotFound()
    {
        // Arrange
        var dto = new UpdateMessageDto { IsRead = true };

        // Act
        var response = await _messagesClient.UpdateMessage(Guid.NewGuid().ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetMessage Tests

    [Fact]
    public async Task GetMessage_AsSender_ReturnsOk()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        // Act
        var response = await _messagesClient.GetMessage(message.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<MessageResponseDto>();
        Assert.NotNull(content);
        Assert.Equal(message.Id, content.Id);
        Assert.Equal(message.Content, content.Content);
        Assert.Null(content.DatabaseEntryAt); // Regular user shouldn't see this
    }

    [Fact]
    public async Task GetMessage_AsAdmin_ReturnsFullDetails()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow,
            Note = "Admin note"
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var adminClient = new MessagesControllerClient(_superAdminHttpClient);

        // Act
        var response = await adminClient.GetMessage(message.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<MessageResponseDto>();
        Assert.NotNull(content);
        Assert.NotNull(content.DatabaseEntryAt); // Admin should see this
        Assert.NotNull(content.LastEditedAt);
        Assert.Equal("Admin note", content.Note);
    }

    [Fact]
    public async Task GetMessage_AsUnrelatedUser_ReturnsForbidden()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        // Create a third user
        var testUser3 = new User
        {
            Email = "testuser3@messages.com",
            DisplayName = "Test User 3",
            UserRole = UserRole.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Users.Add(testUser3);
        await _context.SaveChangesAsync();

        var user3HttpClient = await HttpClientFactory.Create(_factory, testUser3, password: "password123!");
        var user3Client = new MessagesControllerClient(user3HttpClient);

        // Act
        var response = await user3Client.GetMessage(message.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetMessage_NonExistentMessage_ReturnsNotFound()
    {
        // Act
        var response = await _messagesClient.GetMessage(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetMessages Tests

    [Fact]
    public async Task GetMessages_AsUser_ReturnsOnlyOwnMessages()
    {
        // Arrange - Create multiple messages
        var message1 = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Message 1",
            Title = "Test 1",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        var message2 = new Message
        {
            SenderId = _testUser2.Id,
            ReceiverId = _testUser1.Id,
            Content = "Message 2",
            Title = "Test 2",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Messages.AddRange(message1, message2);
        await _context.SaveChangesAsync();

        var dto = new GetMessageDto();

        // Act
        var response = await _messagesClient.GetMessages(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<MessageResponseDto>>();
        Assert.NotNull(content);
        Assert.Single(content); // Should only see own sent messages
        Assert.All(content, m => Assert.Equal(_testUser1.Id, m.SenderId));
    }

    [Fact]
    public async Task GetMessages_WithSenderIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var message1 = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Message 1",
            Title = "Test 1",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Messages.Add(message1);
        await _context.SaveChangesAsync();

        var adminClient = new MessagesControllerClient(_superAdminHttpClient);
        var dto = new GetMessageDto
        {
            SenderId = new List<Guid> { _testUser1.Id }
        };

        // Act
        var response = await adminClient.GetMessages(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<MessageResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, m => Assert.Equal(_testUser1.Id, m.SenderId));
    }

    [Fact]
    public async Task GetMessages_WithIsReadFilter_ReturnsFilteredResults()
    {
        // Arrange
        var readMessage = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Read message",
            Title = "Read",
            SentAt = DateTime.UtcNow,
            IsRead = true,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        var unreadMessage = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Unread message",
            Title = "Unread",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Messages.AddRange(readMessage, unreadMessage);
        await _context.SaveChangesAsync();

        var dto = new GetMessageDto { IsRead = false };

        // Act
        var response = await _messagesClient.GetMessages(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<MessageResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, m => Assert.False(m.IsRead));
    }

    [Fact]
    public async Task GetMessages_WithPagination_ReturnsPaginatedResults()
    {
        // Arrange - Create multiple messages
        for (int i = 0; i < 5; i++)
        {
            var message = new Message
            {
                SenderId = _testUser1.Id,
                ReceiverId = _testUser2.Id,
                Content = $"Message {i}",
                Title = $"Test {i}",
                SentAt = DateTime.UtcNow.AddMinutes(-i),
                IsRead = false,
                MessageType = MessageType.USER,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.Messages.Add(message);
        }
        await _context.SaveChangesAsync();

        var dto = new GetMessageDto
        {
            Paging = true,
            Page = 1,
            PageLength = 2
        };

        // Act
        var response = await _messagesClient.GetMessages(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<MessageResponseDto>>();
        Assert.NotNull(content);
        Assert.Equal(2, content.Count);
    }

    [Fact]
    public async Task GetMessages_WithSearchQuery_ReturnsMatchingResults()
    {
        // Arrange
        var message1 = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "This contains the word unicorn",
            Title = "Unique",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        var message2 = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "This is a regular message",
            Title = "Regular",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Messages.AddRange(message1, message2);
        await _context.SaveChangesAsync();

        var dto = new GetMessageDto { Query = "unicorn" };

        // Act
        var response = await _messagesClient.GetMessages(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<MessageResponseDto>>();
        Assert.NotNull(content);
        Assert.Single(content);
        Assert.Contains("unicorn", content[0].Content);
    }

    [Fact]
    public async Task GetMessages_WithOrderBy_ReturnsSortedResults()
    {
        // Arrange
        var message1 = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Message A",
            Title = "Alpha",
            SentAt = DateTime.UtcNow.AddDays(-2),
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        var message2 = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Message B",
            Title = "Beta",
            SentAt = DateTime.UtcNow.AddDays(-1),
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };

        _context.Messages.AddRange(message1, message2);
        await _context.SaveChangesAsync();

        var dto = new GetMessageDto
        {
            OrderBy = "SentAt",
            SortDirection = "desc"
        };

        // Act
        var response = await _messagesClient.GetMessages(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<MessageResponseDto>>();
        Assert.NotNull(content);
        Assert.True(content[0].SentAt >= content[1].SentAt);
    }

    #endregion

    #region DeleteMessage Tests

    [Fact]
    public async Task DeleteMessage_AsSender_ReturnsOk()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        // Act
        var response = await _messagesClient.DeleteMessage(message.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deletedMessage = await _context.Messages.FirstOrDefaultAsync(m => m.Id == message.Id);
        Assert.Null(deletedMessage);
    }

    [Fact]
    public async Task DeleteMessage_AsReceiver_ReturnsForbidden()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var user2Client = new MessagesControllerClient(_testUser2HttpClient);

        // Act
        var response = await user2Client.DeleteMessage(message.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteMessage_AsAdmin_ReturnsOk()
    {
        // Arrange
        var message = new Message
        {
            SenderId = _testUser1.Id,
            ReceiverId = _testUser2.Id,
            Content = "Test message",
            Title = "Test",
            SentAt = DateTime.UtcNow,
            IsRead = false,
            MessageType = MessageType.USER,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var adminClient = new MessagesControllerClient(_superAdminHttpClient);

        // Act
        var response = await adminClient.DeleteMessage(message.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deletedMessage = await _context.Messages.FirstOrDefaultAsync(m => m.Id == message.Id);
        Assert.Null(deletedMessage);
    }

    [Fact]
    public async Task DeleteMessage_NonExistentMessage_ReturnsNotFound()
    {
        // Act
        var response = await _messagesClient.DeleteMessage(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion
}
