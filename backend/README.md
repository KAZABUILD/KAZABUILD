# KAZA BUILD - BACKEND

## How to run
 - `cd backend/KAZABUILD.API` to get into the backend application folder in terminal
 - `dotnet restore` to get the required packages
 - create and fill in the `launchSettings.json` file with correct information based on the example file
 - use visual studio to run or `dotnet watch run`
 - access automatic swagger documentation using `<ip_address>/swagger`

## Migrations
 - `cd backend` to get into the main backend folder in terminal
 - `dotnet ef migrations add InitialCreate --project KAZABUILD.Infrastructure --startup-project KAZABUILD.API` to create the initial database migration
 - `dotnet ef database update` to apply migration
 - migrations can be reviewed in `backend/KAZABUILD.Infrastructure/Migrations`


## NuGet Packages:
- `MediatR`
- `FluentValidation.DependencyInjectionExtensions`
- `Microsoft.AspNetCore.OpenApi`
- `Microsoft.EntityFrameworkCore`
- `Microsoft.EntityFrameworkCore.SqlServer`
- `Microsoft.EntityFrameworkCore.Tools`
- `Swashbuckle.AspNetCore`
- `RabbitMQ.Client`
- `Microsoft.AspNetCore.Authentication.JwtBearer`
- `Microsoft.Extensions.Options.ConfigurationExtensions`
- `BCrypt.Net-Next`
- `Serilog.AspNetCore`
- `FluentAssertions`
- `Microsoft.AspNetCore.Mvc.Testing`
- `Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore`
- `AspNetCoreRateLimit`
- `System.Linq.Dynamic.Core`

## Features
- Swagger Documentation
- Authentication
- Authorization
- Automatic Validation
- Rate Limiting
- CORS
- RabbitMQ Queues
- Health Checks Endpoints
- Smtp Email Service
- hashing Service

## Models

## Controller methods