using KAZABUILD.Application.DTOs.Builds.BuildComponent;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Builds
{
    /// <summary>
    /// Controller for BuildComponent related endpoints.
    /// Allows users to add Components to Builds.
    /// Users can add components to their own builds, while admins to all.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class BuildComponentsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new BuildComponent.
        /// Used to add a new component to the build.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> AddBuildComponent([FromBody] CreateBuildComponentDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the build exists
            var build = await _db.Builds.FirstOrDefaultAsync(b => b.Id == dto.BuildId);
            if (build == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Build Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Build not found!" });
            }

            //Check if the component exists
            var component = await _db.Components.FirstOrDefaultAsync(c => c.Id == dto.ComponentId);
            if (component == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Component Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Component not found!" });
            }

            //Check if current user has admin permissions or if they are adding a component to their own build
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == build.UserId;

            //Check if the user has correct permission
            if (!isPrivileged && !isSelf)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return proper unauthorized response
                return Forbid();
            }

            //Check if the user isn't modifying an auto-generated build
            if (!isPrivileged && build.Status == BuildStatus.GENERATED)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Build Status"
                );

                //Return proper error response
                return BadRequest(new { message = "Users cannot modify auto-generated builds!" });
            }

            //Create a buildComponent to add
            BuildComponent buildComponent = new()
            {
                BuildId = dto.BuildId,
                ComponentId = dto.ComponentId,
                Quantity = dto.Quantity,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the buildComponent to the database
            _db.BuildComponents.Add(buildComponent);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "BuildComponent",
                ip,
                buildComponent.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New BuildComponent Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildComponent.created", new
            {
                buildComponentId = buildComponent.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { buildComponent = "Component added to the build successfully!", id = buildComponent.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected BuildComponent's quantity and note.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> UpdateBuildComponent(Guid id, [FromBody] UpdateBuildComponentDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildComponent to edit
            var buildComponent = await _db.BuildComponents.Include(c => c.Build).FirstOrDefaultAsync(c => c.Id == id);
            //Check if the buildComponent exists
            if (buildComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "BuildComponent",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildComponent"
                );

                //Return not found response
                return NotFound(new { buildComponent = "BuildComponent not found!" });
            }

            //Check if current user has admin permissions or if they are modifying their own build
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == buildComponent.Build!.UserId;

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

            //Check if the user isn't modifying an auto-generated build
            if (!isPrivileged && buildComponent.Build.Status == BuildStatus.GENERATED)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Invalid Build Status"
                );

                //Return proper error response
                return BadRequest(new { message = "Users cannot modify auto-generated builds!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Quantity != null)
            {
                changedFields.Add("Quantity: " + buildComponent.Quantity);

                buildComponent.Quantity = (int)dto.Quantity;
            }
            if (isPrivileged)
            {
                if (dto.Note != null)
                {
                    changedFields.Add("Note: " + buildComponent.Note);

                    if (string.IsNullOrWhiteSpace(dto.Note))
                        buildComponent.Note = null;
                    else
                        buildComponent.Note = dto.Note;
                }
            }

            //Update edit timestamp
            buildComponent.LastEditedAt = DateTime.UtcNow;

            //Update the buildComponent
            _db.BuildComponents.Update(buildComponent);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "BuildComponent",
                ip,
                buildComponent.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildComponent.updated", new
            {
                buildComponentId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { buildComponent = "BuildComponent updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the BuildComponent specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<BuildComponentResponseDto>> GetBuildComponent(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildComponent to return
            var buildComponent = await _db.BuildComponents.Include(c => c.Build).FirstOrDefaultAsync(c => c.Id == id);
            if (buildComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "BuildComponent",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildComponent"
                );

                //Return not found response
                return NotFound(new { buildComponent = "BuildComponent not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            BuildComponentResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == buildComponent.Build!.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged && (buildComponent.Build.Status == BuildStatus.DRAFT || buildComponent.Build.Status == BuildStatus.GENERATED))
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "BuildComponent",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return not found response
                return Forbid();
            }

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create buildComponent response
                response = new BuildComponentResponseDto
                {
                    Id = buildComponent.Id,
                    BuildId = buildComponent.BuildId,
                    ComponentId = buildComponent.ComponentId,
                    Quantity = buildComponent.Quantity
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create buildComponent response
                response = new BuildComponentResponseDto
                {
                    Id = buildComponent.Id,
                    BuildId = buildComponent.BuildId,
                    ComponentId = buildComponent.ComponentId,
                    Quantity = buildComponent.Quantity,
                    DatabaseEntryAt = buildComponent.DatabaseEntryAt,
                    LastEditedAt = buildComponent.LastEditedAt,
                    Note = buildComponent.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "BuildComponent",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildComponent.got", new
            {
                buildComponentId = id,
                gotBy = currentUserId
            });

            //Return the buildComponent
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting BuildComponents with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<BuildComponentResponseDto>>> GetBuildComponents([FromBody] GetBuildComponentDto dto)
        {
            //Get buildComponent id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.BuildComponents.Include(c => c.Build).AsNoTracking();

            //Filter by the variables if included
            if (dto.BuildId != null)
            {
                query = query.Where(c => dto.BuildId.Contains(c.BuildId));
            }
            if (dto.ComponentId != null)
            {
                query = query.Where(c => dto.ComponentId.Contains(c.ComponentId));
            }
            if (dto.QuantityStart != null)
            {
                query = query.Where(c => c.Quantity >= dto.QuantityStart);
            }
            if (dto.QuantityEnd != null)
            {
                query = query.Where(c => c.Quantity <= dto.QuantityEnd);
            }

            //Apply search based om credentials
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(c => c.Build).Include(c => c.Component).Search(dto.Query, c => c.Build!.Name, c => c.Component!.Name);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get buildComponents with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<BuildComponent> buildComponents = await query.Where(b => b.Build!.UserId == currentUserId || isPrivileged || (b.Build!.Status != BuildStatus.DRAFT && b.Build!.Status != BuildStatus.GENERATED)).ToListAsync();

            //Declare response variable
            List<BuildComponentResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple BuildComponents";

                //Create a buildComponent response list
                responses = [.. buildComponents.Select(buildComponent =>
                {
                    //Return a follow response
                    return new BuildComponentResponseDto
                    {
                        Id = buildComponent.Id,
                        BuildId = buildComponent.BuildId,
                        ComponentId = buildComponent.ComponentId,
                        Quantity = buildComponent.Quantity
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple BuildComponents";

                //Create a buildComponent response list
                responses = [.. buildComponents.Select(buildComponent => new BuildComponentResponseDto
                {
                    Id = buildComponent.Id,
                    BuildId = buildComponent.BuildId,
                    ComponentId = buildComponent.ComponentId,
                    Quantity = buildComponent.Quantity,
                    DatabaseEntryAt = buildComponent.DatabaseEntryAt,
                    LastEditedAt = buildComponent.LastEditedAt,
                    Note = buildComponent.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "BuildComponent",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildComponent.gotBuildComponents", new
            {
                buildComponentIds = buildComponents.Select(c => c.Id),
                gotBy = currentUserId
            });

            //Return the buildComponents
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected BuildComponent.
        /// Removes a component from the build.
        /// Users can remove components from their own builds, while admins from all.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<IActionResult> DeleteBuildComponent(Guid id)
        {
            //Get buildComponent id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the buildComponent to delete
            var buildComponent = await _db.BuildComponents.Include(c => c.Build).FirstOrDefaultAsync(c => c.Id == id);
            if (buildComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "BuildComponent",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such BuildComponent"
                );

                //Return not found response
                return NotFound(new { buildComponent = "BuildComponent not found!" });
            }

            //Check if current user has admin permissions or if they are creating a follow for themselves
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());
            var isSelf = currentUserId == buildComponent.Build!.UserId;

            //Return an unauthorized response if the user doesn't have correct privileges
            if (!isSelf && !isPrivileged)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "BuildComponent",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Unauthorized Access"
                );

                //Return not found response
                return Forbid();
            }

            //Delete the buildComponent
            _db.BuildComponents.Remove(buildComponent);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "BuildComponent",
                ip,
                buildComponent.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("buildComponent.deleted", new
            {
                buildComponentId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { buildComponent = "BuildComponent deleted successfully!" });
        }
    }
}
