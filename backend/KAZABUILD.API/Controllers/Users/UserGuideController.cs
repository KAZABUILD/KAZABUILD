using KAZABUILD.Application.DTOs.Users.UserGuide;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Users
{
    /// <summary>
    /// Controller for Guide related endpoints.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserGuideController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for adding a UserGuide for staff.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> AddUserGuide([FromBody] CreateUserGuideDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Create a userGuide to add
            UserGuide userGuide = new()
            {
                Title = dto.Title,
                Text = dto.Text,
                Author = dto.Author,
                Category = dto.Category,
                TimeToRead = dto.TimeToRead,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the userGuide to the database
            _db.UserGuides.Add(userGuide);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserGuide",
                ip,
                userGuide.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserGuide Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userGuide.created", new
            {
                userGuideId = userGuide.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Guide left successfully!", id = userGuide.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserGuide for staff.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> UpdateUserGuide(Guid id, [FromBody] UpdateUserGuideDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userGuide to edit
            var userGuide = await _db.UserGuides.FirstOrDefaultAsync(g => g.Id == id);
            //Check if the userGuide exists
            if (userGuide == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserGuide",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserGuide"
                );

                //Return not found response
                return NotFound(new { message = "Guide not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrWhiteSpace(dto.Title))
            {
                changedFields.Add("Title: " + userGuide.Title);

                userGuide.Title = dto.Title;
            }
            if (!string.IsNullOrWhiteSpace(dto.Text))
            {
                changedFields.Add("Text: " + userGuide.Text);

                userGuide.Text = dto.Text;
            }
            if (!string.IsNullOrWhiteSpace(dto.Author))
            {
                changedFields.Add("Author: " + userGuide.Author);

                userGuide.Author = dto.Author;
            }
            if (!string.IsNullOrWhiteSpace(dto.Category))
            {
                changedFields.Add("Category: " + userGuide.Category);

                userGuide.Category = dto.Category;
            }
            if (dto.TimeToRead != null)
            {
                changedFields.Add("TimeToRead: " + userGuide.TimeToRead);

                userGuide.TimeToRead = (decimal)dto.TimeToRead;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + userGuide.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    userGuide.Note = null;
                else
                    userGuide.Note = dto.Note;
            }

            //Update edit timestamp
            userGuide.LastEditedAt = DateTime.UtcNow;

            //Update the userGuide
            _db.UserGuides.Update(userGuide);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserGuide",
                ip,
                userGuide.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userGuide.updated", new
            {
                userGuideId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Guide updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserGuide specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserGuideResponseDto>> GetUserGuide(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userGuide to return
            var userGuide = await _db.UserGuides.FirstOrDefaultAsync(g => g.Id == id);
            if (userGuide == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserGuide",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserGuide"
                );

                //Return not found response
                return NotFound(new { message = "Guide not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserGuideResponseDto response;

            //Check if current user has staff permissions or if they are modifying their own feedback
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Check if has staff privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create userGuide response
                response = new UserGuideResponseDto
                {
                    Id = userGuide.Id,
                    Title = userGuide.Title,
                    Text = userGuide.Text,
                    Author = userGuide.Author,
                    Category = userGuide.Category,
                    TimeToRead = userGuide.TimeToRead
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userGuide response
                response = new UserGuideResponseDto
                {
                    Id = userGuide.Id,
                    Title = userGuide.Title,
                    Text = userGuide.Text,
                    Author = userGuide.Author,
                    Category = userGuide.Category,
                    TimeToRead = userGuide.TimeToRead,
                    DatabaseEntryAt = userGuide.DatabaseEntryAt,
                    LastEditedAt = userGuide.LastEditedAt,
                    Note = userGuide.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserGuide",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userGuide.got", new
            {
                userGuideId = id,
                gotBy = currentUserId
            });

            //Return the userGuide
            return Ok(response);
        }

        /// <summary>
        ///  API endpoint for getting UserGuide with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserGuideResponseDto>>> GetUserGuide([FromBody] GetUserGuideDto dto)
        {
            //Get userGuide id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has staff permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserGuides.AsNoTracking();

            //Filter by the variables if included
            if (dto.Title != null)
            {
                query = query.Where(f => dto.Title.Contains(f.Title));
            }
            if (dto.Author != null)
            {
                query = query.Where(f => dto.Author.Contains(f.Author));
            }
            if (dto.Category != null)
            {
                query = query.Where(f => dto.Category.Contains(f.Category));
            }
            if (dto.TimeToReadStart != null)
            {
                query = query.Where(f => f.TimeToRead >= dto.TimeToReadStart);
            }
            if (dto.TimeToReadEnd != null)
            {
                query = query.Where(f => f.TimeToRead <= dto.TimeToReadEnd);
            }
            if (dto.PostedAtStart != null)
            {
                query = query.Where(f => f.PostedAt >= dto.PostedAtStart);
            }
            if (dto.PostedAtEnd != null)
            {
                query = query.Where(f => f.PostedAt <= dto.PostedAtEnd);
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Search(dto.Query, f => f.Title, f => f.Author, f => f.Category, f => f.PostedAt);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userGuide with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<UserGuide> userGuide = await query.ToListAsync();

            //Declare response variable
            List<UserGuideResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserGuide";

                //Create a userGuide response list
                responses = [.. userGuide.Select(userGuide =>
                {
                    //Return a follow response
                    return new UserGuideResponseDto
                    {
                        Id = userGuide.Id,
                        Title = userGuide.Title,
                        Text = userGuide.Text,
                        Author = userGuide.Author,
                        Category = userGuide.Category,
                        TimeToRead = userGuide.TimeToRead
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserGuide";

                //Create a userGuide response list
                responses = [.. userGuide.Select(userGuide => new UserGuideResponseDto
                {
                    Id = userGuide.Id,
                    Title = userGuide.Title,
                    Text = userGuide.Text,
                    Author = userGuide.Author,
                    Category = userGuide.Category,
                    TimeToRead = userGuide.TimeToRead,
                    DatabaseEntryAt = userGuide.DatabaseEntryAt,
                    LastEditedAt = userGuide.LastEditedAt,
                    Note = userGuide.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserGuide",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userGuide.gotUserGuide", new
            {
                userGuideIds = userGuide.Select(f => f.Id),
                gotBy = currentUserId
            });

            //Return the userGuide
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserGuide for staff.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> DeleteUserGuide(Guid id)
        {
            //Get userGuide id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userGuide to delete
            var userGuide = await _db.UserGuides.FirstOrDefaultAsync(f => f.Id == id);
            if (userGuide == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserGuide",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserGuide"
                );

                //Return not found response
                return NotFound(new { message = "UserGuide not found!" });
            }

            //Delete the userGuide
            _db.UserGuides.Remove(userGuide);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserGuide",
                ip,
                userGuide.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userGuide.deleted", new
            {
                userGuideId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "UserGuide deleted successfully!" });
        }
    }
}
