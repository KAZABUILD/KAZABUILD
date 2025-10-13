namespace KAZABUILD.Tests;

using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using KAZABUILD.Tests.Utils;
using Microsoft.AspNetCore.Mvc.Testing;

public class UserControllerTests
{
    private readonly KAZABUILDDBContext _context;
    private HttpClient _client;
    private readonly DbTestUtils _utils = new();

    private User admin = UserFactory.GenerateUser(role: UserRole.ADMINISTRATOR);
    private User user = UserFactory.GenerateUser(role: UserRole.USER);
    public UserControllerTests(WebApplicationFactory<API.Program> factory)
    {
        _context = _utils.SetContextInMemory(_context);
        _client = factory.CreateClient();
    }

    [Fact]
    public void UserWithLowerRankShouldntDeleteUserWithHigherRank()
    {
        //when
        //then
    }
}
