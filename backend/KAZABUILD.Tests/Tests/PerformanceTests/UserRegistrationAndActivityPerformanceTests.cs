using KAZABUILD.Application.DTOs.Users.User;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;

namespace KAZABUILD.Tests.Tests.PerformanceTests;

[Collection("Sequential")]
public class UserRegistrationAndActivityPerformanceTests : BasePerformanceTest
{
    private UsersControllerClient _usersControllerClient = null!;
    private AuthControllerClient _authControllerClient = null!;
    private const string DefaultPassword = "password123!";
    private List<CreateUserDto> _createdUsers = new();
    private List<HttpClient> _userClients = new();
    private int _activityLevel;

    private CreateUserDto? _admin_user;
    private CreateUserDto? _user_user;
    private CreateUserDto? _user2_user;
    private CreateUserDto? _user3_user;
    private CreateUserDto? _banned_user;
    private CreateUserDto? _unverified_user;

    public UserRegistrationAndActivityPerformanceTests()
    {
        CreateUsers();
        SetActivityLevel();
        Simulate();
    }
    public async void CreateUsers()
    {
        _admin_user = UserFactory.GenerateUserCreateDto(role: UserRole.ADMINISTRATOR, rawPassword: DefaultPassword);
        _user_user = UserFactory.GenerateUserCreateDto(role: UserRole.USER, rawPassword: DefaultPassword);
        _user2_user = UserFactory.GenerateUserCreateDto(role: UserRole.USER, rawPassword: DefaultPassword);
        _user3_user = UserFactory.GenerateUserCreateDto(role: UserRole.USER, rawPassword: DefaultPassword);
        _banned_user = UserFactory.GenerateUserCreateDto(role: UserRole.BANNED, rawPassword: DefaultPassword);
        _unverified_user = UserFactory.GenerateUserCreateDto(role: UserRole.UNVERIFIED, rawPassword: DefaultPassword);

        _createdUsers.AddRange(_admin_user, _user_user, _user2_user, _user3_user, _banned_user, _unverified_user);
        foreach (var userDto in _createdUsers)
        {
            await _superUserControllerClient.AddUser(userDto);
        }
    }

    public void SetActivityLevel(int i = 1)
    {
        // <1:5> - will decide on amount of actions performed by each user
        if (!(0 < i && i < 6))
        { return;}
        _activityLevel = i;
    }
    public void Simulate()
    {
        // Choose time frame per action based on activity level
        var timeFrameInSeconds = 50/(_activityLevel*_createdUsers.Count);

        HttpClient tempClient;

        // For each user: log in
        foreach (var user in _createdUsers)
        {

        }

        // For each user: Create different api clients

        //
    }
}
