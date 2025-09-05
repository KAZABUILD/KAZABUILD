using KAZABUILD.Application.Settings;
using KAZABUILD.Infrastructure;
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
            builder.Services.AddSwaggerGen();

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
                    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
                });

            var app = builder.Build();

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

            app.Run();
        }
    }
}
