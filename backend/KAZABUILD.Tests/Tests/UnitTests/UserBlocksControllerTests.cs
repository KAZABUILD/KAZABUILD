using System.Net;
using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Users.UserBlock;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests.Users;

[Collection("Sequential")]
public class UserBlocksControllerTests : BaseIntegrationTest
{
    private UserBlocksControllerClient _userBlocksClient = null!;
    private User _testUser1 = null!;
    private User _testUser2 = null!;
    private User _testUser3 = null!;
    private HttpClient _testUser1HttpClient = null!;
    private HttpClient _testUser2HttpClient = null!;

    public UserBlocksControllerTests(KazaWebApplicationFactory factory) : base(factory)
    {
    }

    public override async Task InitializeAsync()
    {
        await base.InitializeAsync();

        // Create test users
        _testUser1 = _context.Users.First(u => u.UserRole == UserRole.USER);
        _testUser2 = _context.Users.First(u => u.UserRole == UserRole.USER && u.Id != _testUser1.Id);

        // Create a third user for additional tests
        _testUser3 = new User
        {
            Email = "testuser3@userblocks.com",
            DisplayName = "Test User 3",
            Login = "testuser3block",
            UserRole = UserRole.USER,
            PasswordHash = _hasher.Hash("password123!"),
            RegisteredAt = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Users.Add(_testUser3);
        await _context.SaveChangesAsync();

        // Create HTTP clients for test users
        _testUser1HttpClient = await HttpClientFactory.Create(_factory, _testUser1, password: "password123!");
        _testUser2HttpClient = await HttpClientFactory.Create(_factory, _testUser2, password: "password123!");

        // Initialize clients
        _userBlocksClient = new UserBlocksControllerClient(_testUser1HttpClient);
    }

    #region AddUserBlock Tests

    [Fact]
    public async Task AddUserBlock_WithNonExistentUser_ReturnsBadRequest()
    {
        // Arrange
        var dto = new CreateUserBlockDto
        {
            UserId = _testUser1.Id,
            BlockedUserId = Guid.NewGuid() // Non-existent user
        };

        // Act
        var response = await _userBlocksClient.AddUserBlock(dto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserBlock_AsOtherUser_ReturnsForbidden()
    {
        // Arrange
        var dto = new CreateUserBlockDto
        {
            UserId = _testUser2.Id, // Trying to block as different user
            BlockedUserId = _testUser3.Id
        };

        // Act
        var response = await _userBlocksClient.AddUserBlock(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddUserBlock_DuplicateBlock_ReturnsConflict()
    {
        // Arrange - Create initial block
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var dto = new CreateUserBlockDto
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id
        };

        // Act
        var response = await _userBlocksClient.AddUserBlock(dto);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task AddUserBlock_AsStaff_CanBlockForOtherUser()
    {
        // Arrange
        var staffClient = new UserBlocksControllerClient(_superAdminHttpClient);
        var dto = new CreateUserBlockDto
        {
            UserId = _testUser2.Id,
            BlockedUserId = _testUser3.Id
        };

        // Act
        var response = await staffClient.AddUserBlock(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    #endregion

    #region UpdateUserBlock Tests

    [Fact]
    public async Task UpdateUserBlock_AsRegularUser_ReturnsForbidden()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var dto = new UpdateUserBlockDto
        {
            Note = "Trying to add note"
        };

        // Act
        var response = await _userBlocksClient.UpdateUserBlock(userBlock.Id.ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserBlock_NonExistentBlock_ReturnsNotFound()
    {
        // Arrange
        var staffClient = new UserBlocksControllerClient(_superAdminHttpClient);
        var dto = new UpdateUserBlockDto
        {
            Note = "Test note"
        };

        // Act
        var response = await staffClient.UpdateUserBlock(Guid.NewGuid().ToString(), dto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
    #endregion

    #region GetUserBlock Tests

    [Fact]
    public async Task GetUserBlock_AsSelf_ReturnsOk()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        // Act
        var response = await _userBlocksClient.GetUserBlock(userBlock.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<UserBlockResponseDto>();
        Assert.NotNull(content);
        Assert.Equal(userBlock.Id, content.Id);
        Assert.Null(content.DatabaseEntryAt); // Regular user shouldn't see this
    }

    [Fact]
    public async Task GetUserBlock_AsStaff_ReturnsFullDetails()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            Note = "Staff note",
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var staffClient = new UserBlocksControllerClient(_superAdminHttpClient);

        // Act
        var response = await staffClient.GetUserBlock(userBlock.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<UserBlockResponseDto>();
        Assert.NotNull(content);
        Assert.NotNull(content.DatabaseEntryAt); // Staff should see this
        Assert.NotNull(content.LastEditedAt);
        Assert.Equal("Staff note", content.Note);
    }

    [Fact]
    public async Task GetUserBlock_AsUnrelatedUser_ReturnsForbidden()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var user3HttpClient = await HttpClientFactory.Create(_factory, _testUser3, password: "password123!");
        var user3Client = new UserBlocksControllerClient(user3HttpClient);

        // Act
        var response = await user3Client.GetUserBlock(userBlock.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetUserBlock_NonExistentBlock_ReturnsNotFound()
    {
        // Act
        var response = await _userBlocksClient.GetUserBlock(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion

    #region GetUserBlocks Tests

    [Fact]
    public async Task GetUserBlocks_WithUserIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var staffClient = new UserBlocksControllerClient(_superAdminHttpClient);
        var dto = new GetUserBlockDto
        {
            UserId = new List<Guid> { _testUser1.Id }
        };

        // Act
        var response = await staffClient.GetUserBlocks(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserBlockResponseDto>>();
        Assert.NotNull(content);
        Assert.NotEmpty(content);
    }

    [Fact]
    public async Task GetUserBlocks_WithBlockedUserIdFilter_ReturnsFilteredResults()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var staffClient = new UserBlocksControllerClient(_superAdminHttpClient);
        var dto = new GetUserBlockDto
        {
            BlockedUserId = new List<Guid> { _testUser2.Id }
        };

        // Act
        var response = await staffClient.GetUserBlocks(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserBlockResponseDto>>();
        Assert.NotNull(content);
        Assert.NotEmpty(content);
    }

    [Fact]
    public async Task GetUserBlocks_WithPagination_ReturnsPaginatedResults()
    {
        // Arrange - Create multiple blocks
        for (int i = 0; i < 5; i++)
        {
            var user = new User
            {
                Email = $"blocked{i}@test.com",
                DisplayName = $"Blocked User {i}",
                Login = $"blocked{i}",
                UserRole = UserRole.USER,
                PasswordHash = _hasher.Hash("password123!"),
                RegisteredAt = DateTime.UtcNow,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            var userBlock = new UserBlock
            {
                UserId = _testUser1.Id,
                BlockedUserId = user.Id,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };
            _context.UserBlocks.Add(userBlock);
        }
        await _context.SaveChangesAsync();

        var dto = new GetUserBlockDto
        {
            Paging = true,
            Page = 1,
            PageLength = 2
        };

        // Act
        var response = await _userBlocksClient.GetUserBlocks(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserBlockResponseDto>>();
        Assert.NotNull(content);
        Assert.Equal(2, content.Count);
    }

    [Fact]
    public async Task GetUserBlocks_WithSearchQuery_ReturnsMatchingResults()
    {
        // Arrange
        var uniqueUser = new User
        {
            Email = "unicorn@test.com",
            DisplayName = "Unicorn User",
            Login = "unicornuser",
            UserRole = UserRole.USER,
            PasswordHash = _hasher.Hash("password123!"),
            RegisteredAt = DateTime.UtcNow,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.Users.Add(uniqueUser);
        await _context.SaveChangesAsync();

        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = uniqueUser.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var dto = new GetUserBlockDto { Query = "Unicorn" };

        // Act
        var response = await _userBlocksClient.GetUserBlocks(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserBlockResponseDto>>();
        Assert.NotNull(content);
        Assert.Single(content);
    }

    [Fact]
    public async Task GetUserBlocks_WithOrderBy_ReturnsSortedResults()
    {
        // Arrange
        var userBlock1 = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow.AddDays(-2),
            LastEditedAt = DateTime.UtcNow
        };

        var userBlock2 = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser3.Id,
            DatabaseEntryAt = DateTime.UtcNow.AddDays(-1),
            LastEditedAt = DateTime.UtcNow
        };

        _context.UserBlocks.AddRange(userBlock1, userBlock2);
        await _context.SaveChangesAsync();

        var dto = new GetUserBlockDto
        {
            OrderBy = "DatabaseEntryAt",
            SortDirection = "desc"
        };

        // Act
        var response = await _userBlocksClient.GetUserBlocks(dto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<UserBlockResponseDto>>();
        Assert.NotNull(content);
        Assert.True(content.Count >= 2);
    }

    #endregion

    #region DeleteUserBlock Tests

    [Fact]
    public async Task DeleteUserBlock_AsSelf_ReturnsOk()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        // Act
        var response = await _userBlocksClient.DeleteUserBlock(userBlock.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deletedBlock = await _context.UserBlocks.FirstOrDefaultAsync(ub => ub.Id == userBlock.Id);
        Assert.Null(deletedBlock);
    }

    [Fact]
    public async Task DeleteUserBlock_AsOtherUser_ReturnsForbidden()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var user2Client = new UserBlocksControllerClient(_testUser2HttpClient);

        // Act
        var response = await user2Client.DeleteUserBlock(userBlock.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserBlock_AsStaff_ReturnsOk()
    {
        // Arrange
        var userBlock = new UserBlock
        {
            UserId = _testUser1.Id,
            BlockedUserId = _testUser2.Id,
            DatabaseEntryAt = DateTime.UtcNow,
            LastEditedAt = DateTime.UtcNow
        };
        _context.UserBlocks.Add(userBlock);
        await _context.SaveChangesAsync();

        var staffClient = new UserBlocksControllerClient(_superAdminHttpClient);

        // Act
        var response = await staffClient.DeleteUserBlock(userBlock.Id.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var deletedBlock = await _context.UserBlocks.FirstOrDefaultAsync(ub => ub.Id == userBlock.Id);
        Assert.Null(deletedBlock);
    }

    [Fact]
    public async Task DeleteUserBlock_NonExistentBlock_ReturnsNotFound()
    {
        // Act
        var response = await _userBlocksClient.DeleteUserBlock(Guid.NewGuid().ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    #endregion
}
