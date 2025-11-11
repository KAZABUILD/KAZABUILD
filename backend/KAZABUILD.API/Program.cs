using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Settings;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using KAZABUILD.Infrastructure.DependencyInjection;
using KAZABUILD.Infrastructure.Middleware;

using Prometheus;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Serilog;
using System.Text.Json.Serialization;

namespace KAZABUILD.API
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            //Register all custom services
            builder.Services.AddInfrastructure(builder.Configuration);

            //Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            //Register Swagger
            builder.Services.AddSwaggerSettings();

            //Add CORS policy
            var corsSettings = builder.Configuration.GetSection("Frontend").Get<FrontendSettings>()!;
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("DevelopmentCorsPolicy", policy =>
                {
                    policy.WithOrigins(corsSettings.AllowedFrontendOrigins)
                          .AllowAnyHeader()
                          .AllowAnyMethod()
                          .AllowCredentials();
                });

                options.AddPolicy("ProductionCorsPolicy", policy =>
                {
                    policy.WithOrigins(corsSettings.AllowedFrontendOrigins)
                          .AllowAnyMethod()
                          .WithHeaders("Content-Type", "Authorization");
                });
            });

            //Add services for controllers
            builder.Services.AddControllers()
                .AddJsonOptions(options =>
                {
                    //Add enum serialization (so that both numerical values and string are valid)
                    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter(allowIntegerValues: true));
                });

            //Register Serilog settings
            builder.Host.UseSerilog((ctx, config) =>
                config.ReadFrom.Configuration(ctx.Configuration));

            //Add Prometheus HTTP metrics before building the app
            builder.Services.AddHealthChecks();

            //Build the app using the declared configuration
            var app = builder.Build();

            //Get the database context and the logger from context
            using var scope = app.Services.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<KAZABUILDDBContext>();
            var logger = scope.ServiceProvider.GetRequiredService<ILoggerService>();

            //Enter a loop that will go on until a connection to the database can be established
            while (true)
            {
                try
                {
                    await dbContext.Database.MigrateAsync();
                    //await logger.FlushStashedLogsAsync();
                    Console.WriteLine("Database initialized successfully!");
                    break;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Database connection failed: {ex.Message}");
                    Console.WriteLine($"Exception Type: {ex.GetType().Name}");
                    Console.WriteLine($"Stack Trace: {ex.StackTrace}");

                    // Log inner exception if exists
                    if (ex.InnerException != null)
                    {
                        Console.WriteLine($"Inner Exception: {ex.InnerException.Message}");
                        Console.WriteLine($"Inner Stack Trace: {ex.InnerException.StackTrace}");
                    }

                    Console.WriteLine("Retrying in 5 seconds...");
                    await Task.Delay(TimeSpan.FromSeconds(5));
                }
            }

            //Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();

                //Add Swagger documentation middleware
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            //Add health check endpoints
            app.MapHealthChecks("/health/live");
            app.MapHealthChecks("/health/ready");

            //Redirect http to https
            app.UseHttpsRedirection();

            //Enable forwarded headers usage
            app.UseForwardedHeaders();

            //Enable CORS policy
            if (app.Environment.IsDevelopment())
                app.UseCors("DevelopmentCorsPolicy");
            else
                app.UseCors("ProductionCorsPolicy");

            //Enable authentication
            app.UseAuthentication();

            //Enable middleware for handling guest user claims
            app.UseMiddleware<GuestClaimsMiddleware>();

            //Enable middleware for handling ip blocks
            app.UseMiddleware<BannedClaimsMiddleware>();

            //Enables rate limiting
            app.UseRateLimiter();

            //Enable authorization
            app.UseAuthorization();

            //Enable Prometheus HTTP request metrics middleware
            app.UseHttpMetrics();

            app.MapControllers();

            //Expose the /metrics endpoint for Prometheus to scrape
            app.MapMetrics();

            //Get the hasher and admin user settings
            var hasher = scope.ServiceProvider.GetRequiredService<IHashingService>();
            var SystemAdminSettigns = scope.ServiceProvider.GetRequiredService<IOptions<SystemAdminSetings>>().Value;
            var SmtpServiceSettings = scope.ServiceProvider.GetRequiredService<IOptions<SmtpSettings>>().Value;

            //Create the system user if one doesn't already exist
            if (!await dbContext.Users.AnyAsync(u => u.Login == SystemAdminSettigns.Login))
            {
                var systemUser = new User
                {
                    Id = Guid.Parse("00000000-0000-0000-0000-000000000001"),
                    Login = SystemAdminSettigns.Login,
                    Email = SmtpServiceSettings.Username,
                    PasswordHash = hasher.Hash(SystemAdminSettigns.Password),
                    DisplayName = SystemAdminSettigns.Login,
                    Description = "System Admin account. Beware!",
                    Gender = "None",
                    UserRole = UserRole.SYSTEM,
                    ImageId = null,
                    Birth = DateTime.UtcNow,
                    RegisteredAt = DateTime.UtcNow,
                    ProfileAccessibility = ProfileAccessibility.PUBLIC,
                    Theme = Theme.LIGHT,
                    Language = Language.ENGLISH,
                    ReceiveEmailNotifications = false,
                    EnableDoubleFactorAuthentication = false
                };

                dbContext.Users.Add(systemUser);
                await dbContext.SaveChangesAsync();
            }

            //Try to run the app and throw an error for empty validation
            try
            {
                app.Run();
            }
            catch (OptionsValidationException ex)
            {
                //Log the validation error
                await logger.LogAsync(
                    Guid.Empty,
                    "Validation",
                    "Database",
                    "",
                    Guid.Empty,
                    PrivacyLevel.CRITICAL,
                    $"Configuration validation failed. Error message: {ex.Message}"
                );

                //Print all configuration errors to the console
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Configuration validation failed:");
                foreach (var failure in ex.Failures)
                {
                    Console.WriteLine($"  - {failure}");
                }
                Console.ResetColor();

                //Close the app upon a button press
                Console.WriteLine("Press any button to close...");
                if (!app.Environment.IsEnvironment("Testing"))
                {
                    Console.WriteLine("Press any key to exit...");
                    Console.ReadKey();
                }
                return;
            }
            catch (Exception ex)
            {
                //Log the validation error
                await logger.LogAsync(
                    Guid.Empty,
                    "Start",
                    "Application",
                    "",
                    Guid.Empty,
                    PrivacyLevel.CRITICAL,
                    $"Launching the application failed. Error message: {ex.Message}"
                );

                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Launching the application failed: {ex.Message}");
                Console.ResetColor();

                //Close the app upon a button press
                Console.WriteLine("Press any button to close...");
                Console.ReadKey();
                return;
            }
        }
    }
}
