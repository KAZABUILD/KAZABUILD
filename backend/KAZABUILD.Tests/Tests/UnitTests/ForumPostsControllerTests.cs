using System.Net;
using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.ForumPost;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class ForumPostsControllerTests : BaseIntegrationTest
{
    private ForumPostsControllerClient _forumPostsClient = null!;
    private User _testUser1 = null!;
    private User _testUser2 = null!;
    private HttpClient _testUser1HttpClient = null!;
    private HttpClient _testUser2HttpClient = null!;
    private ForumPost _seededPost1 = null!;
    private ForumPost _seededPost2 = null!;
    private ForumPost _seededPost3 = null!;

    public ForumPostsControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        // Get test users from seeded data
        _testUser1 = await _context.Users.FirstAsync(u => u.UserRole == UserRole.USER);
        _testUser2 = await _context.Users.FirstAsync(u => u.UserRole == UserRole.USER && u.Id != _testUser1.Id);

        // Get seeded forum posts
        var posts = await _context.ForumPosts.ToListAsync();
        _seededPost1 = posts.FirstOrDefault(p => p.CreatorId == _testUser1.Id)
            ?? posts.First();
        _seededPost2 = posts.FirstOrDefault(p => p.CreatorId == _testUser2.Id && p.Id != _seededPost1.Id)
            ?? posts.Skip(1).First();
        _seededPost3 = posts.FirstOrDefault(p => p.Id != _seededPost1.Id && p.Id != _seededPost2.Id)
            ?? posts.Skip(2).First();

        // Create HTTP clients for test users
        _testUser1HttpClient = await HttpClientFactory.Create(_factory, _testUser1, password: "password123!");
        _testUser2HttpClient = await HttpClientFactory.Create(_factory, _testUser2, password: "password123!");

        // Initialize clients
        _forumPostsClient = new ForumPostsControllerClient(_testUser1HttpClient);
    }

    #region AddForumPost Tests

    [Fact]
    public async Task AddForumPost_WithValidData_ReturnsOk()
    {
        // Arrange
        var dto = new CreateForumPostDto
        {
            CreatorId = _testUser1.Id,
            Content = "This is a test forum post content!",
            Title = "Test Forum Post",
            Topic = "General Discussion",
            PostedAt = DateTime.UtcNow
        };

        // Act
        var response = await _forumPostsClient.AddForumPost(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        Assert.NotNull(content);

        // Parse response to get post ID
        var jsonDoc = System.Text.Json.JsonDocument.Parse(content);
        var postId = Guid.Parse(jsonDoc.RootElement.GetProperty("id").GetString()!);

        // Verify post was created in database
        var post = await _context.ForumPosts.FirstOrDefaultAsync(p => p.Id == postId);
        Assert.NotNull(post);
        Assert.Equal(dto.Content, post.Content);
        Assert.Equal(dto.Title, post.Title);
        Assert.Equal(dto.Topic, post.Topic);
        Assert.Equal(_testUser1.Id, post.CreatorId);
    }

    [Fact]
    public async Task AddForumPost_WithNonExistentCreator_ReturnsBadRequest()
    {
        // Arrange
        var dto = new CreateForumPostDto
        {
            CreatorId = Guid.NewGuid(), // Non-existent user
            Content = "Test content",
            Title = "Test Title",
            Topic = "Test Topic",
            PostedAt = DateTime.UtcNow
        };

        // Act
        var response = await _forumPostsClient.AddForumPost(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddForumPost_AsOtherUser_ReturnsForbidden()
    {
        // Arrange
        var dto = new CreateForumPostDto
        {
            CreatorId = _testUser2.Id, // Trying to post as different user
            Content = "Test content",
            Title = "Test Title",
            Topic = "Test Topic",
            PostedAt = DateTime.UtcNow
        };

        // Act
        var response = await _forumPostsClient.AddForumPost(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddForumPost_AsStaff_CanPostForOtherUser()
    {
        // Arrange
        var staffClient = new ForumPostsControllerClient(_superAdminHttpClient);
        var dto = new CreateForumPostDto
        {
            CreatorId = _testUser2.Id,
            Content = "Staff posting for another user",
            Title = "Staff Post",
            Topic = "Announcements",
            PostedAt = DateTime.UtcNow
        };

        // Act
        var response = await staffClient.AddForumPost(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    #endregion

    #region UpdateForumPost Tests

    [Fact]
    public async Task UpdateForumPost_AsCreator_ReturnsOk()
    {
        // Arrange - Use seeded post where testUser1 is the creator
        var post = await _context.ForumPosts.FirstAsync(p => p.CreatorId == _testUser1.Id);
        var originalContent = post.Content;
        var originalTitle = post.Title;

        var dto = new UpdateForumPostDto
        {
            Content = "Updated content by creator",
            Title = "Updated title by creator"
        };

        // Act
        var response = await _forumPostsClient.UpdateForumPost(post.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Refresh from database
        await _context.Entry(post).ReloadAsync();
        Assert.Equal("Updated content by creator", post.Content);
        Assert.Equal("Updated title by creator", post.Title);

        // Restore original values
        var restoreDto = new UpdateForumPostDto
        {
            Content = originalContent,
            Title = originalTitle
        };
        await _forumPostsClient.UpdateForumPost(post.Id.ToString(), restoreDto);
    }

    [Fact]
    public async Task UpdateForumPost_AsNonCreator_ReturnsForbidden()
    {
        // Arrange - Use seeded post where testUser2 is the creator
        var post = await _context.ForumPosts.FirstAsync(p => p.CreatorId == _testUser2.Id);

        var dto = new UpdateForumPostDto
        {
            Content = "Attempted update",
            Title = "Attempted title"
        };

        // Act - Try to update as testUser1 (not creator)
        var response = await _forumPostsClient.UpdateForumPost(post.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateForumPost_TopicAsStaff_ReturnsOk()
    {
        // Arrange - Use seeded post
        var post = _seededPost1;
        var originalTopic = post.Topic;
        var originalNote = post.Note;

        var staffClient = new ForumPostsControllerClient(_superAdminHttpClient);
        var dto = new UpdateForumPostDto
        {
            Topic = "Updated Topic by Staff",
            Note = "Staff note added"
        };

        // Act
        var response = await staffClient.UpdateForumPost(post.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Refresh from database
        await _context.Entry(post).ReloadAsync();
        Assert.Equal("Updated Topic by Staff", post.Topic);
        Assert.Equal("Staff note added", post.Note);

        // Restore original values
        var restoreDto = new UpdateForumPostDto
        {
            Topic = originalTopic,
            Note = originalNote
        };
        await staffClient.UpdateForumPost(post.Id.ToString(), restoreDto);
    }

    [Fact]
    public async Task UpdateForumPost_TopicAsRegularUser_DoesNotUpdateTopic()
    {
        // Arrange - Use seeded post where testUser1 is the creator
        var post = await _context.ForumPosts.FirstAsync(p => p.CreatorId == _testUser1.Id);
        var originalTopic = post.Topic;
        var originalContent = post.Content;

        var dto = new UpdateForumPostDto
        {
            Content = "Updated content",
            Topic = "Attempted topic change"
        };

        // Act
        var response = await _forumPostsClient.UpdateForumPost(post.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Refresh from database
        await _context.Entry(post).ReloadAsync();
        Assert.Equal("Updated content", post.Content); // This should be updated
        Assert.Equal(originalTopic, post.Topic); // This should NOT be updated

        // Restore original content
        var restoreDto = new UpdateForumPostDto { Content = originalContent };
        await _forumPostsClient.UpdateForumPost(post.Id.ToString(), restoreDto);
    }

    [Fact]
    public async Task UpdateForumPost_NonExistentPost_ReturnsNotFound()
    {
        // Arrange
        var dto = new UpdateForumPostDto { Content = "Test" };

        // Act
        var response = await _forumPostsClient.UpdateForumPost(Guid.NewGuid().ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetForumPost Tests

    [Fact]
    public async Task GetForumPost_AsRegularUser_ReturnsBasicInfo()
    {
        // Arrange - Use seeded post
        var post = _seededPost1;

        // Act
        var response = await _forumPostsClient.GetForumPost(post.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<ForumPostResponseDto>();
        Assert.NotNull(content);
        Assert.Equal(post.Id, content.Id);
        Assert.Equal(post.Content, content.Content);
        Assert.Equal(post.Title, content.Title);
        Assert.Equal(post.Topic, content.Topic);
        Assert.Null(content.DatabaseEntryAt); // Regular user shouldn't see this
        Assert.Null(content.Note); // Regular user shouldn't see this
    }

    [Fact]
    public async Task GetForumPost_AsStaff_ReturnsFullDetails()
    {
        // Arrange - Use seeded post
        var post = _seededPost1;

        var staffClient = new ForumPostsControllerClient(_superAdminHttpClient);

        // Act
        var response = await staffClient.GetForumPost(post.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<ForumPostResponseDto>();
        Assert.NotNull(content);
        Assert.NotNull(content.DatabaseEntryAt); // Staff should see this
        Assert.NotNull(content.LastEditedAt);
    }

    [Fact]
    public async Task GetForumPost_NonExistentPost_ReturnsNotFound()
    {
        // Act
        var response = await _forumPostsClient.GetForumPost(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetForumPosts Tests

    [Fact]
    public async Task GetForumPosts_WithoutFilters_ReturnsAllPosts()
    {
        // Arrange
        var dto = new GetForumPostDto();

        // Act
        var response = await _forumPostsClient.GetPosts(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<ForumPostResponseDto>>();
        Assert.NotNull(content);
        Assert.NotEmpty(content);
    }

    [Fact]
    public async Task GetForumPosts_WithTopicFilter_ReturnsFilteredResults()
    {
        // Arrange
        var post = await _context.ForumPosts.FirstAsync();
        var dto = new GetForumPostDto
        {
            Topic = new List<string> { post.Topic }
        };

        // Act
        var response = await _forumPostsClient.GetPosts(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<ForumPostResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, p => Assert.Equal(post.Topic, p.Topic));
    }

    [Fact]
    public async Task GetForumPosts_WithCreatorIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var dto = new GetForumPostDto
        {
            CreatorId = new List<Guid> { _testUser1.Id }
        };

        // Act
        var response = await _forumPostsClient.GetPosts(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<ForumPostResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, p => Assert.Equal(_testUser1.Id, p.CreatorId));
    }

    [Fact]
    public async Task GetForumPosts_WithDateRangeFilter_ReturnsFilteredResults()
    {
        // Arrange
        var now = DateTime.UtcNow;
        var dto = new GetForumPostDto
        {
            PostedAtStart = now.AddDays(-30),
            PostedAtEnd = now
        };

        // Act
        var response = await _forumPostsClient.GetPosts(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<ForumPostResponseDto>>();
        Assert.NotNull(content);
        Assert.All(content, p =>
        {
            Assert.True(p.PostedAt >= dto.PostedAtStart);
            Assert.True(p.PostedAt <= dto.PostedAtEnd);
        });
    }

    [Fact]
    public async Task GetForumPosts_WithSearchQuery_ReturnsMatchingResults()
    {
        // Arrange - Get a post and use part of its content as search query
        var samplePost = await _context.ForumPosts.FirstAsync();
        var searchTerm = samplePost.Title.Split(' ').First();

        var dto = new GetForumPostDto { Query = searchTerm };

        // Act
        var response = await _forumPostsClient.GetPosts(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<ForumPostResponseDto>>();
        Assert.NotNull(content);
        Assert.NotEmpty(content);
    }

    [Fact]
    public async Task GetForumPosts_AsStaff_ReturnsFullDetails()
    {
        // Arrange
        var staffClient = new ForumPostsControllerClient(_superAdminHttpClient);
        var dto = new GetForumPostDto();

        // Act
        var response = await staffClient.GetPosts(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<ForumPostResponseDto>>();
        Assert.NotNull(content);
        Assert.NotEmpty(content);
        // Staff should see additional fields
        Assert.All(content, p => Assert.NotNull(p.DatabaseEntryAt));
    }

    [Fact]
    public async Task GetForumPosts_AsRegularUser_ReturnsBasicInfo()
    {
        // Arrange
        var dto = new GetForumPostDto();

        // Act
        var response = await _forumPostsClient.GetPosts(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<ForumPostResponseDto>>();
        Assert.NotNull(content);
        Assert.NotEmpty(content);
        // Regular users should NOT see additional fields
        Assert.All(content, p => Assert.Null(p.DatabaseEntryAt));
    }

    #endregion

    #region DeleteForumPost Tests

    [Fact]
    public async Task DeleteForumPost_AsCreator_ReturnsOk()
    {
        // Arrange - Create a new post to delete
        var createDto = new CreateForumPostDto
        {
            CreatorId = _testUser1.Id,
            Content = "Post to be deleted",
            Title = "Delete Test",
            Topic = "Test Topic",
            PostedAt = DateTime.UtcNow
        };

        var createResponse = await _forumPostsClient.AddForumPost(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createJsonDoc = System.Text.Json.JsonDocument.Parse(createContent);
        var postId = Guid.Parse(createJsonDoc.RootElement.GetProperty("id").GetString()!);

        // Act
        var response = await _forumPostsClient.DeleteForumPost(postId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deletedPost = await _context.ForumPosts.FirstOrDefaultAsync(p => p.Id == postId);
        Assert.Null(deletedPost);
    }

    [Fact]
    public async Task DeleteForumPost_AsNonCreator_ReturnsForbidden()
    {
        // Arrange - Use seeded post where testUser2 is the creator
        var post = await _context.ForumPosts.FirstAsync(p => p.CreatorId == _testUser2.Id);

        // Act - Try to delete as testUser1 (not creator)
        var response = await _forumPostsClient.DeleteForumPost(post.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteForumPost_AsStaff_ReturnsOk()
    {
        // Arrange - Create a new post to delete
        var createDto = new CreateForumPostDto
        {
            CreatorId = _testUser1.Id,
            Content = "Post to be deleted by staff",
            Title = "Staff Delete Test",
            Topic = "Test Topic",
            PostedAt = DateTime.UtcNow
        };

        var createResponse = await _forumPostsClient.AddForumPost(createDto);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var createJsonDoc = System.Text.Json.JsonDocument.Parse(createContent);
        var postId = Guid.Parse(createJsonDoc.RootElement.GetProperty("id").GetString()!);

        var staffClient = new ForumPostsControllerClient(_superAdminHttpClient);

        // Act
        var response = await staffClient.DeleteForumPost(postId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deletedPost = await _context.ForumPosts.FirstOrDefaultAsync(p => p.Id == postId);
        Assert.Null(deletedPost);
    }

    [Fact]
    public async Task DeleteForumPost_NonExistentPost_ReturnsNotFound()
    {
        // Act
        var response = await _forumPostsClient.DeleteForumPost(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion
}
