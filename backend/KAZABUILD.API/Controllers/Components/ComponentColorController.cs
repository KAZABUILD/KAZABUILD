using KAZABUILD.Application.DTOs.Components.ComponentColor;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
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
    //Controller for endpoints related to a connector for Colors which are assigned to a Component
    [ApiController]
    [Route("[controller]")]
    public class ComponentColorController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new ComponentColor for administration.
        /// Callers can create new colors if they provide a color name.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddComponentColor([FromBody] CreateComponentColorDto dto)
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
                    "ComponentColor",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Component Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Component not found!" });
            }

            //Check if the Color exists, if not create it
            var color = await _db.Colors.FirstOrDefaultAsync(u => u.ColorCode == dto.ColorCode);
            if (color == null && dto.ColorName != null)
            {
                //Create a color to add
                color = new()
                {
                    ColorCode = dto.ColorCode,
                    ColorName = dto.ColorName,
                    DatabaseEntryAt = DateTime.UtcNow,
                    LastEditedAt = DateTime.UtcNow
                };

                //Add the color to the database
                _db.Colors.Add(color);
            }
            //Return a failure response if new color name not provided
            if (color == null && dto.ColorName == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "POST",
                    "ComponentColor",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Color Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Color unable to be created! Provide a Color Name or an existing color." });
            }

            //Create a componentColor to add
            ComponentColor componentColor = new()
            {
                ComponentId = dto.ComponentId,
                ColorCode = dto.ColorCode,
                IsAvailable = dto.IsAvailable,
                AdditionalPrice = dto.AdditionalPrice,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the componentColor to the database
            _db.ComponentColors.Add(componentColor);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "ComponentColor",
                ip,
                componentColor.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New ComponentColor Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentColor.created", new
            {
                componentColorId = componentColor.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { componentColor = "ComponentColor created successfully!", id = componentColor.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected ComponentColor for administration,
        /// can update the Colors's name as well.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateComponentColor(Guid id, [FromBody] UpdateComponentColorDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentColor to edit
            var componentColor = await _db.ComponentColors.FirstOrDefaultAsync(u => u.Id == id);
            //Check if the componentColor exists
            if (componentColor == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "ComponentColor",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentColor"
                );

                //Return not found response
                return NotFound(new { componentColor = "ComponentColor not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrWhiteSpace(dto.ColorName))
            {
                //Get the color
                var color = await _db.Colors.FirstOrDefaultAsync(c => c.ColorCode == componentColor.ColorCode);

                changedFields.Add("ColorName: " + color!.ColorName);

                //Update the color name and last edit date
                color!.ColorName = dto.ColorName;
                color!.LastEditedAt = DateTime.UtcNow;

                //Update the color in the database
                _db.Colors.Update(color);
            }
            if (!string.IsNullOrWhiteSpace(dto.ColorCode))
            {
                changedFields.Add("ColorCode: " + componentColor.ColorCode);

                componentColor.ColorCode = dto.ColorCode;
            }
            if (dto.IsAvailable != null)
            {
                changedFields.Add("IsAvailable: " + componentColor.IsAvailable);

                componentColor.IsAvailable = (bool)dto.IsAvailable;
            }
            if (dto.AdditionalPrice != null)
            {
                changedFields.Add("AdditionalPrice: " + componentColor.AdditionalPrice);

                if (dto.AdditionalPrice == 0)
                    componentColor.AdditionalPrice = null;
                else
                    componentColor.AdditionalPrice = dto.AdditionalPrice;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + componentColor.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    componentColor.Note = null;
                else
                    componentColor.Note = dto.Note;
            }

            //Update edit timestamp
            componentColor.LastEditedAt = DateTime.UtcNow;

            //Update the componentColor
            _db.ComponentColors.Update(componentColor);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "ComponentColor",
                ip,
                componentColor.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentColor.updated", new
            {
                componentColorId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentColor = "ComponentColor updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the ComponentColor specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ComponentColorResponseDto>> GetComponentColor(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentColor to return
            var componentColor = await _db.ComponentColors.FirstOrDefaultAsync(u => u.Id == id);
            if (componentColor == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "ComponentColor",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentColor"
                );

                //Return not found response
                return NotFound(new { componentColor = "ComponentColor not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ComponentColorResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create componentColor response
                response = new ComponentColorResponseDto
                {
                    Id = componentColor.Id,
                    ComponentId = componentColor.ComponentId,
                    ColorCode = componentColor.ColorCode,
                    IsAvailable = componentColor.IsAvailable,
                    AdditionalPrice = componentColor.AdditionalPrice
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create componentColor response
                response = new ComponentColorResponseDto
                {
                    Id = componentColor.Id,
                    ComponentId = componentColor.ComponentId,
                    ColorCode = componentColor.ColorCode,
                    IsAvailable = componentColor.IsAvailable,
                    AdditionalPrice = componentColor.AdditionalPrice,
                    DatabaseEntryAt = componentColor.DatabaseEntryAt,
                    LastEditedAt = componentColor.LastEditedAt,
                    Note = componentColor.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentColor",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentColor.got", new
            {
                componentColorId = id,
                gotBy = currentUserId
            });

            //Return the componentColor
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting ComponentColors with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ComponentColorResponseDto>>> GetComponentColors([FromBody] GetComponentColorDto dto)
        {
            //Get componentColor id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.ComponentColors.AsNoTracking();

            //Filter by the variables if included
            if (dto.ComponentId != null)
            {
                query = query.Where(c => dto.ComponentId.Contains(c.ComponentId));
            }
            if (dto.ColorCode != null)
            {
                query = query.Where(c => dto.ColorCode.Contains(c.ColorCode));
            }
            if (dto.ColorName != null)
            {
                query = query.Include(c => c.Color).Where(c => dto.ColorName.Contains(c.Color!.ColorName));
            }
            if (dto.IsAvailable != null)
            {
                query = query.Where(c => c.IsAvailable == dto.IsAvailable);
            }

            //Apply search
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(c => c.Color).Search(dto.Query, c => c.Color!.ColorName, c => c.ColorCode);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get componentColors with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<ComponentColor> componentColors = await query.ToListAsync();

            //Declare response variable
            List<ComponentColorResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple ComponentColors";

                //Create a componentColor response list
                responses = [.. componentColors.Select(componentColor =>
                {
                    //Return a follow response
                    return new ComponentColorResponseDto
                    {
                        Id = componentColor.Id,
                        ComponentId = componentColor.ComponentId,
                        ColorCode = componentColor.ColorCode,
                        IsAvailable = componentColor.IsAvailable,
                        AdditionalPrice = componentColor.AdditionalPrice
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple ComponentColors";

                //Create a componentColor response list
                responses = [.. componentColors.Select(componentColor => new ComponentColorResponseDto
                {
                    Id = componentColor.Id,
                    ComponentId = componentColor.ComponentId,
                    ColorCode = componentColor.ColorCode,
                    IsAvailable = componentColor.IsAvailable,
                    AdditionalPrice = componentColor.AdditionalPrice,
                    DatabaseEntryAt = componentColor.DatabaseEntryAt,
                    LastEditedAt = componentColor.LastEditedAt,
                    Note = componentColor.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentColor",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentColor.gotComponentColors", new
            {
                componentColorIds = componentColors.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the componentColors
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected ComponentColor for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteComponentColor(Guid id)
        {
            //Get componentColor id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentColor to delete
            var componentColor = await _db.ComponentColors.FirstOrDefaultAsync(u => u.Id == id);
            if (componentColor == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "ComponentColor",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentColor"
                );

                //Return not found response
                return NotFound(new { componentColor = "ComponentColor not found!" });
            }

            //Delete the componentColor
            _db.ComponentColors.Remove(componentColor);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "ComponentColor",
                ip,
                componentColor.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentColor.deleted", new
            {
                componentColorId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentColor = "ComponentColor deleted successfully!" });
        }
    }
}
