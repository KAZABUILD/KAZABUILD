# KAZA BUILD - BACKEND

## How to run
 - `cd backend/KAZABUILD.API` to get into the backend application folder in terminal.
 - `dotnet restore` to get the required packages.
 - Create and fill in the `launchSettings.json` file with correct information based on the example file.
 - Use visual studio to run or use `dotnet watch run` in the command line.
 - Access automatic swagger documentation using `<ip_address>/swagger`.

## Migrations
 - `cd backend` to get into the main backend folder in terminal.
 - `dotnet ef migrations add InitialCreate --project KAZABUILD.Infrastructure --startup-project KAZABUILD.API` to create the initial database migration. If there is one already create a different one or just apply it.
 - `dotnet ef database update` to apply all migrations.
 - The app will automatically apply migrations when run.
 - Migrations can be reviewed in `backend/KAZABUILD.Infrastructure/Migrations`.

## Search function
 - Whenever a new model is added to the database the user has to manually add the search index for it as well:
   - Create a new migration.
   - Add this to the up function:
     - `migrationBuilder.Sql(@"`
            `IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.[class_name]'))`
                `CREATE FULLTEXT INDEX ON [class_name]([field_name1] LANGUAGE 0, [field_name2] LANGUAGE 0)`
                `KEY INDEX PK_[class_name];`
        `", suppressTransaction: true);`
   - Add this to the down function:
     - `migrationBuilder.Sql("DROP FULLTEXT INDEX ON [class_name];", suppressTransaction: true);`
    

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
- SMTP Email Service
- Hashing Service
- Guest User Handling Middleware

## Models
All models have protections against adding invalid values but the any call made should be double checked anyway

- User (individual user account, profile and settings):
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
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- Log (events happening in the application, like API calls, errors, database connection info)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the id of the user that called the logged activity
  - `Timestamp` -> date object storing when the activity happened
  - `SeverityLevel` -> Enum storing how critical the information in the log is
  - `ActivityType` -> string storing what is being logged
  - `TargetType` -> string storing where the activity happened
  - `TargetId` -> nullable string storing which object in the database was affected
  - `Description` -> nullable string storing additional information about the activity and error if one occurred
  - `IpAddress` -> the IP address of the user that called the logged activity

- UserToken (temporary token for authorization)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id the token is for
  - `Token` -> string storing the actual token 
  - `TokenType` -> string storing the type of the token
  - `CreatedAt` -> date object storing the date the token was created
  - `ExpiresAt` -> date object storing the date the token expires
  - `UsedAt` -> date object storing the date the token was used
  - `IpAddress` -> string storing the IP address of the person calling the endpoint that created the token
  - `RedirectUrl` -> string that stores the URL to which the user should be redirected after clicking a link with the token 
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- UserPreference (data from polls and quizzes)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id the preference is for
  - `DatabaseEntryAt` -> date object storing when the user was created in the database
  - `LastEditedAt` -> date object storing when the user was last edited
  - `Note` -> nullable string storing any staff-only information

- UserFollow (which user follows which user)
  - `Id` -> automatically assigned GUID
  - `FollowerId` -> GUID storing the user's id for the user that is following
  - `FollowedId` -> GUID storing the user's id for the user that is being followed
  - `FollowedAt` -> date object storing when the user was followed
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- UserComment (replies to different types of objects)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id that wrote the comment
  - `Content` -> string storing the html text in the comment
  - `ParentCommentId` -> nullable GUID storing which comment is being replied to
  - `CommentTargetType` -> Enum storing what type of entity is this commented under
  - `ForumPostId` -> nullable GUID storing which forum post is being replied to
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- Notification (notification about something happening, e.g. a discount for a liked product)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id that received the notification
  - `NotificationType` -> Enum storing the type of notification
  - `Body` -> string storing the html text in the notification
  - `Title` -> string storing the title of the notification
  - `LinkUrl` -> string storing the link to any related page
  - `SentAt` -> date object storing when the notification has been or will be received
  - `IsRead` -> bool storing whether the notification was read by the user
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- Message (private message sent or received by the user)
  - `Id` -> automatically assigned GUID
  - `SenderId` -> GUID storing the user's id that sent the message
  - `ReceiverId` -> GUID storing the user's id that received the message
  - `Content` -> string storing the html text in the message
  - `Title` -> string storing the title of the message
  - `SentAt` -> date object storing when the message has been sent
  - `IsRead` -> bool storing whether the message was read by the user
  - `ParentMessageId` -> nullable GUID storing which message is being replied to
  - `MessageType` -> Enum storing type of the message
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- ForumPost (private message sent by the user)
  - `Id` -> automatically assigned GUID
  - `CreatorId` -> GUID storing the user's id that posted the ForumPost
  - `Content` -> string storing the html text in the ForumPost
  - `Title` -> string storing the title of the ForumPost
  - `Topic` -> string storing the topic in which the ForumPost has been posted in
  - `PostedAt` -> date object storing when the ForumPost has been posted
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

## Controller methods
To see what fields should be provided in an API request check the swagger documentation.

### Basic CRUD API calls
- `GET/id` gets the specified object from the database using the id:
  - all users have access but returns differing amount of information.
- `POST/add` creates a new object with elements provided in the Body:
  - usually the user can create objects belonging to them;
  - staff can create objects related to user activity;
  - admins can create any object.
- `DELETE/id` removes the specified object from the database
  - usually the user can delete objects belonging to them;
  - staff can delete objects related to user activity;
  - admins can delete any object.
- `POST/get` gets a list of objects depending on the provided: allowed field values, sort order, page length and number:
  - all users have access but returns differing amount of information.
- `PUT/id` updates the specified object with the fields provided, only fields specified in the body get updated
  - all users can edit information related to themselves;
  - staff can edit sensitive user related information;
  - admins can modify any object.

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
