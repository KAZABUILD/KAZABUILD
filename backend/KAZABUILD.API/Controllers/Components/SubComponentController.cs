using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.CoolerSocketSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.IntegratedGraphicsSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.M2SlotSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.OnboardEthernetSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.PCIeSlotSubComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.PortSubComponent;
using KAZABUILD.Application.Helpers;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Application.Security;
using KAZABUILD.Domain.Entities.Components.SubComponents;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;
using System.Security.Claims;
using Linq = System.Linq;

namespace KAZABUILD.API.Controllers.Components
{
    /// <summary>
    /// Controller for SubComponent related endpoints.
    /// Allows for polymorphic handling of the SubComponents class.
    /// The BaseSubComponent class and its dto's can be treated as all its derived classes.
    /// The classes are: Case, CaseFan, Cooler, CPU, GPU, Memory, Monitor, Motherboard, PowerSupply, Storage.
    /// </summary>
    /// <param name="db"></param>
    /// <param name="logger"></param>
    /// <param name="publisher"></param>
    [ApiController]
    [Route("[controller]")]
    public class SubComponentController(KAZABUILDDBContext db, ILoggerService logger, IRabbitMQPublisher publisher) : ControllerBase
    {
        //Services used in the controller
        private readonly KAZABUILDDBContext _db = db;
        private readonly ILoggerService _logger = logger;
        private readonly IRabbitMQPublisher _publisher = publisher;

