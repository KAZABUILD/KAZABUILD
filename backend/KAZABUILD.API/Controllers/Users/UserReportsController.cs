using KAZABUILD.Application.DTOs.Users.UserReport;
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
    /// Controller for UserReport related endpoints.
    /// Allows users to report rule breaking behaviour to the administration for: ForumPosts, Users, Messages, Builds and UserComments.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class UserReportsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for posting a new UserReport.
        /// User can post their own comments, while staff can post for all.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddUserReport([FromBody] CreateUserReportDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the User exists
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserReport",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - User Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "User not found!" });
            }

            //Check if current user has admin permissions or if they are posting a comment for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == dto.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserReport",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Create a userReport to add
            UserReport userReport = new()
            {
                UserId = dto.UserId,
                Reason = dto.Reason,
                Details = dto.Details,
                TargetType = dto.TargetType,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the target id depending on the CommentTargetType
            switch (userReport.TargetType)
            {
                case ReportTargetType.BUILD:
                    //Set the target as build
                    userReport.BuildId = dto.TargetId;

                    //Check if the build exists
                    var build = await _db.Builds.FirstOrDefaultAsync(b => b.Id == dto.TargetId);
                    if (build == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserReport",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Build Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Build not found!" });
                    }

                    break;
                case ReportTargetType.MESSAGE:
                    //Set the target as message
                    userReport.MessageId = dto.TargetId;

                    //Check if the message exists
                    var message = await _db.Messages.FirstOrDefaultAsync(m => m.Id == dto.TargetId);
                    if (message == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserReport",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Message Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Message not found!" });
                    }

                    break;
                case ReportTargetType.COMMENT:
                    //Set the target as comment
                    userReport.UserCommentId = dto.TargetId;

                    //Check if the comment exists
                    var comment = await _db.UserComments.FirstOrDefaultAsync(c => c.Id == dto.TargetId);
                    if (comment == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserReport",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Comment Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Comment not found!" });
                    }

                    break;
                case ReportTargetType.FORUM:
                    //Set the target as post
                    userReport.ForumPostId = dto.TargetId;

                    //Check if the post exists
                    var post = await _db.ForumPosts.FirstOrDefaultAsync(p => p.Id == dto.TargetId);
                    if (post == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserReport",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - ForumPost Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "ForumPost not found!" });
                    }

                    break;
                case ReportTargetType.USER:
                    //Set the target as reported user
                    userReport.ReportedUserId = dto.TargetId;

                    //Check if the reported user exists
                    var reportedUser = await _db.Users.FirstOrDefaultAsync(u => u.Id == dto.TargetId);
                    if (reportedUser == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "UserReport",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Reported User Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Reported user not found!" });
                    }

                    break;
                default:
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "POST",
                        "UserReport",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        "Operation Failed - Invalid Target"
                    );

                    //Return proper unauthorized response
                    return BadRequest(new { message = "Invalid Target Type!" });
            }

            //Add the userReport to the database
            _db.UserReports.Add(userReport);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "UserReport",
                ip,
                userReport.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New UserReport Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userReport.created", new
            {
                userReportId = userReport.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Comment posted successfully!", id = userReport.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected UserReport.
        /// User can modify the reason and details for the Report.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateUserReport(Guid id, [FromBody] UpdateUserReportDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userReport to edit
            var userReport = await _db.UserReports.FirstOrDefaultAsync(r => r.Id == id);
            //Check if the userReport exists
            if (userReport == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "UserReport",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserReport"
                );

                //Return not found response
                return NotFound(new { message = "UserReport not found!" });
            }

            //Check if current user has admin permissions or if they are modifying a follow for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userReport.UserId;

            //Return unauthorized access exception if the user does not have the correct permissions
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "User",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return forbidden response
                return Forbid();
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrWhiteSpace(dto.Details))
            {
                changedFields.Add("Details: " + userReport.Details);

                userReport.Details = dto.Details;
            }
            if (!string.IsNullOrWhiteSpace(dto.Reason))
            {
                changedFields.Add("Reason: " + userReport.Reason);

                userReport.Reason = dto.Reason;
            }
            if (isPrivileged)
            {
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + userReport.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        userReport.Note = null;
                    else
                        userReport.Note = dto.Note;
                }
            }

            //Update edit timestamp
            userReport.LastEditedAt = DateTime.UtcNow;

            //Update the userReport
            _db.UserReports.Update(userReport);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "UserReport",
                ip,
                userReport.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userReport.updated", new
            {
                userReportId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "Comment updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the UserReport specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<UserReportResponseDto>> GetUserReport(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userReport to return
            var userReport = await _db.UserReports.FirstOrDefaultAsync(r => r.Id == id);
            if (userReport == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserReport",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserReport"
                );

                //Return not found response
                return NotFound(new { message = "UserReport not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            UserReportResponseDto response;

            //Check if current user has admin permissions or if they are getting a comment for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == userReport.UserId;

            //Check if has admin privilege or is self
            if(isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create userReport response
                response = new UserReportResponseDto
                {
                    Id = userReport.Id,
                    UserId = userReport.UserId,
                    Reason = userReport.Reason,
                    Details = userReport.Details,
                    TargetType = userReport.TargetType,
                    DatabaseEntryAt = userReport.DatabaseEntryAt,
                    LastEditedAt = userReport.LastEditedAt,
                    Note = userReport.Note,
                };
            }
            else if (isSelf)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create userReport response
                response = new UserReportResponseDto
                {
                    Id = userReport.Id,
                    UserId = userReport.UserId,
                    Reason = userReport.Reason,
                    Details = userReport.Details,
                    TargetType = userReport.TargetType
                };
            }
            else
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "UserReport",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Add the target id depending on the CommentTargetType
            switch (userReport.TargetType)
            {
                case ReportTargetType.BUILD:
                    response.TargetId = userReport.BuildId;
                    break;
                case ReportTargetType.MESSAGE:
                    response.TargetId = userReport.MessageId;
                    break;
                case ReportTargetType.COMMENT:
                    response.TargetId = userReport.UserCommentId;
                    break;
                case ReportTargetType.FORUM:
                    response.TargetId = userReport.ForumPostId;
                    break;
                case ReportTargetType.USER:
                    response.TargetId = userReport.ForumPostId;
                    break;
                default:
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "POST",
                        "UserReport",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        "Operation Failed - Invalid Target"
                    );

                    //Return proper unauthorized response
                    return BadRequest(new { message = "Invalid Target Type!" });
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserReport",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userReport.got", new
            {
                userReportId = id,
                gotBy = currentUserId
            });

            //Return the userReport
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting UserReports with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<UserReportResponseDto>>> GetUserReports([FromBody] GetUserReportDto dto)
        {
            //Get userReport id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Staff.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.UserReports.AsNoTracking();

            //Filter by the variables if included
            if (dto.UserId != null)
            {
                query = query.Where(c => dto.UserId.Contains(c.UserId));
            }
            if (dto.Reason != null)
            {
                query = query.Where(c => dto.Reason.Contains(c.Reason));
            }
            if (dto.TargetType != null)
            {
                query = query.Where(c => dto.TargetType.Contains(c.TargetType));
            }
            if (dto.ForumPostId != null)
            {
                query = query.Where(r => r.ForumPostId != null && dto.ForumPostId.Contains((Guid)r.ForumPostId));
            }
            if (dto.BuildId != null)
            {
                query = query.Where(r => r.BuildId != null && dto.BuildId.Contains((Guid)r.BuildId));
            }
            if (dto.UserCommentId != null)
            {
                query = query.Where(r => r.UserCommentId != null && dto.UserCommentId.Contains((Guid)r.UserCommentId));
            }
            if (dto.MessageId != null)
            {
                query = query.Where(r => r.MessageId != null && dto.MessageId.Contains((Guid)r.MessageId));
            }
            if (dto.ReportedUserId != null)
            {
                query = query.Where(r => r.ReportedUserId != null && dto.ReportedUserId.Contains((Guid)r.ReportedUserId));
            }

            //Apply search based on provided query string
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(r => r.User).Search(dto.Query, r => r.Reason, r => r.Details, r => r.User!.DisplayName);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get userReports with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            //Get all queried userReports as a list
            List<UserReport> userReports = await query.Where(r => r.UserId == currentUserId || isPrivileged).ToListAsync();

            //Declare the failure check boolean
            bool failure = false;

            //Declare response variable
            List<UserReportResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple UserReports";

                //Create a userReport response list
                responses = [.. userReports.Select(userReport =>
                {
                    //Create a response
                    var response = new UserReportResponseDto
                    {
                        Id = userReport.Id,
                        UserId = userReport.UserId,
                        Reason = userReport.Reason,
                        Details = userReport.Details,
                        TargetType = userReport.TargetType
                    };

                    //Add the target id depending on the CommentTargetType
                    switch (userReport.TargetType)
                    {
                        case ReportTargetType.BUILD:
                            response.TargetId = userReport.BuildId;
                            break;
                        case ReportTargetType.MESSAGE:
                            response.TargetId = userReport.MessageId;
                            break;
                        case ReportTargetType.COMMENT:
                            response.TargetId = userReport.UserCommentId;
                            break;
                        case ReportTargetType.FORUM:
                            response.TargetId = userReport.ForumPostId;
                            break;
                        case ReportTargetType.USER:
                            response.TargetId = userReport.ForumPostId;
                            break;
                        default:
                            failure = true;
                            break;
                            
                    }

                    return response;
                })];

            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple UserReports";

                //Create a userReport response list
                responses = [.. userReports.Select(userReport =>
                {
                    //Create a response
                    var response = new UserReportResponseDto
                    {
                        Id = userReport.Id,
                        UserId = userReport.UserId,
                        Reason = userReport.Reason,
                        Details = userReport.Details,
                        TargetType = userReport.TargetType,
                        DatabaseEntryAt = userReport.DatabaseEntryAt,
                        LastEditedAt = userReport.LastEditedAt,
                        Note = userReport.Note
                    };

                    //Add the target id depending on the CommentTargetType
                    switch (userReport.TargetType)
                    {
                        case ReportTargetType.BUILD:
                            response.TargetId = userReport.BuildId;
                            break;
                        case ReportTargetType.MESSAGE:
                            response.TargetId = userReport.MessageId;
                            break;
                        case ReportTargetType.COMMENT:
                            response.TargetId = userReport.UserCommentId;
                            break;
                        case ReportTargetType.FORUM:
                            response.TargetId = userReport.ForumPostId;
                            break;
                        case ReportTargetType.USER:
                            response.TargetId = userReport.ForumPostId;
                            break;
                        default:
                            failure = true;
                            break;

                    }

                    return response;
                })];
            }

            //Return failure if some assignment failed
            if (failure)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "UserReport",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Target"
                );

                //Return proper unauthorized response
                return BadRequest(new { message = "Invalid Target Type!" });
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "UserReport",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userReport.gotUserReports", new
            {
                userReportIds = userReports.Select(r => r.Id),
                gotBy = currentUserId
            });

            //Return the userReports
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected UserReport.
        /// Only staff can delete userReports.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Staff")]
        public async Task<IActionResult> DeleteUserReport(Guid id)
        {
            //Get userReport id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the userReport to delete
            var userReport = await _db.UserReports.FirstOrDefaultAsync(r => r.Id == id);
            if (userReport == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "UserReport",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such UserReport"
                );

                //Return not found response
                return NotFound(new { message = "UserReport not found!" });
            }

            //Delete the userReport
            _db.UserReports.Remove(userReport);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the deletion
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "UserReport",
                ip,
                userReport.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("userReport.deleted", new
            {
                userReportId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { message = "UserReport deleted successfully!" });
        }
    }
}
