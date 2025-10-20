using KAZABUILD.Application.DTOs.Components.SubComponentPart;
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
    /// <summary>
    /// Controller for SubComponentPart related endpoints.
    /// Used to connect SubComponents with other SubComponent which they are a part of.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class SubComponentPartsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new SubComponentPart for administration.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddSubComponentPart([FromBody] CreateSubComponentPartDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if the Main SubComponent exists
            var mainSubComponent = await _db.SubComponents.FirstOrDefaultAsync(s => s.Id == dto.MainSubComponentId);
            if (mainSubComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "SubComponentPart",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned SubComponent Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "SubComponent not found!" });
            }

            //Check if the SubComponent exists
            var subComponent = await _db.SubComponents.FirstOrDefaultAsync(s => s.Id == dto.SubComponentId);
            if (subComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "SubComponentPart",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned SubComponent Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "SubComponent not found!" });
            }

            //Check if the subComponent isn't already a part of the subComponent
            var part = await _db.SubComponentParts.FirstOrDefaultAsync(p => p.MainSubComponentId == dto.MainSubComponentId && p.SubComponentId == dto.SubComponentId);
            if (part != null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "BuildInteraction",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - SubComponent Already A Part Of This SubComponent"
                );

                //Return proper error response
                return BadRequest(new { message = "Part already exists!" });
            }

            //Create a subComponentPart to add
            SubComponentPart subComponentPart = new()
            {
                MainSubComponentId = dto.MainSubComponentId,
                SubComponentId = dto.SubComponentId,
                Amount = dto.Amount,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the subComponentPart to the database
            _db.SubComponentParts.Add(subComponentPart);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "SubComponentPart",
                ip,
                subComponentPart.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New SubComponentPart Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponentPart.created", new
            {
                subComponentPartId = subComponentPart.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { subComponentPart = "SubComponentPart created successfully!", id = subComponentPart.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected SubComponentPart's fields for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateSubComponentPart(Guid id, [FromBody] UpdateSubComponentPartDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the subComponentPart to edit
            var subComponentPart = await _db.SubComponentParts.FirstOrDefaultAsync(p => p.Id == id);

            //Check if the subComponentPart exists
            if (subComponentPart == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "SubComponentPart",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such SubComponentPart"
                );

                //Return not found response
                return NotFound(new { subComponentPart = "SubComponentPart not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.Amount != null)
            {
                changedFields.Add("Amount: " + subComponentPart.Amount);

                subComponentPart.Amount = (int)dto.Amount;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + subComponentPart.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    subComponentPart.Note = null;
                else
                    subComponentPart.Note = dto.Note;
            }

            //Update edit timestamp
            subComponentPart.LastEditedAt = DateTime.UtcNow;

            //Update the subComponentPart
            _db.SubComponentParts.Update(subComponentPart);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description if the note was edited or not
            var description = changedFields.Count > 0 ? $"Updated {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "SubComponentPart",
                ip,
                subComponentPart.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponentPart.updated", new
            {
                subComponentPartId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { subComponentPart = "SubComponentPart updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the SubComponentPart specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<SubComponentPartResponseDto>> GetSubComponentPart(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the subComponentPart to return
            var subComponentPart = await _db.SubComponentParts.FirstOrDefaultAsync(p => p.Id == id);
            if (subComponentPart == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "SubComponentPart",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such SubComponentPart"
                );

                //Return not found response
                return NotFound(new { subComponentPart = "SubComponentPart not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            SubComponentPartResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create subComponentPart response
                response = new SubComponentPartResponseDto
                {
                    Id = subComponentPart.Id,
                    MainSubComponentId = subComponentPart.MainSubComponentId,
                    SubComponentId = subComponentPart.SubComponentId,
                    Amount = subComponentPart.Amount
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create subComponentPart response
                response = new SubComponentPartResponseDto
                {
                    Id = subComponentPart.Id,
                    MainSubComponentId = subComponentPart.MainSubComponentId,
                    SubComponentId = subComponentPart.SubComponentId,
                    Amount = subComponentPart.Amount,
                    DatabaseEntryAt = subComponentPart.DatabaseEntryAt,
                    LastEditedAt = subComponentPart.LastEditedAt,
                    Note = subComponentPart.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "SubComponentPart",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponentPart.got", new
            {
                subComponentPartId = id,
                gotBy = currentUserId
            });

            //Return the subComponentPart
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting SubComponentParts with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<SubComponentPartResponseDto>>> GetSubComponentParts([FromBody] GetSubComponentPartDto dto)
        {
            //Get subComponentPart id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.SubComponentParts.AsNoTracking();

            //Filter by the variables if included
            if (dto.MainSubComponentId != null)
            {
                query = query.Where(p => dto.MainSubComponentId.Contains(p.MainSubComponentId));
            }
            if (dto.SubComponentId != null)
            {
                query = query.Where(p => dto.SubComponentId.Contains(p.SubComponentId));
            }
            if (dto.AmountStart != null)
            {
                query = query.Where(p => dto.AmountStart <= p.Amount);
            }
            if (dto.AmountEnd != null)
            {
                query = query.Where(p => dto.AmountEnd >= p.Amount);
            }

            //Apply search
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(p => p.SubComponent).Include(p => p.MainSubComponent).Search(dto.Query, p => p.MainSubComponent!.Name, p => p.SubComponent!.Name);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get subComponentParts with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<SubComponentPart> subComponentParts = await query.ToListAsync();

            //Declare response variable
            List<SubComponentPartResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple SubComponentParts";

                //Create a subComponentPart response list
                responses = [.. subComponentParts.Select(subComponentPart =>
                {
                    //Return a follow response
                    return new SubComponentPartResponseDto
                    {
                        Id = subComponentPart.Id,
                        MainSubComponentId = subComponentPart.MainSubComponentId,
                        SubComponentId = subComponentPart.SubComponentId,
                        Amount = subComponentPart.Amount
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple SubComponentParts";

                //Create a subComponentPart response list
                responses = [.. subComponentParts.Select(subComponentPart => new SubComponentPartResponseDto
                {
                    Id = subComponentPart.Id,
                    MainSubComponentId = subComponentPart.MainSubComponentId,
                    SubComponentId = subComponentPart.SubComponentId,
                    Amount = subComponentPart.Amount,
                    DatabaseEntryAt = subComponentPart.DatabaseEntryAt,
                    LastEditedAt = subComponentPart.LastEditedAt,
                    Note = subComponentPart.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "SubComponentPart",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponentPart.gotSubComponentParts", new
            {
                subComponentPartIds = subComponentParts.Select(p => p.Id),
                gotBy = currentUserId
            });

            //Return the subComponentParts
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected SubComponentPart for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteSubComponentPart(Guid id)
        {
            //Get subComponentPart id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the subComponentPart to delete
            var subComponentPart = await _db.SubComponentParts.FirstOrDefaultAsync(p => p.Id == id);
            if (subComponentPart == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "SubComponentPart",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such SubComponentPart"
                );

                //Return not found response
                return NotFound(new { subComponentPart = "SubComponentPart not found!" });
            }

            //Delete the subComponentPart
            _db.SubComponentParts.Remove(subComponentPart);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "SubComponentPart",
                ip,
                subComponentPart.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponentPart.deleted", new
            {
                subComponentPartId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { subComponentPart = "SubComponentPart deleted successfully!" });
        }
    }
}
