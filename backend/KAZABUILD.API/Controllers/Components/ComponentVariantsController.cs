using KAZABUILD.Application.DTOs.Components.ComponentVariant;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Components;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Security.Claims;

namespace KAZABUILD.API.Controllers.Components
{
    /// <summary>
    /// Controller for ComponentVariant related endpoints.
    /// Used to connect a Color with a Component, where the color is an available version of the component.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class ComponentVariantsController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new ComponentVariant for administration.
        /// Multiple colors can be assigned to a Variant if it's multicolored.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddComponentVariant([FromBody] CreateComponentVariantDto dto)
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
                    "ComponentVariant",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Component Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Component not found!" });
            }

            //Create a componentVariant to add
            ComponentVariant componentVariant = new()
            {
                ComponentId = dto.ComponentId,
                IsAvailable = dto.IsAvailable,
                AdditionalPrice = dto.AdditionalPrice,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //For each Color, check if it exists, if it does add it
            foreach (var colorCode in dto.ColorCodes)
            {
                //Return a failure response if the color doesn't exist
                var color = await _db.Colors.FirstOrDefaultAsync(c => c.ColorCode == colorCode);
                if (color == null)
                {
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "POST",
                        "ComponentVariant",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        "Operation Failed - Assigned Color Doesn't Exist"
                    );

                    //Return proper error response
                    return BadRequest(new { message = "Color doesn't exist!" });
                }

                //Create a colorVariant to add
                ColorVariant colorVariant = new()
                {
                    ColorCode = colorCode,
                    ComponentVariantId = componentVariant.Id
                };

                //Add the colorVariant to the database
                _db.ColorVariants.Add(colorVariant);
            }

            //Add the componentVariant to the database
            _db.ComponentVariants.Add(componentVariant);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "ComponentVariant",
                ip,
                componentVariant.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New ComponentVariant Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentVariant.created", new
            {
                componentVariantId = componentVariant.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { componentVariant = "ComponentVariant created successfully!", id = componentVariant.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected ComponentVariant for administration,
        /// Can update multicolored Variants as well.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateComponentVariant(Guid id, [FromBody] UpdateComponentVariantDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentVariant to edit
            var componentVariant = await _db.ComponentVariants.Include(v => v.ColorVariants).FirstOrDefaultAsync(v => v.Id == id);
            //Check if the componentVariant exists
            if (componentVariant == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "ComponentVariant",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentVariant"
                );

                //Return not found response
                return NotFound(new { componentVariant = "ComponentVariant not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (dto.ColorCodes != null)
            {
                changedFields.Add("ColorCodes: " + string.Join("-", componentVariant.ColorVariants.Select(v => v.ColorCode)));

                //Delete old colorVariants
                foreach (var colorVariant in componentVariant.ColorVariants)
                {
                    //Return a failure response if the color doesn't exist
                    var color = await _db.Colors.FirstOrDefaultAsync(c => c.ColorCode == colorVariant.ColorCode);
                    if (color == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "ComponentVariant",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Assigned Color Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Color doesn't exist!" });
                    }

                    //Add the color to the database
                    _db.ColorVariants.Remove(colorVariant);
                }

                //Create new colorVariants
                foreach (var colorCode in dto.ColorCodes)
                {
                    //Return a failure response if the color doesn't exist
                    var color = await _db.Colors.FirstOrDefaultAsync(c => c.ColorCode == colorCode);
                    if (color == null)
                    {
                        //Log failure
                        await _logger.LogAsync(
                            currentUserId,
                            "POST",
                            "ComponentVariant",
                            ip,
                            Guid.Empty,
                            PrivacyLevel.WARNING,
                            "Operation Failed - Assigned Color Doesn't Exist"
                        );

                        //Return proper error response
                        return BadRequest(new { message = "Color doesn't exist!" });
                    }

                    //Create a colorVariant to add
                    ColorVariant colorVariant = new()
                    {
                        ColorCode = colorCode,
                        ComponentVariantId = componentVariant.Id
                    };

                    //Add the colorVariant to the database
                    _db.ColorVariants.Add(colorVariant);
                }

            }
            if (dto.IsAvailable != null)
            {
                changedFields.Add("IsAvailable: " + componentVariant.IsAvailable);

                componentVariant.IsAvailable = (bool)dto.IsAvailable;
            }
            if (dto.AdditionalPrice != null)
            {
                changedFields.Add("AdditionalPrice: " + componentVariant.AdditionalPrice);

                if (dto.AdditionalPrice == 0)
                    componentVariant.AdditionalPrice = null;
                else
                    componentVariant.AdditionalPrice = dto.AdditionalPrice;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + componentVariant.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    componentVariant.Note = null;
                else
                    componentVariant.Note = dto.Note;
            }

            //Update edit timestamp
            componentVariant.LastEditedAt = DateTime.UtcNow;

            //Update the componentVariant
            _db.ComponentVariants.Update(componentVariant);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "ComponentVariant",
                ip,
                componentVariant.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentVariant.updated", new
            {
                componentVariantId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentVariant = "ComponentVariant updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the ComponentVariant specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ComponentVariantResponseDto>> GetComponentVariant(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentVariant to return
            var componentVariant = await _db.ComponentVariants.Include(v => v.ColorVariants).ThenInclude(v => v.Color).FirstOrDefaultAsync(v => v.Id == id);
            if (componentVariant == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "ComponentVariant",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentVariant"
                );

                //Return not found response
                return NotFound(new { componentVariant = "ComponentVariant not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ComponentVariantResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create componentVariant response
                response = new ComponentVariantResponseDto
                {
                    Id = componentVariant.Id,
                    ComponentId = componentVariant.ComponentId,
                    Colors = [.. componentVariant.ColorVariants.Select(v => Tuple.Create(v.ColorCode, v.Color!.ColorName))],
                    IsAvailable = componentVariant.IsAvailable,
                    AdditionalPrice = componentVariant.AdditionalPrice
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create componentVariant response
                response = new ComponentVariantResponseDto
                {
                    Id = componentVariant.Id,
                    ComponentId = componentVariant.ComponentId,
                    Colors = [.. componentVariant.ColorVariants.Select(v => Tuple.Create(v.ColorCode, v.Color!.ColorName))],
                    IsAvailable = componentVariant.IsAvailable,
                    AdditionalPrice = componentVariant.AdditionalPrice,
                    DatabaseEntryAt = componentVariant.DatabaseEntryAt,
                    LastEditedAt = componentVariant.LastEditedAt,
                    Note = componentVariant.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentVariant",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentVariant.got", new
            {
                componentVariantId = id,
                gotBy = currentUserId
            });

            //Return the componentVariant
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting ComponentVariants with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ComponentVariantResponseDto>>> GetComponentVariants([FromBody] GetComponentVariantDto dto)
        {
            //Get componentVariant id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.ComponentVariants.AsNoTracking();

            //Filter by the variables if included
            if (dto.ComponentId != null)
            {
                query = query.Where(v => dto.ComponentId.Contains(v.ComponentId));
            }
            if (dto.ColorCode != null)
            {
                query = query.Include(v => v.ColorVariants).Where(v => dto.ColorCode.Any(col => v.ColorVariants.Any(var => var.ColorCode == col)));
            }
            if (dto.ColorName != null)
            {
                query = query.Include(v => v.ColorVariants).ThenInclude(v => v.Color).Where(v => dto.ColorName.Any(col => v.ColorVariants.Any(var => var.Color!.ColorName == col)));
            }
            if (dto.IsAvailable != null)
            {
                query = query.Where(v => v.IsAvailable == dto.IsAvailable);
            }

            //Apply search
            //This search is special since the color names are stored in the Color model not ComponentVariant
            //This has to be revised since the calculations happen in memory instead of sql
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query
                    .Include(v => v.ColorVariants)
                        .ThenInclude(var => var.Color)
                    .Select(v => new
                    {
                        Variant = v,
                        ColorCodes = string.Join("-", v.ColorVariants.Select(cv => cv.ColorCode)),
                        ColorNames = string.Join("-", v.ColorVariants.Select(cv => cv.Color!.ColorName))
                    })
                    .AsEnumerable()
                    .AsQueryable()
                    .Search(dto.Query, x => x.ColorCodes, x => x.ColorNames)
                    .Select(x => x.Variant);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get componentVariants with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<ComponentVariant> componentVariants = await query.ToListAsync();

            //Declare response variable
            List<ComponentVariantResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple ComponentVariants";

                //Create a componentVariant response list
                responses = [.. componentVariants.Select(componentVariant =>
                {
                    //Return a follow response
                    return new ComponentVariantResponseDto
                    {
                        Id = componentVariant.Id,
                        ComponentId = componentVariant.ComponentId,
                        Colors = [.. componentVariant.ColorVariants.Select(v => Tuple.Create(v.ColorCode, v.Color!.ColorName))],
                        IsAvailable = componentVariant.IsAvailable,
                        AdditionalPrice = componentVariant.AdditionalPrice
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple ComponentVariants";

                //Create a componentVariant response list
                responses = [.. componentVariants.Select(componentVariant => new ComponentVariantResponseDto
                {
                    Id = componentVariant.Id,
                    ComponentId = componentVariant.ComponentId,
                    Colors = [.. componentVariant.ColorVariants.Select(v => Tuple.Create(v.ColorCode, v.Color!.ColorName))],
                    IsAvailable = componentVariant.IsAvailable,
                    AdditionalPrice = componentVariant.AdditionalPrice,
                    DatabaseEntryAt = componentVariant.DatabaseEntryAt,
                    LastEditedAt = componentVariant.LastEditedAt,
                    Note = componentVariant.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentVariant",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentVariant.gotComponentVariants", new
            {
                componentVariantIds = componentVariants.Select(v => v.Id),
                gotBy = currentUserId
            });

            //Return the componentVariants
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected ComponentVariant for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteComponentVariant(Guid id)
        {
            //Get componentVariant id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentVariant to delete
            var componentVariant = await _db.ComponentVariants.FirstOrDefaultAsync(v => v.Id == id);
            if (componentVariant == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "ComponentVariant",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentVariant"
                );

                //Return not found response
                return NotFound(new { componentVariant = "ComponentVariant not found!" });
            }

            //Delete the componentVariant
            _db.ComponentVariants.Remove(componentVariant);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "ComponentVariant",
                ip,
                componentVariant.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentVariant.deleted", new
            {
                componentVariantId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentVariant = "ComponentVariant deleted successfully!" });
        }
    }
}
