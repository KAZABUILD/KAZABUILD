using KAZABUILD.Application.DTOs.Components.ComponentReview;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Components
{
    /// <summary>
    /// Controller for ComponentReview related endpoints.
    /// Used to store and work with external component reviews.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class ComponentReviewsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new ComponentReview for administration.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddComponentReview([FromBody] CreateComponentReviewDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Component exists
            var component = await _db.Components.FirstOrDefaultAsync(c => c.Id == dto.ComponentId);
            if (component == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "ComponentReview",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Component Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Component not found!" });
            }

            //Create a ComponentReview to add
            ComponentReview componentReview = new()
            {
                SourceUrl = dto.SourceUrl,
                ReviewerName = dto.ReviewerName,
                ComponentId = dto.ComponentId,
                FetchedAt = dto.FetchedAt,
                CreatedAt = dto.CreatedAt,
                Rating = dto.Rating,
                ReviewText = dto.ReviewText,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the componentReview to the database
            _db.ComponentReviews.Add(componentReview);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "ComponentReview",
                ip,
                componentReview.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New ComponentReview Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentReview.created", new
            {
                componentReviewId = componentReview.Id,
                createdBy = currentUserId
            });

            //Return a success response
            return Ok(new { componentReview = "ComponentsPrice created successfully!", id = componentReview.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected ComponentReview's Note for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateComponentReview(Guid id, [FromBody] UpdateComponentReviewDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentReview to edit
            var componentReview = await _db.ComponentReviews.FirstOrDefaultAsync(r => r.Id == id);
            //Check if the componentReview exists
            if (componentReview == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "ComponentReview",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentReview"
                );

                //Return not found response
                return NotFound(new { componentReview = "ComponentReview not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrWhiteSpace(dto.SourceUrl))
            {
                changedFields.Add("SourceUrl: " + componentReview.SourceUrl);

                componentReview.SourceUrl = dto.SourceUrl;
            }
            if (!string.IsNullOrWhiteSpace(dto.ReviewerName))
            {
                changedFields.Add("ReviewerName: " + componentReview.ReviewerName);

                componentReview.ReviewerName = dto.ReviewerName;
            }
            if (dto.ComponentId != null)
            {
                changedFields.Add("ComponentId: " + componentReview.ComponentId);

                componentReview.ComponentId = (Guid)dto.ComponentId;
            }
            if (dto.FetchedAt != null)
            {
                changedFields.Add("FetchedAt: " + componentReview.FetchedAt);

                componentReview.FetchedAt = (DateTime)dto.FetchedAt;
            }
            if (dto.CreatedAt != null)
            {
                changedFields.Add("CreatedAt: " + componentReview.CreatedAt);

                componentReview.CreatedAt = (DateTime)dto.CreatedAt;
            }
            if (dto.Rating != null)
            {
                changedFields.Add("Rating: " + componentReview.Rating);

                componentReview.Rating = (decimal)dto.Rating;
            }
            if (!string.IsNullOrWhiteSpace(dto.ReviewText))
            {
                changedFields.Add("ReviewText: " + componentReview.ReviewText);

                componentReview.ReviewText = dto.ReviewText;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + componentReview.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    componentReview.Note = null;
                else
                    componentReview.Note = dto.Note;
            }

            //Update edit timestamp
            componentReview.LastEditedAt = DateTime.UtcNow;

            //Update the componentReview
            _db.ComponentReviews.Update(componentReview);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description of the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "ComponentReview",
                ip,
                componentReview.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentReview.updated", new
            {
                componentReviewId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentReview = "ComponentReview updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the ComponentReview specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ComponentReviewResponseDto>> GetComponentReview(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentReview to return
            var componentReview = await _db.ComponentReviews.FirstOrDefaultAsync(r => r.Id == id);
            if (componentReview == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "ComponentReview",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentReview"
                );

                //Return not found response
                return NotFound(new { componentReview = "ComponentReview not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ComponentReviewResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create componentReview response
                response = new ComponentReviewResponseDto
                {
                    Id = componentReview.Id,
                    SourceUrl = componentReview.SourceUrl,
                    ReviewerName = componentReview.ReviewerName,
                    ComponentId = componentReview.ComponentId,
                    FetchedAt = componentReview.FetchedAt,
                    CreatedAt = componentReview.CreatedAt,
                    Rating = componentReview.Rating,
                    ReviewText = componentReview.ReviewText
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create componentReview response
                response = new ComponentReviewResponseDto
                {
                    Id = componentReview.Id,
                    SourceUrl = componentReview.SourceUrl,
                    ReviewerName = componentReview.ReviewerName,
                    ComponentId = componentReview.ComponentId,
                    FetchedAt = componentReview.FetchedAt,
                    CreatedAt = componentReview.CreatedAt,
                    Rating = componentReview.Rating,
                    ReviewText = componentReview.ReviewText,
                    DatabaseEntryAt = componentReview.DatabaseEntryAt,
                    LastEditedAt = componentReview.LastEditedAt,
                    Note = componentReview.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentReview",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentReview.got", new
            {
                componentReviewId = id,
                gotBy = currentUserId
            });

            //Return the ComponentReview
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting ComponentReviews with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ComponentReviewResponseDto>>> GetComponentReviews([FromBody] GetComponentReviewDto dto)
        {
            //Get componentReview id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.ComponentReviews.AsNoTracking();

            //Filter by the variables if included
            if (dto.ComponentId != null)
            {
                query = query.Where(r => dto.ComponentId.Contains(r.ComponentId));
            }
            if (dto.FetchedAtStart != null)
            {
                query = query.Where(r => r.FetchedAt >= dto.FetchedAtStart);
            }
            if (dto.FetchedAtEnd != null)
            {
                query = query.Where(r => r.FetchedAt <= dto.FetchedAtEnd);
            }
            if (dto.CreatedAtStart != null)
            {
                query = query.Where(r => r.CreatedAt >= dto.CreatedAtStart);
            }
            if (dto.CreatedAtEnd != null)
            {
                query = query.Where(r => r.CreatedAt <= dto.CreatedAtEnd);
            }
            if (dto.RatingStart != null)
            {
                query = query.Where(r => r.Rating >= dto.RatingStart);
            }
            if (dto.RatingEnd != null)
            {
                query = query.Where(r => r.Rating <= dto.RatingEnd);
            }

            //Apply search
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(r => r.Component).Search(dto.Query, r => r.Component!.Name, r => r.Component!.Manufacturer, r => r.Component!.Release!, r => r.ReviewerName, r => r.FetchedAt!, r => r.CreatedAt!, r => r.ReviewText);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get componentReviews with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<ComponentReview> componentReviews = await query.ToListAsync();

            //Declare response variable
            List<ComponentReviewResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple ComponentReviews";

                //Create a componentReview response list
                responses = [.. componentReviews.Select(componentReview =>
                {
                    //Return a follow response
                    return new ComponentReviewResponseDto
                    {
                        Id = componentReview.Id,
                        SourceUrl = componentReview.SourceUrl,
                        ReviewerName = componentReview.ReviewerName,
                        ComponentId = componentReview.ComponentId,
                        FetchedAt = componentReview.FetchedAt,
                        CreatedAt = componentReview.CreatedAt,
                        Rating = componentReview.Rating,
                        ReviewText = componentReview.ReviewText
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple ComponentReviews";

                //Create a componentReview response list
                responses = [.. componentReviews.Select(componentReview => new ComponentReviewResponseDto
                {
                    Id = componentReview.Id,
                    SourceUrl = componentReview.SourceUrl,
                    ReviewerName = componentReview.ReviewerName,
                    ComponentId = componentReview.ComponentId,
                    FetchedAt = componentReview.FetchedAt,
                    CreatedAt = componentReview.CreatedAt,
                    Rating = componentReview.Rating,
                    ReviewText = componentReview.ReviewText,
                    DatabaseEntryAt = componentReview.DatabaseEntryAt,
                    LastEditedAt = componentReview.LastEditedAt,
                    Note = componentReview.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentReview",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentReview.gotComponentReviews", new
            {
                componentReviewIds = componentReviews.Select(r => r.Id),
                gotBy = currentUserId
            });

            //Return the componentReviews
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected ComponentReview for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteComponentReview(Guid id)
        {
            //Get componentReview id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentReview to delete
            var componentReview = await _db.ComponentReviews.Include(r => r.Comments).FirstOrDefaultAsync(r => r.Id == id);
            if (componentReview == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "ComponentReview",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentReview"
                );

                //Return not found response
                return NotFound(new { componentReview = "ComponentReview not found!" });
            }

            //Remove all related comments
            if (componentReview.Comments.Count != 0)
            {
                _db.UserComments.RemoveRange(componentReview.Comments);
            }

            //Delete the componentReview
            _db.ComponentReviews.Remove(componentReview);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "ComponentReview",
                ip,
                componentReview.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentReview.deleted", new
            {
                componentReviewId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentReview = "ComponentsPrice deleted successfully!" });
        }
    }
}