        /// <summary>
        /// API Endpoint for creating a new SubComponent for administration.
        /// The class created is based on the provide type.
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPost("add")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> AddSubComponent([FromBody] CreateBaseSubComponentDto dto)
        {
            //Get user id from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Declare the SubComponent variable
            BaseSubComponent subComponent;

            //Return an invalid response if try/catch statement catches a type assignment error
            try
            {
                //Create a subComponent to add
                subComponent = dto switch
                {
                    CreateCoolerSocketSubComponentDto coolerSocketDto => new CoolerSocketSubComponent
                    {
                        Name = coolerSocketDto.Name,
                        Type = coolerSocketDto.Type,
                        SocketType = coolerSocketDto.SocketType,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateIntegratedGraphicsSubComponentDto integratedGraphicsDto => new IntegratedGraphicsSubComponent
                    {
                        Name = integratedGraphicsDto.Name,
                        Type = integratedGraphicsDto.Type,
                        Model = integratedGraphicsDto.Model,
                        BaseClockSpeed = integratedGraphicsDto.BaseClockSpeed,
                        BoostClockSpeed = integratedGraphicsDto.BoostClockSpeed,
                        CoreCount = integratedGraphicsDto.CoreCount,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateM2SlotSubComponentDto m2SlotSubComponentDto => new M2SlotSubComponent
                    {
                        Name = m2SlotSubComponentDto.Name,
                        Type = m2SlotSubComponentDto.Type,
                        Size = m2SlotSubComponentDto.Size,
                        KeyType = m2SlotSubComponentDto.KeyType,
                        Interface = m2SlotSubComponentDto.Interface,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreateOnboardEthernetSubComponentDto onBoardEthernetDto => new OnboardEthernetSubComponent
                    {
                        Name = onBoardEthernetDto.Name,
                        Type = onBoardEthernetDto.Type,
                        Speed = onBoardEthernetDto.Speed,
                        Controller = onBoardEthernetDto.Controller,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreatePCIeSlotSubComponentDto pcieSlotDto => new PCIeSlotSubComponent
                    {
                        Name = pcieSlotDto.Name,
                        Type = pcieSlotDto.Type,
                        Gen = pcieSlotDto.Gen,
                        Lanes = pcieSlotDto.Lanes,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    CreatePortSubComponentDto portDto => new PortSubComponent
                    {
                        Name = portDto.Name,
                        Type = portDto.Type,
                        PortType = portDto.PortType,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    _ => throw new NotImplementedException("Invalid SubComponent Type"),
                };
            }
            catch (Exception ex)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "SubComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    $"Operation Failed - {ex}"
                );

                //Return not found response
                return BadRequest(new { subComponent = "SubComponent not found!" });
            }

            //Add the subComponent to the database
            _db.SubComponents.Add(subComponent);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the creation
            await _logger.LogAsync(
                currentUserId,
                "POST",
                "SubComponent",
                ip,
                subComponent.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation - New SubComponent Created"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponent.created", new
            {
                subComponentId = subComponent.Id,
                createdBy = currentUserId
            });

            //Return success response
            return Ok(new { subComponent = "SubComponent sent successfully!", id = subComponent.Id });
        }

        /// <summary>
        /// API endpoint for updating the selected SubComponent.
        /// The updated subComponent has to receive the correct dto to undergo any changes.
        /// </summary>
        /// <param name="id"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        [HttpPut("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> UpdateSubComponent(Guid id, [FromBody] UpdateBaseSubComponentDto dto)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the subComponent to edit
            var subComponent = await _db.SubComponents.FirstOrDefaultAsync(u => u.Id == id);
            //Check if the subComponent exists
            if (subComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "SubComponent",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such SubComponent"
                );

                //Return not found response
                return NotFound(new { subComponent = "SubComponent not found!" });
            }

            //Track changes for logging
            var changedFields = new List<string>();

            //Update fields based on the SubComponent type
            switch(dto)
            {
                case UpdateCoolerSocketSubComponentDto coolerSocket:
                {
                    if (coolerSocket.SocketType != null)
                    {
                        changedFields.Add("SocketType: " + ((CoolerSocketSubComponent)subComponent).SocketType);

                        ((CoolerSocketSubComponent)subComponent).SocketType = coolerSocket.SocketType;
                    }
                    break;
                }
                case UpdateIntegratedGraphicsSubComponentDto integratedGraphicsDto:
                {
                    if (integratedGraphicsDto.Model != null)
                    {
                        changedFields.Add("Model: " + ((IntegratedGraphicsSubComponent)subComponent).Model);

                        if (string.IsNullOrWhiteSpace(integratedGraphicsDto.Model))
                            ((IntegratedGraphicsSubComponent)subComponent).Model = null;
                        else
                            ((IntegratedGraphicsSubComponent)subComponent).Model = integratedGraphicsDto.Model;
                    }
                    if (integratedGraphicsDto.BaseClockSpeed != null)
                    {
                        changedFields.Add("BaseClockSpeed: " + ((IntegratedGraphicsSubComponent)subComponent).BaseClockSpeed);

                        ((IntegratedGraphicsSubComponent)subComponent).BaseClockSpeed = (int)integratedGraphicsDto.BaseClockSpeed;
                    }
                    if (integratedGraphicsDto.BoostClockSpeed != null)
                    {
                        changedFields.Add("BoostClockSpeed: " + ((IntegratedGraphicsSubComponent)subComponent).BoostClockSpeed);

                        ((IntegratedGraphicsSubComponent)subComponent).BoostClockSpeed = (int)integratedGraphicsDto.BoostClockSpeed;
                    }
                    if (integratedGraphicsDto.CoreCount != null)
                    {
                        changedFields.Add("CoreCount: " + ((IntegratedGraphicsSubComponent)subComponent).CoreCount);

                        ((IntegratedGraphicsSubComponent)subComponent).CoreCount = (int)integratedGraphicsDto.CoreCount;
                    }
                    break;
                }
                case UpdateM2SlotSubComponentDto m2SlotDto:
                {
                    if (!string.IsNullOrWhiteSpace(m2SlotDto.Size))
                    {
                        changedFields.Add("Size: " + ((M2SlotSubComponent)subComponent).Size);

                        ((M2SlotSubComponent)subComponent).Size = m2SlotDto.Size;
                    }
                    if (!string.IsNullOrWhiteSpace(m2SlotDto.KeyType))
                    {
                        changedFields.Add("KeyType: " + ((M2SlotSubComponent)subComponent).KeyType);

                        ((M2SlotSubComponent)subComponent).KeyType = m2SlotDto.KeyType;
                    }
                    if (!string.IsNullOrWhiteSpace(m2SlotDto.Interface))
                    {
                        changedFields.Add("Interface: " + ((M2SlotSubComponent)subComponent).Interface);

                        ((M2SlotSubComponent)subComponent).Interface = m2SlotDto.Interface;
                    }
                    break;
                }
                case UpdateOnboardEthernetSubComponentDto onBoardEthernetDto:
                {
                    if (!string.IsNullOrWhiteSpace(onBoardEthernetDto.Speed))
                    {
                        changedFields.Add("Speed: " + ((OnboardEthernetSubComponent)subComponent).Speed);

                        ((OnboardEthernetSubComponent)subComponent).Speed = onBoardEthernetDto.Speed;
                    }
                    if (!string.IsNullOrWhiteSpace(onBoardEthernetDto.Controller))
                    {
                        changedFields.Add("Controller: " + ((OnboardEthernetSubComponent)subComponent).Controller);

                        ((OnboardEthernetSubComponent)subComponent).Controller = onBoardEthernetDto.Controller;
                    }
                    break;
                }
                case UpdatePCIeSlotSubComponentDto pcieSlotDto:
                {
                    if (!string.IsNullOrWhiteSpace(pcieSlotDto.Gen))
                    {
                        changedFields.Add("Gen: " + ((PCIeSlotSubComponent)subComponent).Gen);

                        ((PCIeSlotSubComponent)subComponent).Gen = pcieSlotDto.Gen;
                    }
                    if (!string.IsNullOrWhiteSpace(pcieSlotDto.Lanes))
                    {
                        changedFields.Add("Lanes: " + ((PCIeSlotSubComponent)subComponent).Lanes);

                        ((PCIeSlotSubComponent)subComponent).Lanes = pcieSlotDto.Lanes;
                    }
                    break;
                }
                case UpdatePortSubComponentDto portDto:
                {
                    if (portDto.PortType != null)
                    {
                        changedFields.Add("PortType: " + ((PortSubComponent)subComponent).PortType);

                        ((PortSubComponent)subComponent).PortType = (PortType)portDto.PortType;
                    }
                    break;
                }
            };

            //Update base subComponent fields
            if (!string.IsNullOrWhiteSpace(dto.Name))
            {
                changedFields.Add("Name: " + subComponent.Name);

                subComponent.Name = dto.Name;
            }
            if (dto.Note != null)
            {
                changedFields.Add("Note: " + subComponent.Note);

                if (string.IsNullOrWhiteSpace(dto.Note))
                    subComponent.Note = null;
                else
                    subComponent.Note = dto.Note;
            }

            //Update edit timestamp
            subComponent.LastEditedAt = DateTime.UtcNow;

            //Update the subComponent
            _db.SubComponents.Update(subComponent);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Logging description with all the changed fields
            var description = changedFields.Count > 0 ? $"Updated Fields: {string.Join(", ", changedFields)}" : "No Fields Changed";

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "PUT",
                "SubComponent",
                ip,
                subComponent.Id,
                PrivacyLevel.INFORMATION,
                $"Successful Operation - Type: {subComponent.Type}, {description}"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponent.updated", new
            {
                subComponentId = id,
                updatedBy = currentUserId
            });

            //Return success response
            return Ok(new { subComponent = "SubComponent updated successfully!" });
        }

        /// <summary>
        /// API endpoint for getting the SubComponent specified by id,
        /// different level of information returned based on privileges.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        /// <exception cref="NotImplementedException"></exception>
        [HttpGet("{id:Guid}")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<BaseSubComponentResponseDto>> GetSubComponent(Guid id)
        {
            //Get user id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the subComponent to return
            var subComponent = await _db.SubComponents.FirstOrDefaultAsync(u => u.Id == id);
            if (subComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "GET",
                    "SubComponent",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such SubComponent"
                );

                //Return not found response
                return NotFound(new { subComponent = "SubComponent not found!" });
            }

            //Declare the response variable
            BaseSubComponentResponseDto response;

            //Log Description string declaration
            string logDescription;

            //Return an invalid response if try/catch statement catches a type assignment error
            try
            {
                //Create a subComponent to add
                response = subComponent switch
                {
                    CoolerSocketSubComponent coolerSocketDto => new CoolerSocketSubComponentResponseDto
                    {
                        Name = coolerSocketDto.Name,
                        Type = coolerSocketDto.Type,
                        SocketType = coolerSocketDto.SocketType,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    IntegratedGraphicsSubComponent integratedGraphicsDto => new IntegratedGraphicsSubComponentResponseDto
                    {
                        Name = integratedGraphicsDto.Name,
                        Type = integratedGraphicsDto.Type,
                        Model = integratedGraphicsDto.Model,
                        BaseClockSpeed = integratedGraphicsDto.BaseClockSpeed,
                        BoostClockSpeed = integratedGraphicsDto.BoostClockSpeed,
                        CoreCount = integratedGraphicsDto.CoreCount,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    M2SlotSubComponent m2SlotSubComponentDto => new M2SlotSubComponentResponseDto
                    {
                        Name = m2SlotSubComponentDto.Name,
                        Type = m2SlotSubComponentDto.Type,
                        Size = m2SlotSubComponentDto.Size,
                        KeyType = m2SlotSubComponentDto.KeyType,
                        Interface = m2SlotSubComponentDto.Interface,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    OnboardEthernetSubComponent onBoardEthernetDto => new OnboardEthernetSubComponentResponseDto
                    {
                        Name = onBoardEthernetDto.Name,
                        Type = onBoardEthernetDto.Type,
                        Speed = onBoardEthernetDto.Speed,
                        Controller = onBoardEthernetDto.Controller,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    PCIeSlotSubComponent pcieSlotDto => new PCIeSlotSubComponentResponseDto
                    {
                        Name = pcieSlotDto.Name,
                        Type = pcieSlotDto.Type,
                        Gen = pcieSlotDto.Gen,
                        Lanes = pcieSlotDto.Lanes,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    PortSubComponent portDto => new PortSubComponentResponseDto
                    {
                        Name = portDto.Name,
                        Type = portDto.Type,
                        PortType = portDto.PortType,
                        DatabaseEntryAt = DateTime.UtcNow,
                        LastEditedAt = DateTime.UtcNow
                    },
                    _ => throw new NotImplementedException("Invalid SubComponent Type"),
                };
            }
            catch (Exception ex)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "PUT",
                    "SubComponent",
                    ip,
                    Guid.Empty,
                    PrivacyLevel.WARNING,
                    $"Operation Failed - {ex}"
                );

                //Return not found response
                return StatusCode(StatusCodes.Status500InternalServerError, new { message = "Invalid SubComponent Type!", detail = ex.Message });
            }

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Check if has admin privilege
            if (!isPrivileged)
            {
                //Change log description
                logDescription = "Successful Operation - User Access";
            }
            else
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access";

                //Add admin fields
                response.DatabaseEntryAt = subComponent.DatabaseEntryAt;
                response.LastEditedAt = subComponent.LastEditedAt;
                response.Note = subComponent.Note;
            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "SubComponent",
                ip,
                id,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponent.got", new
            {
                subComponentId = id,
                gotBy = currentUserId
            });

            //Return the subComponent
            return Ok(response);
        }

        /// <summary>
        /// API endpoint for getting SubComponents with pagination and search custom for each subclass,
        /// different level of information returned based on privileges
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        /// <exception cref="NotImplementedException"></exception>
        [HttpPost("get")]
        [Authorize(Policy = "AllUsers")]
        public async Task<ActionResult<IEnumerable<BaseSubComponentResponseDto>>> GetSubComponents([FromBody] GetBaseSubComponentDto dto)
        {
            //Get subComponent id and claims from the request
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Check if current user has admin permissions
            var isPrivileged = RoleGroups.Admins.Contains(currentUserRole.ToString());

            //Declare the query
            var query = _db.SubComponents.AsNoTracking();

            //Filter by Base SubComponent class variables
            if (dto.Name != null)
            {
                query = query.Where(s => dto.Name.Contains(s.Name));
            }
            if (dto.Type != null)
            {
                query = query.Where(s => dto.Type.Contains(s.Type));
            }

            //Filter by the specific subclass variables
            switch (dto)
            {
                case GetCoolerSocketSubComponentDto coolerSocketDto:
                {
                    //Create a subquery based on the CoolerSocket type
                    var coolerSocketQuery = query.OfType<CoolerSocketSubComponent>();

                    //Filter by Cooler Socket SubComponent class variables
                    coolerSocketQuery = coolerSocketQuery.Where(s =>
                        (coolerSocketDto.SocketType == null || coolerSocketDto.SocketType.Contains(s.SocketType))
                    );

                    //Apply search for the Cooler Socket SubComponent
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        coolerSocketQuery = coolerSocketQuery.Search(dto.Query, s => s.Name, s => s.Type, s => s.SocketType);
                    }

                    query = coolerSocketQuery;

                    break;
                }
                case GetIntegratedGraphicsSubComponentDto integratedGraphicsDto:
                {
                    //Create a subquery based on the IntegratedGraphics type
                    var integratedGraphicsQuery = query.OfType<IntegratedGraphicsSubComponent>();
                        
                    //Filter by Integrated Graphics SubComponent class variables
                    integratedGraphicsQuery = integratedGraphicsQuery.Where(s =>
                        (integratedGraphicsDto.Model == null || (s.Model != null && integratedGraphicsDto.Model.Contains(s.Model))) &&
                        (integratedGraphicsDto.BaseClockSpeedStart == null || integratedGraphicsDto.BaseClockSpeedStart <= s.BaseClockSpeed) &&
                        (integratedGraphicsDto.BaseClockSpeedEnd == null || integratedGraphicsDto.BaseClockSpeedEnd >= s.BaseClockSpeed) &&
                        (integratedGraphicsDto.BoostClockSpeedStart == null || integratedGraphicsDto.BoostClockSpeedStart <= s.BoostClockSpeed) &&
                        (integratedGraphicsDto.BoostClockSpeedEnd == null || integratedGraphicsDto.BoostClockSpeedEnd >= s.BoostClockSpeed) &&
                        (integratedGraphicsDto.CoreCountStart == null || integratedGraphicsDto.CoreCountStart <= s.CoreCount) &&
                        (integratedGraphicsDto.CoreCountEnd == null || integratedGraphicsDto.CoreCountEnd >= s.CoreCount)
                    );

                    //Apply search for the Integrated Graphics SubComponent
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        integratedGraphicsQuery = integratedGraphicsQuery.Search(dto.Query, s => s.Name, s => s.Type, s => s.Model!);
                    }

                    query = integratedGraphicsQuery;

                    break;
                }
                case GetM2SlotSubComponentDto m2SlotDto:
                {
                        //Create a subquery based on the M2Slot type
                        var m2SlotQuery = query.OfType<M2SlotSubComponent>();
                        
                    //Filter by M2Slot class variables
                    m2SlotQuery = m2SlotQuery.Where(s =>
                        (m2SlotDto.Size == null || m2SlotDto.Size.Contains(s.Size)) &&
                        (m2SlotDto.KeyType == null || m2SlotDto.KeyType.Contains(s.KeyType)) &&
                        (m2SlotDto.Interface == null || m2SlotDto.Interface.Contains(s.Interface))
                    );

                    //Apply search for the M2Slot Fan SubComponent
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        m2SlotQuery = m2SlotQuery.Search(dto.Query, s => s.Name, s => s.Type);
                    }

                    query = m2SlotQuery;

                    break;
                }
                case GetOnboardEthernetSubComponentDto onBoardEthernetDto:
                {
                    //Create a subquery based on the OnboardEthernet type
                    var onBoardEthernetQuery = query.OfType<OnboardEthernetSubComponent>();
                        
                    //Filter by OnboardEthernet class variables
                    onBoardEthernetQuery = onBoardEthernetQuery.Where(s =>
                        (onBoardEthernetDto.Speed == null || onBoardEthernetDto.Speed.Contains(s.Speed)) &&
                        (onBoardEthernetDto.Controller == null || onBoardEthernetDto.Controller.Contains(s.Controller))
                    );

                    //Apply search for the Onboard Ethernet SubComponent
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        onBoardEthernetQuery = onBoardEthernetQuery.Search(dto.Query, s => s.Name, s => s.Type, s => s.Speed, s => s.Controller);
                    }

                    query = onBoardEthernetQuery;

                    break;
                }
                case GetPCIeSlotSubComponentDto pcieSlotDto:
                {
                    //Create a subquery based on the PCIeSlot type
                    var pcieSlotQuery = query.OfType<PCIeSlotSubComponent>();
                        
                    //Filter by PCIeSlot SubComponent class variables
                    pcieSlotQuery = pcieSlotQuery.Where(s =>
                        (pcieSlotDto.Gen == null || pcieSlotDto.Gen.Contains(s.Gen)) &&
                        (pcieSlotDto.Lanes == null || pcieSlotDto.Lanes.Contains(s.Lanes))
                    );

                    //Apply search for the Case Fan SubComponent
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        pcieSlotQuery = pcieSlotQuery.Search(dto.Query, s => s.Name, s => s.Type, s => s.Gen, s => s.Lanes);
                    }

                    query = pcieSlotQuery;

                    break;
                }
                case GetPortSubComponentDto portDto:
                {
                    //Create a subquery based on the Port type
                    var portQuery = query.OfType<PortSubComponent>();
                        
                    //Filter by Port SubComponent class variables
                    portQuery = portQuery.Where(s =>
                        (portDto.PortType == null || portDto.PortType.Contains(s.PortType))
                    );

                    //Apply search for the Case Fan SubComponent
                    if (!string.IsNullOrWhiteSpace(dto.Query))
                    {
                        portQuery = portQuery.Search(dto.Query, s => s.Name, s => s.Type, s => s.PortType);
                    }

                    query = portQuery;

                    break;
                }
            };

