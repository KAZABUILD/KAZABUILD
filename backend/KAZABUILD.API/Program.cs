using KAZABUILD.Application.Settings;
using KAZABUILD.Infrastructure;
using KAZABUILD.Infrastructure.Data;

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Serilog;
using System.Text.Json.Serialization;

namespace KAZABUILD.API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            //Register the database and add the infrastructure
            builder.Services.AddInfrastructure(builder.Configuration);

            //Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            //Documentation with swagger
            builder.Services.AddSwaggerGen(c =>
            {
                //Enable adding a jwt security token
                c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    In = Microsoft.OpenApi.Models.ParameterLocation.Header
                });

                //Inform swagger that endpoints require authorization
                c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
                {
                    {
                        new Microsoft.OpenApi.Models.OpenApiSecurityScheme
                        {
                            Reference = new Microsoft.OpenApi.Models.OpenApiReference
                            {
                                Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });

            //Add CORS policy
            var corsSettings = builder.Configuration.GetSection("AllowedFrontendOrigins").Get<FrontendSettings>()!;
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

            //Build the app using the declared configuration
            var app = builder.Build();

            //Apply migrations automatically
            using var scope = app.Services.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<KAZABUILDDBContext>();
            try
            {
                dbContext.Database.Migrate();
            }
            catch (Exception ex) //Catch any error related to migration
            {
                var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
                logger.LogError(ex, "An error occurred while migrating the database.");
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

            //Enables rate limiting
            app.UseRateLimiter();

            //Enable authentication
            app.UseAuthentication();

            //Enable authorization
            app.UseAuthorization();

            //Map controllers' enpoints
            app.MapControllers();

            //Try to run the app and throw an error for empty validation
            try
            {
                app.Run();
            }
            catch (OptionsValidationException ex)
            {
                //Print all configuration errors
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Configuration validation failed:");
                foreach (var failure in ex.Failures)
                {
                    Console.WriteLine($"  - {failure}");
                }
                Console.ResetColor();

                //Close the app upon a button press
                Console.WriteLine("Press any button to close...");
                Console.ReadKey();
                return;
            }
            catch (Exception ex)
            {
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
