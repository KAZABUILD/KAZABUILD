using System.Diagnostics;
using System.Net.Http.Json;
using KAZABUILD.Application.DTOs.Builds.Tag;
using KAZABUILD.Application.DTOs.Components.ComponentReview;
using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Application.DTOs.Users.User;
using KAZABUILD.Application.DTOs.Users.ForumPost;
using KAZABUILD.Application.DTOs.Users.Message;
using KAZABUILD.Application.DTOs.Users.Notification;
using KAZABUILD.Application.DTOs.Users.UserComment;
using KAZABUILD.Application.DTOs.Users.UserFollow;
using KAZABUILD.Application.DTOs.Users.UserPreference;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;

namespace KAZABUILD.Tests.PerformanceTests;

[Collection("Sequential")]
public class UserRegistrationAndActivityPerformanceTests : BasePerformanceTest
{
    private const string DefaultPassword = "password123!";
    private int _activityLevel;

    private readonly List<CreateUserDto> _createdUsers = new();
    private readonly List<HttpClient> _userClients = new();
    private readonly Dictionary<string, UserApiClients> _clients = new();

    // Track user IDs mapped to their CreateUserDto
    private readonly Dictionary<string, Guid> _userIdsByLogin = new();

    // Track created resources for realistic interactions
    private readonly List<string> _createdForumPostIds = new();
    private readonly List<string> _createdBuildIds = new();
    private readonly List<string> _createdComponentIds = new();

    private CreateUserDto? _admin_user;
    private CreateUserDto? _user_user;
    private CreateUserDto? _user2_user;
    private CreateUserDto? _user3_user;
    private CreateUserDto? _banned_user;
    private CreateUserDto? _unverified_user;

    [Fact]
    public async Task RunPerformanceSimulation()
    {
        await CreateUsers();
        SetActivityLevel(3); // Activity level 1-5
        await Simulate(60); // 60 seconds simulation
    }

    [Theory]
    [InlineData(1, 30)]
    [InlineData(3, 60)]
    [InlineData(5, 120)]
    public async Task RunPerformanceSimulation_WithParameters(int activityLevel, int durationSeconds)
    {
        await CreateUsers();
        SetActivityLevel(activityLevel);
        await Simulate(durationSeconds);
    }