            //Order by specified field if provided
            if (!string.IsNullOrWhiteSpace(dto.OrderBy))
            {
                query = query.OrderBy($"{dto.OrderBy} {dto.SortDirection}");
            }

            //Get subComponents with paging
            if (dto.Paging && dto.Page != null && dto.PageLength != null)
            {
                query = query
                    .Skip(((int)dto.Page - 1) * (int)dto.PageLength)
                    .Take((int)dto.PageLength);
            }

            //Log Description string declaration
            string logDescription;

            List<BaseSubComponent> subComponents = await query.ToListAsync();

            //Declare response variable
            List<BaseSubComponentResponseDto> responses;

            //Check what permissions user has and return respective information
            if (!isPrivileged) //Return user knowledge if no privileges
            {
                //Change log description
                logDescription = "Successful Operation - User Access, Multiple SubComponents";

                //Return an invalid response if try/catch statement catches a type assignment error
                try
                {
                    //Create a subComponent response list
                    responses = [.. Enumerable.Select<BaseSubComponent, BaseSubComponentResponseDto>(subComponents, subComponent =>
                    {
                        return subComponent switch
                        {
                            CoolerSocketSubComponent coolerSocketDto => new CoolerSocketSubComponentResponseDto
                            {
                                Name = coolerSocketDto.Name,
                                Type = coolerSocketDto.Type,
                                SocketType = coolerSocketDto.SocketType
                            },
                            IntegratedGraphicsSubComponent integratedGraphicsDto => new IntegratedGraphicsSubComponentResponseDto
                            {
                                Name = integratedGraphicsDto.Name,
                                Type = integratedGraphicsDto.Type,
                                Model = integratedGraphicsDto.Model,
                                BaseClockSpeed = integratedGraphicsDto.BaseClockSpeed,
                                BoostClockSpeed = integratedGraphicsDto.BoostClockSpeed,
                                CoreCount = integratedGraphicsDto.CoreCount
                            },
                            M2SlotSubComponent m2SlotSubComponentDto => new M2SlotSubComponentResponseDto
                            {
                                Name = m2SlotSubComponentDto.Name,
                                Type = m2SlotSubComponentDto.Type,
                                Size = m2SlotSubComponentDto.Size,
                                KeyType = m2SlotSubComponentDto.KeyType,
                                Interface = m2SlotSubComponentDto.Interface
                            },
                            OnboardEthernetSubComponent onBoardEthernetDto => new OnboardEthernetSubComponentResponseDto
                            {
                                Name = onBoardEthernetDto.Name,
                                Type = onBoardEthernetDto.Type,
                                Speed = onBoardEthernetDto.Speed,
                                Controller = onBoardEthernetDto.Controller
                            },
                            PCIeSlotSubComponent pcieSlotDto => new PCIeSlotSubComponentResponseDto
                            {
                                Name = pcieSlotDto.Name,
                                Type = pcieSlotDto.Type,
                                Gen = pcieSlotDto.Gen,
                                Lanes = pcieSlotDto.Lanes
                            },
                            PortSubComponent portDto => new PortSubComponentResponseDto
                            {
                                Name = portDto.Name,
                                Type = portDto.Type,
                                PortType = portDto.PortType
                            },
                            _ => throw new NotImplementedException("Invalid SubComponent Type"),
                        };
                    })];
                }
                catch (Exception ex)
                {
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "PUT",
                        "SubComponent",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        $"Operation Failed - {ex}"
                    );

                    //Return not found response
                    return StatusCode(StatusCodes.Status500InternalServerError, new { message = "Invalid SubComponent Type!", detail = ex.Message });
                }
            }
            else //Return admin knowledge if has privileges
            {
                //Change log description
                logDescription = "Successful Operation - Admin Access, Multiple SubComponents";

                //Return an invalid response if try/catch statement catches a type assignment error
                try
                {
                    //Create a subComponent response list
                    responses = [.. Linq.Enumerable.Select<BaseSubComponent, BaseSubComponentResponseDto>(subComponents, subComponent =>
                    {
                        return subComponent switch
                        {
                            CoolerSocketSubComponent coolerSocketDto => new CoolerSocketSubComponentResponseDto
                            {
                                Name = coolerSocketDto.Name,
                                Type = coolerSocketDto.Type,
                                SocketType = coolerSocketDto.SocketType,
                                DatabaseEntryAt = DateTime.UtcNow,
                                LastEditedAt = DateTime.UtcNow,
                                Note = coolerSocketDto.Note
                            },
                            IntegratedGraphicsSubComponent integratedGraphicsDto => new IntegratedGraphicsSubComponentResponseDto
                            {
                                Name = integratedGraphicsDto.Name,
                                Type = integratedGraphicsDto.Type,
                                Model = integratedGraphicsDto.Model,
                                BaseClockSpeed = integratedGraphicsDto.BaseClockSpeed,
                                BoostClockSpeed = integratedGraphicsDto.BoostClockSpeed,
                                CoreCount = integratedGraphicsDto.CoreCount,
                                DatabaseEntryAt = DateTime.UtcNow,
                                LastEditedAt = DateTime.UtcNow,
                                Note = integratedGraphicsDto.Note
                            },
                            M2SlotSubComponent m2SlotSubComponentDto => new M2SlotSubComponentResponseDto
                            {
                                Name = m2SlotSubComponentDto.Name,
                                Type = m2SlotSubComponentDto.Type,
                                Size = m2SlotSubComponentDto.Size,
                                KeyType = m2SlotSubComponentDto.KeyType,
                                Interface = m2SlotSubComponentDto.Interface,
                                DatabaseEntryAt = DateTime.UtcNow,
                                LastEditedAt = DateTime.UtcNow,
                                Note = m2SlotSubComponentDto.Note
                            },
                            OnboardEthernetSubComponent onBoardEthernetDto => new OnboardEthernetSubComponentResponseDto
                            {
                                Name = onBoardEthernetDto.Name,
                                Type = onBoardEthernetDto.Type,
                                Speed = onBoardEthernetDto.Speed,
                                Controller = onBoardEthernetDto.Controller,
                                DatabaseEntryAt = DateTime.UtcNow,
                                LastEditedAt = DateTime.UtcNow,
                                Note = onBoardEthernetDto.Note
                            },
                            PCIeSlotSubComponent pcieSlotDto => new PCIeSlotSubComponentResponseDto
                            {
                                Name = pcieSlotDto.Name,
                                Type = pcieSlotDto.Type,
                                Gen = pcieSlotDto.Gen,
                                Lanes = pcieSlotDto.Lanes,
                                DatabaseEntryAt = DateTime.UtcNow,
                                LastEditedAt = DateTime.UtcNow,
                                Note = pcieSlotDto.Note
                            },
                            PortSubComponent portDto => new PortSubComponentResponseDto
                            {
                                Name = portDto.Name,
                                Type = portDto.Type,
                                PortType = portDto.PortType,
                                DatabaseEntryAt = DateTime.UtcNow,
                                LastEditedAt = DateTime.UtcNow,
                                Note = portDto.Note
                            },
                            _ => throw new NotImplementedException("Invalid SubComponent Type"),
                        };
                    })];
                }
                catch (Exception ex)
                {
                    //Log failure
                    await _logger.LogAsync(
                        currentUserId,
                        "PUT",
                        "SubComponent",
                        ip,
                        Guid.Empty,
                        PrivacyLevel.WARNING,
                        $"Operation Failed - {ex}"
                    );

                    //Return not found response
                    return StatusCode(StatusCodes.Status500InternalServerError, new { message = "Invalid SubComponent Type!", detail = ex.Message });
                }

            }

            //Log success
            await _logger.LogAsync(
                currentUserId,
                "GET",
                "SubComponent",
                ip,
                Guid.Empty,
                PrivacyLevel.INFORMATION,
                logDescription
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponent.gotSubComponents", new
            {
                subComponentIds = subComponents.Select(u => u.Id),
                gotBy = currentUserId
            });

            //Return the subComponents
            return Ok(responses);
        }

        /// <summary>
        /// API endpoint for deleting the selected SubComponent for administration.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpDelete("{id:Guid}")]
        [Authorize(Policy = "Admins")]
        public async Task<IActionResult> DeleteSubComponent(Guid id)
        {
            //Get subComponent id and role from the request claims
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var currentUserRole = Enum.Parse<UserRole>(User.FindFirstValue(ClaimTypes.Role)!);

            //Get the IP from request
            var ip = HttpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()
                ?? HttpContext.Connection.RemoteIpAddress?.ToString();

            //Get the subComponent to delete
            var subComponent = await _db.SubComponents.FirstOrDefaultAsync(u => u.Id == id);
            if (subComponent == null)
            {
                //Log failure
                await _logger.LogAsync(
                    currentUserId,
                    "DELETE",
                    "SubComponent",
                    ip,
                    id,
                    PrivacyLevel.WARNING,
                    "Operation Failed - No Such SubComponent"
                );

                //Return not found response
                return NotFound(new { subComponent = "SubComponent not found!" });
            }

            //Delete the subComponent
            _db.SubComponents.Remove(subComponent);

            //Save changes to the database
            await _db.SaveChangesAsync();

            //Log the update
            await _logger.LogAsync(
                currentUserId,
                "DELETE",
                "SubComponent",
                ip,
                subComponent.Id,
                PrivacyLevel.INFORMATION,
                "Successful Operation"
            );

            //Publish RabbitMQ event
            await _publisher.PublishAsync("subComponent.deleted", new
            {
                subComponentId = id,
                deletedBy = currentUserId
            });

            //Return success response
            return Ok(new { subComponent = "SubComponent deleted successfully!" });
        }
    }
}
