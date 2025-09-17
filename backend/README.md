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
- `Microsoft.AspNetCore.Authentication.Google`
- `Google.Apis.Auth`

## Features
- Swagger Documentation
- Authentication Middleware
- Authorization Middleware
- Automatic Validation
- Rate Limiting
- CORS Middleware
- RabbitMQ Queues
- Health Checks Endpoints
- Smtp Email Service
- Hashing Service
- Guest User Handling Middleware

## Models
All models have protections against adding invalid values but the any call made should be double checked anyway

- User:
  - `Id` -> automatically assigned GUID
  - `Login` -> string storing user's username
  - `Email` -> string storing a unique email
  - `PasswordHash` -> string storing securely stored password
  - `DisplayName` -> string storing the name displayed on user's profile
  - `PhoneNumber` -> nullable string storing phone number
  - `Description` -> string storing user's profile description
  - `Gender` -> string storing user's gender (Write full names like "Male")
  - `UserRole` -> Enum storing the assigned user role, can be used with a number or the full role string
  - `ImageURL` -> string storing user's saved profile picture's URL in the backend
  - `Birth` -> date object storing user's birth date
  - `RegisteredAt` -> date object storing the date the user registered their account
  - `Address` -> an object storing user's address with 7 strings:
    - `Country`
    - nullable `Province`
    - `City`
    - `Street`
    - `StreetNumber`
    - `PostalCode`
    - nullable `apartmentNumber`
  - `ProfileAccessibility` -> Enum storing who can see user's profile
  - `Theme` -> Enum storing which theme the user uses globally
  - `Language` -> Enum storing which language the user uses globally 
  - `Location` -> nullable string storing user's noted location
  - `ReceiveEmailNotifications` -> string storing whether the user wants to receive email notifications
  - `DatabaseEntryAt` -> date object storing when the user was created in the database
  - `LastEditedAt` -> date object storing when the user was last edited
  - `Note` -> nullable string storing any staff-only information

- Log
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the id of the user that called the logged activity
  - `Timestamp` -> date object storing when the activity happened
  - `SeverityLevel` -> Enum storing how critical the information in the log is
  - `ActivityType` -> string storing what is being logged
  - `TargetType` -> string storing where the activity happened
  - `TargetId` -> nullable string storing which object in the database was affected
  - `Description` -> nullable string storing additional information about the activity and error if one occurred
  - `IpAddress` -> the IP address of the user that called the logged activity

- UserToken
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id the token is for
  - `Token` -> string storing the actual token 
  - `TokenType` -> string storing the type of the token
  - `CreatedAt` -> date object storing the date the token was created
  - `ExpiresAt` -> date object storing the date the token expires
  - `UsedAt` -> date object storing the date the token was used
  - `IpAddress` -> string storing the IP address of the person calling the endpoint that created the token
  - `RedirectUrl` -> string that stores the URL to which the user should be redirected after clicking a link with the token 
  - `DatabaseEntryAt` -> date object storing when the user was created in the database
  - `LastEditedAt` -> date object storing when the user was last edited
  - `Note` -> nullable string storing any staff-only information

## Controller methods
To see what fields should be provided in an API request check the swagger documentation.

### Basic CRUD API calls
- `GET/id` gets the specified object from the database using the id
  - all users have access but returns different amount of information
- `POST/add` creates a new object with elements provided in the Body
  - only staff has access
- `DELETE/id` removes the specified object from the database
  - only staff has access
- `POST/get` gets a list of objects depending on the provided: allowed field values, sort order, page length and number
  - all users have access but returns different amount of information
- `PUT/id` updates the specified object with the fields provided, only fields specified in the body get updated
  - all users can edit information related to themselves
  - only staff can edit sensitive user related info
  - only admins can modify component related objects

### User specific API calls
- `Users/POST/change-password` allows the user to change their own password, requires the old and new password in the body

### Auth specific API calls
- `Auth/POST/login` allows anyone to login using their password and either Login or Email, sends confirmation email if enabled on user's account
- `Auth/POST/verify-2fa` redirect endpoint that verifies user login with 2fa, never call manually
- `Auth/POST/google-login` allows anyone to login using their google account, connects to google services, has some fields missing and requires further user account setup in the frontend (missing birth date)
- `Auth/POST/register` allows anyone to register a new account, requires providing all user account fields, sends confirmation email
- `Auth/POST/confirm-register` redirect endpoint that verifies user registration, never call manually, redirects to frontend
- `Auth/POST/reset-password` allows anyone to reset user's password, requires providing the old and new passwords, sends confirmation email
- `Auth/POST/confirm-reset-password` redirect endpoint that verifies password reset, never call manually, redirects to frontend