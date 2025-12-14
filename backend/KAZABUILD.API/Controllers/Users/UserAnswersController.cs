using KAZABUILD.Application.DTOs.Users.UserAnswer;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Users
{
    /// <summary>
    /// Controller for User Answer related endpoints.
    /// Used to allow users to answer the questionnaire.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    /// <param name="cache"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserAnswersController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher, IMemoryCache cache) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;
        private readonly IMemoryCache _cache = cache;

        /// <summary>
        /// API Endpoint for creating a new UserAnswer.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserAnswer([FromBody] CreateUserAnswerDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the user exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Message",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if the userPreferenceAnswer exists
            var answer = await _db.UserPreferenceAnswers.FirstOrDefaultAsync(u => u.Id == dto.UserPreferenceAnswerId);
            if (answer == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "Message",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - UserPreferenceAnswer Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Answer not found!" });
            }

            //Check if the answer isn't already selected
            var isUserAnswerAvailable = await _db.UserAnswers.FirstOrDefaultAsync(f => f.UserId == dto.UserId && f.UserPreferenceAnswerId == dto.UserPreferenceAnswerId);
            if (isUserAnswerAvailable != null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserAnswer",
                    ip,
                    isUserAnswerAvailable.Id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - The selected users are already present in the follows"
                );

                //Return proper conflict response
                return Conflict(new { message = "User already followed!" });
            }

            //Check if current user has staff permissions or if they are creating a follow for themselves
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserAnswer",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a userAnswer to add
            UserAnswer userAnswer = new()
            {
                UserId = dto.UserId,
                UserPreferenceAnswerId = dto.UserPreferenceAnswerId,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userAnswer to the database
            _db.UserAnswers.Add(userAnswer);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserAnswer",
                ip,
                userAnswer.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserAnswer Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userAnswer.created", new
            {
                userAnswerId = userAnswer.Id,
                craetedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Question answered successfully!", id = userAnswer.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserAnswer.
        /// Only admins can modify them to add notes.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateUserAnswer(Guid id, [FromBody] UpdateUserAnswerDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userAnswer to edit
            var userAnswer = await _db.UserAnswers.FirstOrDefaultAsync(f => f.Id == id);
            if (userAnswer == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserAnswer",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserAnswer"
                );

                //Return not found response
                return NotFound(new { message = "UserAnswer not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + userAnswer.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    userAnswer.Note = null;
                else
                    userAnswer.Note = dto.Note;
            }

            //Update edit timestamp
            userAnswer.LastEditedAt = DateTime.UtcNow;

            //Update the userAnswer
            _db.UserAnswers.Update(userAnswer);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserAnswer",
                ip,
                userAnswer.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userAnswer.updated", new
            {
                userAnswerId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "User Answer note updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserAnswer specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserAnswerResponseDto>> GetUserAnswer(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userAnswer to return
            var userAnswer = await _db.UserAnswers.FirstOrDefaultAsync(f => f.Id == id);
            if (userAnswer == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserAnswer",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserAnswer"
                );

                //Return not found response
                return NotFound(new { message = "User Answer not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserAnswerResponseDto response;

            //Check if current user is getting themselves or if they have staff permissions
            var isSelf = currentUserId == userAnswer.UserId;
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserAnswer",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return not found response
                return Forbid();
            }

            //Check if has staff privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create userAnswer response
                response = new UserAnswerResponseDto
                {
                    Id = userAnswer.Id,
                    UserId = userAnswer.UserId,
                    UserPreferenceAnswerId = userAnswer.UserPreferenceAnswerId
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userAnswer response
                response = new UserAnswerResponseDto
                {
                    Id = userAnswer.Id,
                    UserId = userAnswer.UserId,
                    UserPreferenceAnswerId = userAnswer.UserPreferenceAnswerId,
                    DatabaseEntryAt = userAnswer.DatabaseEntryAt,
                    LastEditedAt = userAnswer.LastEditedAt,
                    Note = userAnswer.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserAnswer",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userAnswer.got", new
            {
                userAnswerId = id,
                gotBy = currentUserId
            });

            //Return the userAnswer
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting UserAnswers with pagination,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserAnswerResponseDto>>> GetUserAnswers([FromBody] GetUserAnswerDto dto)
        {
            //Get userAnswer id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserAnswers.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(f => dto.UserId.Contains(f.UserId));
            }
            if (dto.UserPreferenceAnswerId != null)
            {
                query = query.Where(f => dto.UserPreferenceAnswerId.Contains(f.UserPreferenceAnswerId));
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(f => f.User).Include(f => f.UserPreferenceAnswer).Search(dto.Query, i => i.User!.DisplayName, i => i.UserPreferenceAnswer!.Answer);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userAnswers with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserAnswer> userAnswers = await query.Where(f => f.UserId == currentUserId || isPrivileged).ToListAsync();

            //Declare response variable
            List<UserAnswerResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserAnswers";

                //Create a userAnswer response list
                responses = [.. userAnswers.Select(userAnswer =>
                {
                    //Return a follow response
                    return new UserAnswerResponseDto
                    {
                        Id = userAnswer.Id,
                        UserId = userAnswer.UserId,
                        UserPreferenceAnswerId = userAnswer.UserPreferenceAnswerId
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserAnswers";

                //Create a userAnswer response list
                responses = [.. userAnswers.Select(userAnswer => new UserAnswerResponseDto
                {
                    Id = userAnswer.Id,
                    UserId = userAnswer.UserId,
                    UserPreferenceAnswerId = userAnswer.UserPreferenceAnswerId,
                    DatabaseEntryAt = userAnswer.DatabaseEntryAt,
                    LastEditedAt = userAnswer.LastEditedAt,
                    Note = userAnswer.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserAnswer",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userAnswer.gotUserAnswers", new
            {
                userAnswerIds = userAnswers.Select(f => f.Id),
                gotBy = currentUserId
            });

            //Return the userAnswers
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserAnswer.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteUserAnswer(Guid id)
        {
            //Get userAnswer id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userAnswer to delete
            var userAnswer = await _db.UserAnswers.FirstOrDefaultAsync(f => f.Id == id);
            if (userAnswer == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserAnswer",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserAnswer"
                );

                //Return not found response
                return NotFound(new { message = "UserAnswer not found!" });
            }

            //Check if current user has staff permissions or if it's their own answer
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userAnswer.UserId;

            //Check if the user has correct permissions
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserAnswer",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Delete the userAnswer
            _db.UserAnswers.Remove(userAnswer);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserAnswer",
                ip,
                userAnswer.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userAnswer.deleted", new
            {
                userAnswerId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Answer deleted successfully!" });
        }
    }
}
