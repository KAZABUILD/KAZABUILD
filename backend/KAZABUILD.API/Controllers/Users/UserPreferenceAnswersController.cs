using KAZABUILD.Application.DTOs.Users.UserPreferenceAnswer;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Users
{
    /// <summary>
    /// Controller for User Preference Answer related endpoints.
    /// Used to set answers to questions in the questionnaires.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserPreferenceAnswersController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new UserPreferenceAnswer for admins.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddUserPreferenceAnswer([FromBody] CreateUserPreferenceAnswerDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();
            
            //Check if the answer exists
            var answer = await _db.UserPreferences.FirstOrDefaultAsync(u => u.Id == dto.UserPreferenceId);
            if (answer == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserPreferenceAnswer",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - UserPreference Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Preference not found!" });
            }

            //Create a userPreferenceAnswer to add
            UserPreferenceAnswer userPreferenceAnswer = new()
            {
                UserPreferenceId = dto.UserPreferenceId,
                Answer = dto.Answer,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userPreferenceAnswer to the database
            _db.UserPreferenceAnswers.Add(userPreferenceAnswer);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserPreferenceAnswer",
                ip,
                userPreferenceAnswer.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserPreferenceAnswer Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreferenceAnswer.created", new
            {
                userPreferenceAnswerId = userPreferenceAnswer.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Preference created successfully!", id = userPreferenceAnswer.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserPreferenceAnswer for admins.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateUserPreferenceAnswer(Guid id, [FromBody] UpdateUserPreferenceAnswerDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userPreferenceAnswer to edit
            var userPreferenceAnswer = await _db.UserPreferenceAnswers.FirstOrDefaultAsync(p => p.Id == id);
            if (userPreferenceAnswer == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserPreferenceAnswer",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserPreferenceAnswer"
                );

                //Return not found response
                return NotFound(new { message = "User Preference not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if(!string.IsNullOrWhiteSpace(dto.Answer))
            {
                changedFields.Add("Answer: " + userPreferenceAnswer.Answer);

                userPreferenceAnswer.Answer = dto.Answer;
            }
            if (dto.UserPreferenceId != null)
            {
                changedFields.Add("UserPreferenceId: " + userPreferenceAnswer.UserPreferenceId);

                userPreferenceAnswer.UserPreferenceId = (Guid)dto.UserPreferenceId;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + userPreferenceAnswer.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    userPreferenceAnswer.Note = null;
                else
                    userPreferenceAnswer.Note = dto.Note;
            }

            //Update edit timestamp
            userPreferenceAnswer.LastEditedAt = DateTime.UtcNow;

            //Update the userPreferenceAnswer
            _db.UserPreferenceAnswers.Update(userPreferenceAnswer);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserPreferenceAnswer",
                ip,
                userPreferenceAnswer.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreferenceAnswer.updated", new
            {
                userPreferenceAnswerId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Preference updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserPreferenceAnswer specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserPreferenceAnswerResponseDto>> GetUserPreferenceAnswer(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userPreferenceAnswer to return
            var userPreferenceAnswer = await _db.UserPreferenceAnswers.FirstOrDefaultAsync(p => p.Id == id);
            if (userPreferenceAnswer == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserPreferenceAnswer",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserPreferenceAnswer"
                );

                //Return not found response
                return NotFound(new { message = "User Preference not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserPreferenceAnswerResponseDto response;

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has staff privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create userPreferenceAnswer response
                response = new UserPreferenceAnswerResponseDto
                {
                    Id = userPreferenceAnswer.Id,
                    UserPreferenceId = userPreferenceAnswer.UserPreferenceId,
                    Answer = userPreferenceAnswer.Answer
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userPreferenceAnswer response
                response = new UserPreferenceAnswerResponseDto
                {
                    Id = userPreferenceAnswer.Id,
                    UserPreferenceId = userPreferenceAnswer.UserPreferenceId,
                    Answer = userPreferenceAnswer.Answer,
                    DatabaseEntryAt = userPreferenceAnswer.DatabaseEntryAt,
                    LastEditedAt = userPreferenceAnswer.LastEditedAt,
                    Note = userPreferenceAnswer.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserPreferenceAnswer",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreferenceAnswer.got", new
            {
                userPreferenceAnswerId = id,
                gotBy = currentUserId
            });

            //Return the userPreferenceAnswer
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting UserPreferenceAnswers with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserPreferenceAnswerResponseDto>>> GetUserPreferenceAnswers([FromBody] GetUserPreferenceAnswerDto dto)
        {
            //Get userPreferenceAnswer id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserPreferenceAnswers.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserPreferenceId != null)
            {
                query = query.Where(p => dto.UserPreferenceId.Contains(p.UserPreferenceId));
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Search(dto.Query, p => p.Answer);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userPreferenceAnswers with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserPreferenceAnswer> userPreferenceAnswers = await query.ToListAsync();

            //Declare response variable
            List<UserPreferenceAnswerResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserPreferenceAnswers";

                //Create a userPreferenceAnswer response list
                responses = [.. userPreferenceAnswers.Select(userPreferenceAnswer =>
                {
                    //Return a follow response
                    return new UserPreferenceAnswerResponseDto
                    {
                        Id = userPreferenceAnswer.Id,
                        UserPreferenceId = userPreferenceAnswer.UserPreferenceId,
                        Answer = userPreferenceAnswer.Answer
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserPreferenceAnswers";

                //Create a userPreferenceAnswer response list
                responses = [.. userPreferenceAnswers.Select(userPreferenceAnswer => new UserPreferenceAnswerResponseDto
                {
                    Id = userPreferenceAnswer.Id,
                    UserPreferenceId = userPreferenceAnswer.UserPreferenceId,
                    Answer = userPreferenceAnswer.Answer,
                    DatabaseEntryAt = userPreferenceAnswer.DatabaseEntryAt,
                    LastEditedAt = userPreferenceAnswer.LastEditedAt,
                    Note = userPreferenceAnswer.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserPreferenceAnswer",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreferenceAnswer.gotUserPreferenceAnswers", new
            {
                userPreferenceAnswerIds = userPreferenceAnswers.Select(p => p.Id),
                gotBy = currentUserId
            });

            //Return the userPreferenceAnswers
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserPreferenceAnswer for admins.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteUserPreferenceAnswer(Guid id)
        {
            //Get userPreferenceAnswer id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userPreferenceAnswer to delete
            var userPreferenceAnswer = await _db.UserPreferenceAnswers.FirstOrDefaultAsync(p => p.Id == id);
            if (userPreferenceAnswer == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserPreferenceAnswer",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserPreferenceAnswer"
                );

                //Return not found response
                return NotFound(new { message = "UserPreferenceAnswer not found!" });
            }

            //Delete the userPreferenceAnswer
            _db.UserPreferenceAnswers.Remove(userPreferenceAnswer);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserPreferenceAnswer",
                ip,
                userPreferenceAnswer.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userPreferenceAnswer.deleted", new
            {
                userPreferenceAnswerId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "UserPreferenceAnswer deleted successfully!" });
        }
    }
}
