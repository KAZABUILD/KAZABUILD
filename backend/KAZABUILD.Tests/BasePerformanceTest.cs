using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using KAZABUILD.Tests.ControllerServices;
using KAZABUILD.Tests.Utils;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

public abstract class BasePerformanceTest
{
    protected User _superAdmin;
    protected HttpClient _superAdminHttpClient;
    protected AdminControllerClient _superAdminControllerClient;
    protected UsersControllerClient _superUserControllerClient;
    protected IConfiguration _configuration = null!;
    protected Uri _baseAddress;
    protected BasePerformanceTest()
    {
        _configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json", optional: false)
            .AddJsonFile("appsettings.json.example", optional: true)
            .AddEnvironmentVariables()
            .Build();

        _baseAddress = new Uri(_configuration["backend:Host"]);

        _superAdminHttpClient = new HttpClient
        {
            BaseAddress = _baseAddress
        };
    }

    public virtual async Task InitializeAsync()
    {
        var superAdminLogin = _configuration["SYSTEM_ADMIN_NAME:Name"];
        var superAdminPassword = _configuration["SYSTEM_ADMIN:Password"];
        _superAdminControllerClient = new AdminControllerClient(_superAdminHttpClient);
    }
}
