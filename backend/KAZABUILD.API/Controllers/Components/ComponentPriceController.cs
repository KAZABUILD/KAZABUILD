using KAZABUILD.Application.DTOs.Components.ComponentPrice;
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
    /// <summary>
    /// Controller for ComponentPrice related endpoints.
    /// Used to store and operate with price listing in external online shops.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class ComponentPriceController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new ComponentPrice for administration.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddComponentPrice([FromBody] CreateComponentPriceDto dto)
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
                    "ComponentPrice",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    "Operation Failed - Assigned Component Doesn't Exist"
                );

                //Return proper error response
                return BadRequest(new { message = "Component not found!" });
            }

            //Create a componentPrice to add
            ComponentPrice componentPrice = new()
            {
                SourceUrl = dto.SourceUrl,
                ComponentId = dto.ComponentId,
                VendorName = dto.VendorName,
                FetchedAt = dto.FetchedAt,
                Price = dto.Price,
                Currency = dto.Currency,
                DatabaseEntryAt = DateTime.UtcNow,
                LastEditedAt = DateTime.UtcNow
            };

            //Add the componentPrice to the database
            _db.ComponentPrices.Add(componentPrice);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "ComponentPrice",
                ip,
                componentPrice.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New ComponentPrice Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPrice.created", new
            {
                componentPriceId = componentPrice.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { componentPrice = "ComponentsPrice created successfully!", id = componentPrice.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected ComponentPrice's Note for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateComponentPrice(Guid id, [FromBody] UpdateComponentPriceDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentPrice to edit
            var componentPrice = await _db.ComponentPrices.FirstOrDefaultAsync(u => u.Id == id);
            //Check if the componentPrice exists
            if (componentPrice == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "ComponentPrice",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentPrice"
                );

                //Return not found response
                return NotFound(new { componentPrice = "ComponentPrice not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update allowed fields
            if (!string.IsNullOrWhiteSpace(dto.SourceUrl))
            {
                changedFields.Add("SourceUrl: " + componentPrice.SourceUrl);

                componentPrice.SourceUrl = dto.SourceUrl;
            }
            if (!string.IsNullOrWhiteSpace(dto.VendorName))
            {
                changedFields.Add("VendorName: " + componentPrice.VendorName);

                componentPrice.VendorName = dto.VendorName;
            }
            if (dto.FetchedAt != null)
            {
                changedFields.Add("FetchedAt: " + componentPrice.FetchedAt);

                if (dto.FetchedAt == DateTime.MinValue)
                    componentPrice.Note = null;
                else
                    componentPrice.Note = dto.Note;
            }
            if (dto.Price != null)
            {
                changedFields.Add("Price: " + componentPrice.Price);

                componentPrice.Price = (decimal)dto.Price;
            }
            if (!string.IsNullOrWhiteSpace(dto.Currency))
            {
                changedFields.Add("Currency: " + componentPrice.Currency);

                componentPrice.Currency = dto.Currency;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + componentPrice.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    componentPrice.Note = null;
                else
                    componentPrice.Note = dto.Note;
            }

            //Update edit timestamp
            componentPrice.LastEditedAt = DateTime.UtcNow;

            //Update the componentPrice
            _db.ComponentPrices.Update(componentPrice);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description of the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "ComponentPrice",
                ip,
                componentPrice.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPrice.updated", new
            {
                componentPriceId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentPrice = "ComponentPrice updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the ComponentPrice specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<ComponentPriceResponseDto>> GetComponentPrice(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentPrice to return
            var componentPrice = await _db.ComponentPrices.FirstOrDefaultAsync(u => u.Id == id);
            if (componentPrice == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "ComponentPrice",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentPrice"
                );

                //Return not found response
                return NotFound(new { componentPrice = "ComponentPrice not found!" });
            }

            //Log Description string declaration
            string logDescription;

            //Declare response variable
            ComponentPriceResponseDto response;

            //Check if current user is getting themselves or if they have admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";

                //Create componentPrice response
                response = new ComponentPriceResponseDto
                {
                    Id = componentPrice.Id,
                    SourceUrl = componentPrice.SourceUrl,
                    ComponentId = componentPrice.ComponentId,
                    VendorName = componentPrice.VendorName,
                    FetchedAt = componentPrice.FetchedAt,
                    Price = componentPrice.Price,
                    Currency = componentPrice.Currency
                };
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Create componentPrice response
                response = new ComponentPriceResponseDto
                {
                    Id = componentPrice.Id,
                    SourceUrl = componentPrice.SourceUrl,
                    ComponentId = componentPrice.ComponentId,
                    VendorName = componentPrice.VendorName,
                    FetchedAt = componentPrice.FetchedAt,
                    Price = componentPrice.Price,
                    Currency = componentPrice.Currency,
                    DatabaseEntryAt = componentPrice.DatabaseEntryAt,
                    LastEditedAt = componentPrice.LastEditedAt,
                    Note = componentPrice.Note,
                };
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentPrice",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPrice.got", new
            {
                componentPriceId = id,
                gotBy = currentUserId
            });

            //Return the ComponentPrice
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting ComponentPrices with pagination and search,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<ComponentPriceResponseDto>>> GetComponentPrices([FromBody] GetComponentPriceDto dto)
        {
            //Get componentPrice id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.ComponentPrices.AsNoTracking();

            //Filter by the variables if included
            if (dto.ComponentId != null)
            {
                query = query.Where(p => dto.ComponentId.Contains(p.ComponentId));
            }
            if (dto.VendorName != null)
            {
                query = query.Where(p => dto.VendorName.Contains(p.VendorName));
            }
            if (dto.FetchedAtStart != null)
            {
                query = query.Where(p => p.FetchedAt >= dto.FetchedAtStart);
            }
            if (dto.FetchedAtEnd != null)
            {
                query = query.Where(p => p.FetchedAt <= dto.FetchedAtEnd);
            }
            if (dto.Currency != null)
            {
                query = query.Where(p => dto.Currency.Contains(p.Currency));
            }

            //Apply search
            if (!string.IsNullOrWhiteSpace(dto.Query))
            {
                query = query.Include(p => p.Component).Search(dto.Query, p => p.Component!.Name, p => p.Component!.Manufacturer, p => p.Component!.Release!, p => p.VendorName, p => p.FetchedAt!);
            }

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get componentPrices with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<ComponentPrice> componentPrices = await query.ToListAsync();

            //Declare response variable
            List<ComponentPriceResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple ComponentPrices";

                //Create a componentPrice response list
                responses = [.. componentPrices.Select(componentPrice =>
                {
                    //Return a follow response
                    return new ComponentPriceResponseDto
                    {
                        Id = componentPrice.Id,
                        SourceUrl = componentPrice.SourceUrl,
                        ComponentId = componentPrice.ComponentId,
                        VendorName = componentPrice.VendorName,
                        FetchedAt = componentPrice.FetchedAt,
                        Price = componentPrice.Price,
                        Currency = componentPrice.Currency
                    };
                })];
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple ComponentPrices";

                //Create a componentPrice response list
                responses = [.. componentPrices.Select(componentPrice => new ComponentPriceResponseDto
                {
                    Id = componentPrice.Id,
                    SourceUrl = componentPrice.SourceUrl,
                    ComponentId = componentPrice.ComponentId,
                    VendorName = componentPrice.VendorName,
                    FetchedAt = componentPrice.FetchedAt,
                    Price = componentPrice.Price,
                    Currency = componentPrice.Currency,
                    DatabaseEntryAt = componentPrice.DatabaseEntryAt,
                    LastEditedAt = componentPrice.LastEditedAt,
                    Note = componentPrice.Note
                })];

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "ComponentPrice",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPrice.gotComponentPrices", new
            {
                componentPriceIds = componentPrices.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the componentPrices
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected ComponentPrice for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteComponentPrice(Guid id)
        {
            //Get componentPrice id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the componentPrice to delete
            var componentPrice = await _db.ComponentPrices.FirstOrDefaultAsync(u => u.Id == id);
            if (componentPrice == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "ComponentPrice",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such ComponentPrice"
                );

                //Return not found response
                return NotFound(new { componentPrice = "ComponentPrice not found!" });
            }

            //Delete the componentPrice
            _db.ComponentPrices.Remove(componentPrice);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "ComponentPrice",
                ip,
                componentPrice.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("componentPrice.deleted", new
            {
                componentPriceId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { componentPrice = "ComponentsPrice deleted successfully!" });
        }
    }
}