    private async Task CreateUsers()
    {
        _admin_user       = UserFactory.GenerateUserCreateDto(role: UserRole.ADMINISTRATOR, rawPassword: DefaultPassword);
        _user_user        = UserFactory.GenerateUserCreateDto(role: UserRole.USER, rawPassword: DefaultPassword);
        _user2_user       = UserFactory.GenerateUserCreateDto(role: UserRole.USER, rawPassword: DefaultPassword);
        _user3_user       = UserFactory.GenerateUserCreateDto(role: UserRole.USER, rawPassword: DefaultPassword);
        _banned_user      = UserFactory.GenerateUserCreateDto(role: UserRole.BANNED, rawPassword: DefaultPassword);
        _unverified_user  = UserFactory.GenerateUserCreateDto(role: UserRole.UNVERIFIED, rawPassword: DefaultPassword);

        _createdUsers.AddRange(new[]
        {
            _admin_user, _user_user, _user2_user, _user3_user, _banned_user, _unverified_user
        }!);

        foreach (var userDto in _createdUsers)
        {
            var response = await _superUserControllerClient.AddUser(userDto);
            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<dynamic>();
                if (result?.id != null)
                {
                    _userIdsByLogin[userDto.Login] = Guid.Parse(result.id.ToString());
                }
            }
        }
    }

    public void SetActivityLevel(int i = 1)
    {
        if (!(0 < i && i < 6))
            return;

        _activityLevel = i;
    }

    public async Task Simulate(int simulationTimeInSeconds = 60)
    {
        int userCount = Math.Max(_createdUsers.Count, 1);
        var timeFrameInSeconds = 50 / (_activityLevel * userCount);

        // Authenticate each user
        foreach (var userCreateDto in _createdUsers)
        {
            var client = new HttpClient { BaseAddress = _baseAddress };

            await HttpClientAssigner.AssignUserToClientAsync(
                client,
                new User { Login = userCreateDto.Login },
                ip: "127.0.0.1",
                password: DefaultPassword);

            _userClients.Add(client);
        }

        // Build API client sets
        for (int i = 0; i < _createdUsers.Count; i++)
        {
            var dto = _createdUsers[i];
            var http = _userClients[i];

            _clients[dto.Login] = new UserApiClients(
                Users:               new UsersControllerClient(http),
                Auth:                new AuthControllerClient(http),
                Admin:               new AdminControllerClient(http),
                BuildComponents:     new BuildComponentsControllerClient(http),
                BuildInteractions:   new BuildInteractionsControllerClient(http),
                Builds:              new BuildsControllerClient(http),
                BuildTags:           new BuildTagsControllerClient(http),
                Colors:              new ColorsControllerClient(http),
                Compatibilities:     new ComponentCompatibilitiesControllerClient(http),
                ComponentParts:      new ComponentPartsControllerClient(http),
                ComponentPrices:     new ComponentPricesControllerClient(http),
                ComponentReviews:    new ComponentReviewsControllerClient(http),
                Components:          new ComponentsControllerClient(http),
                ComponentVariants:   new ComponentVariantsControllerClient(http),
                ForumPosts:          new ForumPostsControllerClient(http),
                Images:              new ImagesControllerClient(http),
                Messages:            new MessagesControllerClient(http),
                Notifications:       new NotificationsControllerClient(http),
                SubComponentParts:   new SubComponentPartsControllerClient(http),
                SubComponents:       new SubComponentsControllerClient(http),
                Tags:                new TagsControllerClient(http),
                UserActivities:      new UserActivitiesControllerClient(http),
                UserBlocks:          new UserBlocksControllerClient(http),
                CommentInteractions: new UserCommentInteractionsControllerClient(http),
                Comments:            new UserCommentsControllerClient(http),
                Feedback:            new UserFeedbackControllerClient(http),
                Follows:             new UserFollowsControllerClient(http),
                Preferences:         new UserPreferencesControllerClient(http),
                Reports:             new UserReportsControllerClient(http)
            );
        }

        var rng = new Random();
        var topics = new[] { "General", "BuildHelp", "Components", "Troubleshooting", "ShowCase" };
        var userLogins = _userIdsByLogin.Keys.ToList();

        // Create weighted actions (some should be more common than others)
        var actions = new List<(int weight, Func<UserApiClients, string, Task> action)>
        {
            // READ operations (most common - 50%)
            (15, async (c, login) => await c.Users.GetUsers(new GetUserDto())),
            (10, async (c, login) => await c.Builds.GetBuild(_createdBuildIds.Count > 0 ? _createdBuildIds[rng.Next(_createdBuildIds.Count)] : "example-id")),
            (10, async (c, login) => await c.ForumPosts.GetPosts(new GetForumPostDto { Topic = new List<string> { topics[rng.Next(topics.Length)] }, Paging = true, Page = 1, PageLength = 20 })),
            (7, async (c, login) => await c.Notifications.GetNotifications(new GetNotificationDto())),

            // WRITE operations - Forum Posts (20%)
            (8, async (c, login) =>
            {
                var userId = _userIdsByLogin[login];
                var response = await c.ForumPosts.AddForumPost(new CreateForumPostDto
                {
                    CreatorId = userId,
                    Title = $"Test Post {Guid.NewGuid().ToString()[..8]}",
                    Content = $"This is a test forum post created during performance testing at {DateTime.UtcNow}",
                    Topic = topics[rng.Next(topics.Length)],
                    PostedAt = DateTime.UtcNow
                });

                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadFromJsonAsync<dynamic>();
                    if (result?.id != null)
                        _createdForumPostIds.Add(result.id.ToString());
                }
            }),
            (5, async (c, login) =>
            {
                if (_createdForumPostIds.Count > 0)
                {
                    var postId = _createdForumPostIds[rng.Next(_createdForumPostIds.Count)];
                    await c.ForumPosts.GetForumPost(postId);
                }
            }),
            (3, async (c, login) =>
            {
                if (_createdForumPostIds.Count > 0)
                {
                    var postId = _createdForumPostIds[rng.Next(_createdForumPostIds.Count)];
                    await c.ForumPosts.UpdateForumPost(postId, new UpdateForumPostDto
                    {
                        Content = $"Updated content at {DateTime.UtcNow}",
                        Note = "Performance test update"
                    });
                }
            }),

            // SOCIAL interactions (15%)
            (5, async (c, login) =>
            {
                var randomUserLogin = userLogins[rng.Next(userLogins.Count)];
                var targetUserId = _userIdsByLogin[randomUserLogin];
                await c.Follows.AddUserFollow(new CreateUserFollowDto { FollowedId = targetUserId });
            }),
            (4, async (c, login) => await c.Comments.AddUserComment(new CreateUserCommentDto { Content = "Great build!", TargetId = Guid.NewGuid() })),
            (3, async (c, login) =>
            {
                var randomUserLogin = userLogins[rng.Next(userLogins.Count)];
                var receiverId = _userIdsByLogin[randomUserLogin];
                await c.Messages.SendMessage(new CreateMessageDto { ReceiverId = receiverId, Content = "Test message" });
            }),

            // USER management (10%)
            (5, async (c, login) =>
            {
                var userId = _userIdsByLogin[login];
                await c.UserActivities.GetUserActivity(userId.ToString());
            }),
            (3, async (c, login) =>
            {
                var userId = _userIdsByLogin[login];
                await c.Preferences.GetUserPreference(userId.ToString());
            }),

            // COMPONENT operations (5%)
            (3, async (c, login) => await c.ComponentReviews.AddComponentReview(new CreateComponentReviewDto { ComponentId = Guid.NewGuid(), Rating = rng.Next(1, 6), ReviewText = "Test review" })),
            (2, async (c, login) => await c.Tags.GetTags(new GetTagDto())),
        };

        // Create weighted action list
        var weightedActions = new List<(Func<UserApiClients, string, Task> action, string name)>();
        for (int i = 0; i < actions.Count; i++)
        {
            for (int j = 0; j < actions[i].weight; j++)
            {
                weightedActions.Add((actions[i].action, $"Action_{i}"));
            }
        }

        var sw = Stopwatch.StartNew();
        var actionCounts = new Dictionary<string, int>();
        var errorCounts = new Dictionary<string, int>();
        int totalActions = 0;

        Console.WriteLine($"Simulation started for {simulationTimeInSeconds} seconds with activity level {_activityLevel}…");
        Console.WriteLine($"Time frame between actions: {timeFrameInSeconds:F2} seconds");

        while (sw.Elapsed < TimeSpan.FromSeconds(simulationTimeInSeconds))
        {
            foreach (var kv in _clients)
            {
                if (sw.Elapsed >= TimeSpan.FromSeconds(simulationTimeInSeconds))
                    break;

                var client = kv.Value;
                var login = kv.Key;
                var (action, actionName) = weightedActions[rng.Next(weightedActions.Count)];

                try
                {
                    await action(client, login);
                    actionCounts[actionName] = actionCounts.GetValueOrDefault(actionName, 0) + 1;
                    totalActions++;
                }
                catch (Exception ex)
                {
                    errorCounts[actionName] = errorCounts.GetValueOrDefault(actionName, 0) + 1;
                    Console.WriteLine($"[{kv.Key}] {actionName} failed: {ex.Message}");
                }

                await Task.Delay(TimeSpan.FromSeconds(timeFrameInSeconds));
            }
        }

        sw.Stop();

        // Print statistics
        Console.WriteLine($"\n{'='} Simulation Complete {'='}");
        Console.WriteLine($"Duration: {sw.Elapsed.TotalSeconds:F2} seconds");
        Console.WriteLine($"Total Actions: {totalActions}");
        Console.WriteLine($"Actions/Second: {totalActions / sw.Elapsed.TotalSeconds:F2}");
        Console.WriteLine($"\nAction Distribution:");

        foreach (var kvp in actionCounts.OrderByDescending(x => x.Value))
        {
            Console.WriteLine($"  {kvp.Key}: {kvp.Value} ({100.0 * kvp.Value / totalActions:F1}%)");
        }

        if (errorCounts.Any())
        {
            Console.WriteLine($"\nErrors:");
            foreach (var kvp in errorCounts.OrderByDescending(x => x.Value))
            {
                Console.WriteLine($"  {kvp.Key}: {kvp.Value}");
            }
        }

        Console.WriteLine($"\nCreated Resources:");
        Console.WriteLine($"  Forum Posts: {_createdForumPostIds.Count}");
        Console.WriteLine($"  Builds: {_createdBuildIds.Count}");
        Console.WriteLine($"  Components: {_createdComponentIds.Count}");
    }

    private record UserApiClients(
        UsersControllerClient Users,
        AuthControllerClient Auth,
        AdminControllerClient Admin,
        BuildComponentsControllerClient BuildComponents,
        BuildInteractionsControllerClient BuildInteractions,
        BuildsControllerClient Builds,
        BuildTagsControllerClient BuildTags,
        ColorsControllerClient Colors,
        ComponentCompatibilitiesControllerClient Compatibilities,
        ComponentPartsControllerClient ComponentParts,
        ComponentPricesControllerClient ComponentPrices,
        ComponentReviewsControllerClient ComponentReviews,
        ComponentsControllerClient Components,
        ComponentVariantsControllerClient ComponentVariants,
        ForumPostsControllerClient ForumPosts,
        ImagesControllerClient Images,
        MessagesControllerClient Messages,
        NotificationsControllerClient Notifications,
        SubComponentPartsControllerClient SubComponentParts,
        SubComponentsControllerClient SubComponents,
        TagsControllerClient Tags,
        UserActivitiesControllerClient UserActivities,
        UserBlocksControllerClient UserBlocks,
        UserCommentInteractionsControllerClient CommentInteractions,
        UserCommentsControllerClient Comments,
        UserFeedbackControllerClient Feedback,
        UserFollowsControllerClient Follows,
        UserPreferencesControllerClient Preferences,
        UserReportsControllerClient Reports
    );
}
