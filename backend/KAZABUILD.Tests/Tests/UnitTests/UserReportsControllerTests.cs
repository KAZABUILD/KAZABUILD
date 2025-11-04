using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using KAZABUILD.Application.DTOs.Users.UserReport;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Tests;

[Collection("Sequential")]
public class UserReportControllerTests : BaseIntegrationTest
{
    private UserReportsControllerClient _api_user_client = null!;
    private UserReportsControllerClient _api_admin_client = null!;
    private HttpClient _client_user = null!;
    private HttpClient _client_admin = null!;
    private User admin = null!;
    private User user = null!;
    private User another_user = null!;
    private readonly JsonSerializerOptions _jsonSerializerOptions;

    public UserReportControllerTests(KazaWebApplicationFactory factory) : base(factory)
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
        _api_admin_client = new UserReportsControllerClient(_client_admin);
        _api_user_client = new UserReportsControllerClient(_client_user);
    }

    [Fact]
    public async Task AddUserReport_ForOtherUser_ShouldReturnForbidden()
    {
        // Arrange
        var reportedUser = await _context.Users.FirstOrDefaultAsync(u => u.Id != user.Id && u.Id != another_user.Id);
        var createDto = new CreateUserReportDto
        {
            UserId = another_user.Id,
            Reason = "Spam",
            Details = "This user is posting spam content everywhere.",
            TargetType = ReportTargetType.USER,
            TargetId = reportedUser.Id
        };

        // Act
        var response = await _api_user_client.AddUserReport(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AddUserReport_WithNonExistentUser_ShouldReturnBadRequest()
    {
        // Arrange
        var reportedUser = await _context.Users.FirstOrDefaultAsync(u => u.Id != user.Id);
        var createDto = new CreateUserReportDto
        {
            UserId = Guid.NewGuid(), // Non-existent user
            Reason = "Test",
            Details = "Test details for non-existent user.",
            TargetType = ReportTargetType.USER,
            TargetId = reportedUser.Id
        };

        // Act
        var response = await _api_admin_client.AddUserReport(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserReport_WithNonExistentTarget_ShouldReturnBadRequest()
    {
        // Arrange
        var createDto = new CreateUserReportDto
        {
            UserId = user.Id,
            Reason = "Inappropriate",
            Details = "This content is inappropriate for the platform.",
            TargetType = ReportTargetType.USER,
            TargetId = Guid.NewGuid() // Non-existent target
        };

        // Act
        var response = await _api_user_client.AddUserReport(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserReport_WithShortReason_ShouldReturnBadRequest()
    {
        // Arrange
        var reportedUser = await _context.Users.FirstOrDefaultAsync(u => u.Id != user.Id);
        var createDto = new CreateUserReportDto
        {
            UserId = user.Id,
            Reason = "Ab", // Too short (minimum 3 characters)
            Details = "Valid details with enough characters.",
            TargetType = ReportTargetType.USER,
            TargetId = reportedUser.Id
        };

        // Act
        var response = await _api_user_client.AddUserReport(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AddUserReport_WithShortDetails_ShouldReturnBadRequest()
    {
        // Arrange
        var reportedUser = await _context.Users.FirstOrDefaultAsync(u => u.Id != user.Id);
        var createDto = new CreateUserReportDto
        {
            UserId = user.Id,
            Reason = "Valid Reason",
            Details = "Short", // Too short (minimum 10 characters)
            TargetType = ReportTargetType.USER,
            TargetId = reportedUser.Id
        };

        // Act
        var response = await _api_user_client.AddUserReport(createDto);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateUserReport_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateDto = new UpdateUserReportDto
        {
            Reason = "Valid Reason"
        };

        // Act
        var response = await _api_user_client.UpdateUserReport(nonExistentId.ToString(), updateDto);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetUserReport_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_user_client.GetUserReport(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetUserReports_ByUser_ShouldReturnOnlyOwnReports()
    {
        // Arrange
        var getDto = new GetUserReportDto();

        // Act
        var response = await _api_user_client.GetUserReports(getDto);
        var data = JsonSerializer.Deserialize<List<UserReportResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, report => Assert.Equal(user.Id, report.UserId));
    }

    [Fact]
    public async Task GetUserReports_WithUserIdFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetUserReportDto
        {
            UserId = new List<Guid> { user.Id }
        };

        // Act
        var response = await _api_admin_client.GetUserReports(getDto);
        var data = JsonSerializer.Deserialize<List<UserReportResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, report => Assert.Equal(user.Id, report.UserId));
    }

    [Fact]
    public async Task GetUserReports_WithTargetTypeFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetUserReportDto
        {
            TargetType = new List<ReportTargetType> { ReportTargetType.USER }
        };

        // Act
        var response = await _api_admin_client.GetUserReports(getDto);
        var data = JsonSerializer.Deserialize<List<UserReportResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, report => Assert.Equal(ReportTargetType.USER, report.TargetType));
    }

    [Fact]
    public async Task GetUserReports_WithReasonFilter_ShouldReturnFilteredResults()
    {
        // Arrange
        var getDto = new GetUserReportDto
        {
            Reason = new List<string> { "Harassment" }
        };

        // Act
        var response = await _api_admin_client.GetUserReports(getDto);
        var data = JsonSerializer.Deserialize<List<UserReportResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.All(data, report => Assert.Equal("Harassment", report.Reason));
    }

    [Fact]
    public async Task GetUserReports_WithPaging_ShouldReturnPagedResults()
    {
        // Arrange
        var getDto = new GetUserReportDto
        {
            Paging = true,
            Page = 1,
            PageLength = 5
        };

        // Act
        var response = await _api_admin_client.GetUserReports(getDto);
        var data = JsonSerializer.Deserialize<List<UserReportResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.True(data.Count <= 5);
    }

    [Fact]
    public async Task GetUserReports_WithOrderBy_ShouldReturnOrderedResults()
    {
        // Arrange
        var getDto = new GetUserReportDto
        {
            OrderBy = "Reason",
            SortDirection = "asc"
        };

        // Act
        var response = await _api_admin_client.GetUserReports(getDto);
        var data = JsonSerializer.Deserialize<List<UserReportResponseDto>>(response.Content.ReadAsStringAsync().Result, _jsonSerializerOptions);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var orderedData = data.OrderBy(r => r.Reason).ToList();
        Assert.Equal(orderedData.Select(r => r.Reason), data.Select(r => r.Reason));
    }

    [Fact]
    public async Task GetUserReports_WithQuery_ShouldReturnMatchingResults()
    {
        // Arrange
        var getDto = new GetUserReportDto
        {
            Query = "harassment"
        };

        // Act
        var response = await _api_admin_client.GetUserReports(getDto);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task DeleteUserReport_WithNonExistentId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _api_admin_client.DeleteUserReport(nonExistentId.ToString());

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
