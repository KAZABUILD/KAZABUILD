using KAZABUILD.Application.DTOs.Components.ComponentCompatibility;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Components;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Components
{
    //Controller for endpoints related to a connector for Components which are a compatible to another Component
    [ApiController]
    [Route("[controller]")]
    public class ComponentCompatibilityController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new ComponentCompatibility for administration.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddComponentCompatibility([FromBody] CreateComponentCompatibilityDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Component exists
            var component = await _db.Components.FirstOrDefaultAsync(u => u.Id == dto.ComponentId);
            if (component == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "ComponentCompatibility",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Component Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Component not found!" });
            }

            //Check if the Compatible Component exists
            var compatibleComponent = await _db.Components.FirstOrDefaultAsync(u => u.Id == dto.CompatibleComponentId);
            if (compatibleComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "ComponentCompatibility",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned  Compatible Component Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Compatible Component not found!" });
            }

            //Create a componentCompatibility to add
            ComponentCompatibility componentCompatibility = new()
            {
                ComponentId = dto.ComponentId,
                CompatibleComponentId = dto.CompatibleComponentId,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the componentCompatibility to the database
            _db.ComponentCompatibilities.Add(componentCompatibility);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "ComponentCompatibility",
                ip,
                componentCompatibility.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New ComponentCompatibility Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentCompatibility.created", new
            {
                componentCompatibilityId = componentCompatibility.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { componentCompatibility = "Components set as compatible successfully!" });
        }

        /// <summary>
        /// API endpoint for updating the selected ComponentCompatibility's Note for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateComponentCompatibility(Guid id, [FromBody] UpdateComponentCompatibilityDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentCompatibility to edit
            var componentCompatibility = await _db.ComponentCompatibilities.FirstOrDefaultAsync(u => u.Id == id);
            //Check if the componentCompatibility exists
            if (componentCompatibility == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "ComponentCompatibility",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentCompatibility"
                );

                //Return not found response
                return NotFound(new { componentCompatibility = "ComponentCompatibility not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + componentCompatibility.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    componentCompatibility.Note = null;
                else
                    componentCompatibility.Note = dto.Note;
            }

            //Update edit timestamp
            componentCompatibility.LastEditedAt = DateTime.UtcNow;

            //Update the componentCompatibility
            _db.ComponentCompatibilities.Update(componentCompatibility);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description if the Note was edited or not
            var description = changedFields.Count > 0 ? $"Updated {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "ComponentCompatibility",
                ip,
                componentCompatibility.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentCompatibility.updated", new
            {
                componentCompatibilityId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentCompatibility = "ComponentCompatibility updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the ComponentCompatibility specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ComponentCompatibilityResponseDto>> GetComponentCompatibility(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentCompatibility to return
            var componentCompatibility = await _db.ComponentCompatibilities.FirstOrDefaultAsync(u => u.Id == id);
            if (componentCompatibility == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "ComponentCompatibility",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentCompatibility"
                );

                //Return not found response
                return NotFound(new { componentCompatibility = "ComponentCompatibility not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ComponentCompatibilityResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create componentCompatibility response
                response = new ComponentCompatibilityResponseDto
                {
                    Id = componentCompatibility.Id,
                    ComponentId = componentCompatibility.ComponentId,
                    CompatibleComponentId = componentCompatibility.CompatibleComponentId
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create componentCompatibility response
                response = new ComponentCompatibilityResponseDto
                {
                    Id = componentCompatibility.Id,
                    ComponentId = componentCompatibility.ComponentId,
                    CompatibleComponentId = componentCompatibility.CompatibleComponentId,
                    DatabaseEntryAt = componentCompatibility.DatabaseEntryAt,
                    LastEditedAt = componentCompatibility.LastEditedAt,
                    Note = componentCompatibility.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentCompatibility",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentCompatibility.got", new
            {
                componentCompatibilityId = id,
                gotBy = currentUserId
            });

            //Return the ComponentCompatibility
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting ComponentCompatibilities with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ComponentCompatibilityResponseDto>>> GetComponentCompatibilities([FromBody] GetComponentCompatibilityDto dto)
        {
            //Get componentCompatibility id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.ComponentCompatibilities.AsNoTracking();

            //Filter by the variables if included
            if (dto.ComponentId != null)
            {
                query = query.Where(c => dto.ComponentId.Contains(c.ComponentId));
            }
            if (dto.CompatibleComponentId != null)
            {
                query = query.Where(c => dto.CompatibleComponentId.Contains(c.CompatibleComponentId));
            }

            //Apply search
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(c => c.CompatibleComponent).Include(c => c.Component).Search(dto.Query, c => c.Component!.Name, c => c.Component!.Manufacturer, c => c.Component!.Release!, c => c.CompatibleComponent!.Name, c => c.CompatibleComponent!.Manufacturer, c => c.CompatibleComponent!.Release!);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get componentCompatibilities with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<ComponentCompatibility> componentCompatibilities = await query.ToListAsync();

            //Declare response variable
            List<ComponentCompatibilityResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple ComponentCompatibilities";

                //Create a componentCompatibility response list
                responses = [.. componentCompatibilities.Select(componentCompatibility =>
                {
                    //Return a follow response
                    return new ComponentCompatibilityResponseDto
                    {
                        Id = componentCompatibility.Id,
                        ComponentId = componentCompatibility.ComponentId,
                        CompatibleComponentId = componentCompatibility.CompatibleComponentId
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple ComponentCompatibilities";

                //Create a componentCompatibility response list
                responses = [.. componentCompatibilities.Select(componentCompatibility => new ComponentCompatibilityResponseDto
                {
                    Id = componentCompatibility.Id,
                    ComponentId = componentCompatibility.ComponentId,
                    CompatibleComponentId = componentCompatibility.CompatibleComponentId,
                    DatabaseEntryAt = componentCompatibility.DatabaseEntryAt,
                    LastEditedAt = componentCompatibility.LastEditedAt,
                    Note = componentCompatibility.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentCompatibility",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentCompatibility.gotComponentCompatibilities", new
            {
                componentCompatibilityIds = componentCompatibilities.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the componentCompatibilities
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected ComponentCompatibility for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteComponentCompatibility(Guid id)
        {
            //Get componentCompatibility id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentCompatibility to delete
            var componentCompatibility = await _db.ComponentCompatibilities.FirstOrDefaultAsync(u => u.Id == id);
            if (componentCompatibility == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "ComponentCompatibility",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentCompatibility"
                );

                //Return not found response
                return NotFound(new { componentCompatibility = "ComponentCompatibility not found!" });
            }

            //Delete the componentCompatibility
            _db.ComponentCompatibilities.Remove(componentCompatibility);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "ComponentCompatibility",
                ip,
                componentCompatibility.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentCompatibility.deleted", new
            {
                componentCompatibilityId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentCompatibility = "Components no longer compatible!" });
        }
    }
}
