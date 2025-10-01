using KAZABUILD.Application.DTOs.Components.ComponentPart;
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
    public class ComponentPartController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new ComponentPart for administration.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddComponentPart([FromBody] CreateComponentPartDto dto)
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
                    "ComponentPart",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Component Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Component not found!" });
            }

            //Check if the SubComponent exists
            var subComponent = await _db.Components.FirstOrDefaultAsync(u => u.Id == dto.ComponentId);
            if (component == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "ComponentPart",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned SubComponent Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "SubComponent not found!" });
            }

            //Create a componentPart to add
            ComponentPart componentPart = new()
            {
                ComponentId = dto.ComponentId,
                SubComponentId = dto.SubComponentId,
                Amount = dto.Amount,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the componentPart to the database
            _db.ComponentParts.Add(componentPart);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "ComponentPart",
                ip,
                componentPart.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New ComponentPart Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPart.created", new
            {
                componentPartId = componentPart.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { componentPart = "ComponentPart created successfully!" });
        }

        /// <summary>
        /// API endpoint for updating the selected ComponentPart for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateComponentPart(Guid id, [FromBody] UpdateComponentPartDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentPart to edit
            var componentPart = await _db.ComponentParts.FirstOrDefaultAsync(u => u.Id == id);
            //Check if the componentPart exists
            if (componentPart == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "ComponentPart",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentPart"
                );

                //Return not found response
                return NotFound(new { componentPart = "ComponentPart not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + componentPart.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    componentPart.Note = null;
                else
                    componentPart.Note = dto.Note;
            }
            if (dto.Amount != null)
            {
                changedFields.Add("Amount: " + componentPart.Amount);

                componentPart.Amount = (int)dto.Amount;
            }

            //Update edit timestamp
            componentPart.LastEditedAt = DateTime.UtcNow;

            //Update the componentPart
            _db.ComponentParts.Update(componentPart);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description for the updated fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "ComponentPart",
                ip,
                componentPart.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPart.updated", new
            {
                componentPartId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentPart = "ComponentPart updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the ComponentPart specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ComponentPartResponseDto>> GetComponentPart(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentPart to return
            var componentPart = await _db.ComponentParts.FirstOrDefaultAsync(u => u.Id == id);
            if (componentPart == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "ComponentPart",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentPart"
                );

                //Return not found response
                return NotFound(new { componentPart = "ComponentPart not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ComponentPartResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create componentPart response
                response = new ComponentPartResponseDto
                {
                    Id = componentPart.Id,
                    ComponentId = componentPart.ComponentId,
                    SubComponentId = componentPart.SubComponentId,
                    Amount = componentPart.Amount
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create componentPart response
                response = new ComponentPartResponseDto
                {
                    Id = componentPart.Id,
                    ComponentId = componentPart.ComponentId,
                    SubComponentId = componentPart.SubComponentId,
                    Amount = componentPart.Amount,
                    DatabaseEntryAt = componentPart.DatabaseEntryAt,
                    LastEditedAt = componentPart.LastEditedAt,
                    Note = componentPart.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentPart",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPart.got", new
            {
                componentPartId = id,
                gotBy = currentUserId
            });

            //Return the componentPart
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting ComponentParts with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ComponentPartResponseDto>>> GetComponentParts([FromBody] GetComponentPartDto dto)
        {
            //Get componentPart id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.ComponentParts.AsNoTracking();

            //Filter by the variables if included
            if (dto.ComponentId != null)
            {
                query = query.Where(p => dto.ComponentId.Contains(p.ComponentId));
            }
            if (dto.SubComponentId != null)
            {
                query = query.Where(p => dto.SubComponentId.Contains(p.SubComponentId));
            }
            if (dto.AmountStart != null)
            {
                query = query.Where(p => p.Amount >= dto.AmountStart);
            }
            if (dto.AmountEnd != null)
            {
                query = query.Where(p => p.Amount <= dto.AmountEnd);
            }

            //Apply search
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(p => p.Component).Include(p => p.SubComponent).Search(dto.Query, p => p.Component!.Name, p => p.Component!.Manufacturer, p => p.Component!.Release!, p => p.SubComponent!.Name);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get componentParts with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<ComponentPart> componentParts = await query.ToListAsync();

            //Declare response variable
            List<ComponentPartResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple ComponentParts";

                //Create a componentPart response list
                responses = [.. componentParts.Select(componentPart =>
                {
                    //Return a follow response
                    return new ComponentPartResponseDto
                    {
                        Id = componentPart.Id,
                        ComponentId = componentPart.ComponentId,
                        SubComponentId = componentPart.SubComponentId,
                        Amount = componentPart.Amount
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple ComponentParts";

                //Create a componentPart response list
                responses = [.. componentParts.Select(componentPart => new ComponentPartResponseDto
                {
                    Id = componentPart.Id,
                    ComponentId = componentPart.ComponentId,
                    SubComponentId = componentPart.SubComponentId,
                    Amount = componentPart.Amount,
                    DatabaseEntryAt = componentPart.DatabaseEntryAt,
                    LastEditedAt = componentPart.LastEditedAt,
                    Note = componentPart.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentPart",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPart.gotComponentParts", new
            {
                componentPartIds = componentParts.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the componentParts
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected ComponentPart for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteComponentPart(Guid id)
        {
            //Get componentPart id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentPart to delete
            var componentPart = await _db.ComponentParts.FirstOrDefaultAsync(u => u.Id == id);
            if (componentPart == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "ComponentPart",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentPart"
                );

                //Return not found response
                return NotFound(new { componentPart = "ComponentPart not found!" });
            }

            //Delete the componentPart
            _db.ComponentParts.Remove(componentPart);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "ComponentPart",
                ip,
                componentPart.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPart.deleted", new
            {
                componentPartId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentPart = "ComponentPart deleted successfully!" });
        }
    }
}
