# KAZA BUILD - BACKEND

## How to run
 - `cd backend/KAZABUILD.API` to get into the backend application folder in terminal.
 - `dotnet restore` to get the required packages.
 - Create and fill in the `launchSettings.json` file with correct information based on the example file.
 - Use visual studio to run or use `dotnet watch run` in the command line.
 - Access automatic swagger documentation using `<ip_address>/swagger`.

## Migrations
 - `cd backend` to get into the main backend folder in terminal.
 - `dotnet ef migrations add InitialCreate --project KAZABUILD.Infrastructure --startup-project KAZABUILD.API` to create the initial database migration. If there is one already create a different one or just apply it.
 - `dotnet ef database update` to apply all migrations.
 - The app will automatically apply migrations when run.
 - Migrations can be reviewed in `backend/KAZABUILD.Infrastructure/Migrations`.

## Search function
 - Whenever a new model is added to the database the user has to manually add the search index for it as well:
   - Create a new migration.
   - Add this to the up function:
     - `migrationBuilder.Sql(@"
            IF NOT EXISTS
            (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.[table_name]'))
                CREATE FULLTEXT INDEX ON [table_name]([field_name1] LANGUAGE 0, [field_name2] LANGUAGE 0, ...)
                KEY INDEX PK_[table_name];
        ", suppressTransaction: true);`
   - Add this to the down function:
     - `migrationBuilder.Sql("DROP FULLTEXT INDEX ON [table_name];", suppressTransaction: true);`
   - Replace the table_name and field name with proper database context table name and fields used in search in the controller
    

## NuGet Packages:
- `MediatR`
- `FluentValidation.DependencyInjectionExtensions`
- `Microsoft.AspNetCore.OpenApi`
- `Microsoft.EntityFrameworkCore`
- `Microsoft.EntityFrameworkCore.SqlServer`
- `Microsoft.EntityFrameworkCore.Tools`
- `Swashbuckle.AspNetCore`
- `RabbitMQ.Client`
- `Microsoft.AspNetCore.Authentication.JwtBearer`
- `Microsoft.Extensions.Options.ConfigurationExtensions`
- `BCrypt.Net-Next`
- `Serilog.AspNetCore`
- `FluentAssertions`
- `Microsoft.AspNetCore.Mvc.Testing`
- `Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore`
- `AspNetCoreRateLimit`
- `System.Linq.Dynamic.Core`
- `Microsoft.AspNetCore.Authentication.Google`
- `Google.Apis.Auth`

## Features
- Swagger Documentation
- Authentication Middleware
- Authorization Middleware
- Automatic Validation
- Rate Limiting
- CORS Middleware
- RabbitMQ Queues
- Health Checks Endpoints
- SMTP Email Service
- Hashing Service
- Guest User Handling Middleware

## Models
All models have protections against adding invalid values but any call made should be double checked anyway

- Log (event happening in the application, like an API call, error, database connection info)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the id of the user that called the logged activity
  - `Timestamp` -> date object storing when the activity happened
  - `SeverityLevel` -> Enum storing how critical the information in the log is
  - `ActivityType` -> string storing what is being logged
  - `TargetType` -> string storing where the activity happened
  - `TargetId` -> nullable string storing which object in the database was affected
  - `Description` -> nullable string storing additional information about the activity and error if one occurred
  - `IpAddress` -> the IP address of the user that called the logged activity

### User Domain
- User (individual user account, profile and settings):
  - `Id` -> automatically assigned GUID
  - `Login` -> string storing user's username
  - `Email` -> string storing a unique email
  - `PasswordHash` -> string storing securely stored password
  - `DisplayName` -> string storing the name displayed on user's profile
  - `PhoneNumber` -> nullable string storing phone number
  - `Description` -> string storing user's profile description
  - `Gender` -> string storing user's gender (Write full names like "Male")
  - `UserRole` -> Enum storing the assigned user role, can be used with a number or the full role string
  - `ImageURL` -> string storing user's saved profile picture's URL in the backend
  - `Birth` -> date object storing user's birth date
  - `RegisteredAt` -> date object storing the date the user registered their account
  - `Address` -> an object storing user's address with 7 strings:
    - `Country`
    - nullable `Province`
    - `City`
    - `Street`
    - `StreetNumber`
    - `PostalCode`
    - nullable `apartmentNumber`
  - `ProfileAccessibility` -> Enum storing who can see user's profile
  - `Theme` -> Enum storing which theme the user uses globally
  - `Language` -> Enum storing which language the user uses globally 
  - `Location` -> nullable string storing user's noted location
  - `ReceiveEmailNotifications` -> boolean storing whether the user wants to receive email notifications
  - `EnableDoubleFactorAuthentication` -> boolean storing whether the user has double factor authentication enabled
  - `GoogleId` -> nullable string storing Google id for user's who used Google OAuth to register
  - `GoogleProfilePicture` -> nullable string storing Google accounts profile picture for user's who used Google OAuth to register
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- UserToken (temporary token for authorization)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id the token is for
  - `Token` -> string storing the actual token 
  - `TokenType` -> string storing the type of the token
  - `CreatedAt` -> date object storing the date the token was created
  - `ExpiresAt` -> date object storing the date the token expires
  - `UsedAt` -> date object storing the date the token was used
  - `IpAddress` -> string storing the IP address of the person calling the endpoint that created the token
  - `RedirectUrl` -> string that stores the URL to which the user should be redirected after clicking a link with the token 
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- UserPreference (data from polls and quizzes)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id the preference is for
  - `DatabaseEntryAt` -> date object storing when the user was created in the database
  - `LastEditedAt` -> date object storing when the user was last edited
  - `Note` -> nullable string storing any staff-only information

- UserFollow (defines which user follows which user)
  - `Id` -> automatically assigned GUID
  - `FollowerId` -> GUID storing the user's id for the user that is following
  - `FollowedId` -> GUID storing the user's id for the user that is being followed
  - `FollowedAt` -> date object storing when the user was followed
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- UserComment (reply to different types of objects)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id that wrote the comment
  - `Content` -> string storing the html text in the comment
  - `ParentCommentId` -> nullable GUID storing which comment is being replied to
  - `CommentTargetType` -> Enum storing what type of entity is this commented under
  - `ForumPostId` -> nullable GUID storing which forum post is being replied to
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- Notification (notification about events, promo, or important notices)
  - `Id` -> automatically assigned GUID
  - `UserId` -> GUID storing the user's id that received the notification
  - `NotificationType` -> Enum storing the type of notification
  - `Body` -> string storing the html text in the notification
  - `Title` -> string storing the title of the notification
  - `LinkUrl` -> string storing the link to any related page
  - `SentAt` -> date object storing when the notification has been or will be received
  - `IsRead` -> boolean storing whether the notification was read by the user
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- Message (private message sent or received by the user)
  - `Id` -> automatically assigned GUID
  - `SenderId` -> GUID storing the user's id that sent the message
  - `ReceiverId` -> GUID storing the user's id that received the message
  - `Content` -> string storing the html text in the message
  - `Title` -> string storing the title of the message
  - `SentAt` -> date object storing when the message has been sent
  - `IsRead` -> boolean storing whether the message was read by the user
  - `ParentMessageId` -> nullable GUID storing which message is being replied to
  - `MessageType` -> Enum storing type of the message
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- ForumPost (forum post created by the user)
  - `Id` -> automatically assigned GUID
  - `CreatorId` -> GUID storing the user's id that posted the ForumPost
  - `Content` -> string storing the html text in the ForumPost
  - `Title` -> string storing the title of the ForumPost
  - `Topic` -> string storing the topic in which the ForumPost has been posted in
  - `PostedAt` -> date object storing when the ForumPost has been posted
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

### Component Domain

- Color (colors that different components can have)
  - `ColorCode` -> string storing color code (e.g. '#FFFFFF') acting as a unique key
  - `ColorName` -> string storing the name of the color
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information
  
- ComponentVariant (defines what color variants a component has)
  - `Id` -> automatically assigned GUID
  - `ColorCode` -> string storing the color's id that the component has a variant in
  - `IsAvailable` -> nullable string storing whether the color variant is available in online shops
  - `AdditionalPrice` -> nullable string storing price changes for the color variant
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- ComponentCompatibility (defines which components are compatible to each other)
  - `Id` -> automatically assigned GUID
  - `ComponentId` -> GUID storing the components's id that is compatible
  - `CompatibleComponentId` -> GUID storing the components's id that is compatible to the other component
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- ComponentPrice (external pricing for a component)
  - `Id` -> automatically assigned GUID
  - `SourceUrl` -> string storing the URL of the website the price is from
  - `ComponentId` -> GUID storing the components's id that the price is for
  - `VendorName` -> string storing the name of the vendor that selling the component
  - `FetchedAt` -> date object storing the when the price was fetched from the website
  - `Price` -> decimal storing the price of the component
  - `Currency` -> string storing the currency the component is being sold in
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information
  
- ComponentReview (external review for a component)
  - `Id` -> automatically assigned GUID
  - `SourceUrl` -> string storing the URL of the website the review is from
  - `ComponentId` -> GUID storing the components's id that the review is for
  - `ReviewerName` -> string storing the name of the reviewer that wrote the review
  - `FetchedAt` -> date object storing when the review was fetched from the website
  - `CreatedAt` -> date object storing when the review was created.
  - `Rating` -> decimal storing the rating given in the review on a scale 0-100
  - `ReviewText` -> string storing the text content of the review
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- ComponentPart (defines which sub-components are a part of component)
  - `Id` -> automatically assigned GUID
  - `ComponentId` -> GUID storing the components's id
  - `SubComponentId` ->  GUID storing the sub-components's id which is a part of the component
  - `Amount` -> integer storing how many of the sub-component is a part of the component
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- SubComponentPart (defines which sub-components are a part of another sub-component)
  - `Id` -> automatically assigned GUID
  - `MainSubComponentId` -> GUID storing the main sub-components's id
  - `SubComponentId` ->  GUID storing the sub-components's id which is a part of the main sub-component
  - `Amount` -> integer storing how many of the sub-component is a part of the main sub-component
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- BaseComponent (base class with common fields for all components)
  - `Id` -> automatically assigned GUID
  - `Name` -> string storing the component's name
  - `Manufacturer` -> string storing who created the component
  - `Release` -> nullable date object storing when the component was released
  - `Type` -> Enum storing the type of the component; used to distinguish between inherited classes in the database
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- CaseComponent (stores other components inside of it)
  - `FormFactor` -> string storing the physical specification of the case
  - `PowerSupplyShrouded` -> boolean storing whether the power supply is covered
  - `PowerSupplyAmount` -> nullable decimal storing the amount of power in the built-in power supply in Watts
  - `HasTransparentSidePanel` -> boolean storing whether the case includes a transparent side panel
  - `SidePanelType` -> nullable string storing what type of side panel is in the case
  - `MaxVideoCardLength` -> decimal storing the maximum length of a video card that can fit in inside the case in mm
  - `MaxCPUCoolerHeight` -> integer storing the maximum height of a CPU Cooler that can fit in inside the case in mm
  - `Internal35BayAmount` -> integer storing the number of internal spaces for holding Seta or HDD Drives, 3.5 - 101.6 mm width
  - `Internal25BayAmount` -> integer storing the number of internal spaces for holding HDD or SDD Drives, 2.5 - 69.85 mm width
  - `External35BayAmount` -> integer storing the number of external spaces for holding Seta or HDD Drives, 3.5 - 101.6 mm width
  - `External525BayAmount` -> integer storing the number of external spaces for holding Seta or HDD Drives, 5.25 - 133.35 mm width
  - `ExpansionSlotAmount` -> integer storing the number of slots where expansion cards can be inserted
  - `Dimensions` -> an object storing the size of the case in mm:
    - `Width`
    - `Height`
    - `Depth`
  - `Volume` -> calculated decimal storing the volume of the case in liters
  - `Weight` -> decimal storing the weight of the case in kg
  - `SupportsRearConnectingMotherboard` -> boolean storing whether the case supports connecting the motherboard in an alternative position

- CaseFanComponent (fan attached to the case for cooling)
  - `Size` -> decimal storing the size of the fan in mm
  - `Quantity` -> integer storing the number of fans included
  - `MinAirflow` -> decimal storing the minimum airflow in CMM
  - `MaxAirflow` -> nullable decimal storing the maximum airflow in CMM
  - `MinNoiseLevel` -> decimal storing the minimum noise level in dBAsize of the fan in mm
  - `MaxNoiseLevel` -> nullable decimal storing the maximum noise level in dBA
  - `PulseWidthModulation` -> boolean storing whether the fan supports Pulse Width Modulation for speed control
  - `LEDType` -> nullable string storing what type of LED type is in the fan
  - `ConnectorType` -> nullable string storing what connector type the fan uses
  - `ControllerType` -> string storing the what type of controller does the fan include
  - `StaticPressureAmount` -> decimal storing the Static pressure in mmH2O in the fan
  - `FlowDirection` -> string storing the direction of the airflow

- CoolerComponent (device used for cooling)
  - `MinFanRotationSpeed` -> nullable decimal storing the minimum fan rotation speed in RPM
  - `MaxFanRotationSpeed` -> nullable decimal storing the maximum fan rotation speed in RPM
  - `MinNoiseLevel` -> nullable decimal storing the minimum noise level in dBA
  - `MaxNoiseLevel` -> nullable decimal storing the maximum noise level in dBA
  - `Height` -> decimal storing the height of the cooler in mm
  - `IsWaterCooled` -> boolean storing whether the cooler uses water-cooling
  - `RadiatorSize` -> nullable decimal storing the radiator size in mm
  - `CanOperateFanless` -> boolean storing whether the cooler can operate fanless
  - `FanSize` -> nullable decimal storing the size of the fan(s) included with the cooler in mm
  - `FanQuantity` -> integer storing the quantity of fans included with the cooler

- CPUComponent (processes a wide variety of tasks on the computer)
  - `Series` -> string storing the CPU series
  - `Microarchitecture` -> string storing the CPU processor's design architecture 
  - `CoreFamily` -> string storing the core family of the CPU architecture
  - `SocketType` -> string storing the type of socket the CPU uses to connect to the motherboard
  - `CoreTotal` -> integer storing the total number of physical cores in the CPU
  - `PerformanceAmount` -> nullable integer storing the total number of Performance cores (hybrid CPUs only) in the CPU
  - `EfficiencyAmount` -> nullable integer storing the total number of Efficiency cores (hybrid CPUs only) in the CPU
  - `ThreadsAmount` -> integer storing the number of logical threads the CPU can handle
  - `BasePerformanceSpeed` -> nullable decimal storing the base clock Speed for a Performance core in MHz
  - `BoostPerformanceSpeed` -> nullable decimal storing the max boosted clock Speed for a Performance core in MHz
  - `BaseEfficiencySpeed` -> nullable decimal storing the base clock Speed for an Efficiency core in MHz
  - `BoostEfficiencySpeed` -> nullable decimal storing the max boosted clock Speed for an Efficiency core in MHz
  - `L1` -> nullable decimal storing the size of the Level 1 cache in KB
  - `L2` -> nullable decimal storing the size of the Level 2 cache in KB
  - `L3` -> nullable decimal storing the size of the Level 3 cache in MB
  - `L4` -> nullable decimal storing the size of the Level 4 cache in MB
  - `IncludesCooler` -> boolean storing whether the CPU includes a stock cooler
  - `Lithography` -> string storing the manufacturing process technology used in the CPU
  - `SupportsSimultaneousMultithreading` -> boolean storing whether the CPU supports simultaneous multithreading
  - `MemoryType` -> string storing the supported memory type
  - `PackagingType` -> string storing the type of packaging the CPU comes in
  - `SupportsECC` -> boolean storing whether the CPU supports detecting and correcting errors in data transmission or storage via ECC
  - `ThermalDesignPower` -> decimal storing the maximum heat the CPU can generate in Watts

- GPUComponent (processes tasks requiring heavy operations such as graphics)
  - `Chipset` -> string storing the GPU chipset name
  - `VideoMemoryAmount` ->  decimal storing the amount of dedicated VRAM in MB
  - `VideoMemoryType` -> string storing what type of video memory the GPU uses 
  - `CoreBaseClockSpeed` ->  decimal storing the GPU base core clock speed in MHz
  - `CoreBoostClockSpeed` ->  decimal storing the GPU boost core clock speed in MHz
  - `CoreCount` -> integer storing the number of specialized GPU cores/shaders for task division
  - `EffectiveMemoryClockSpeed` ->  decimal storing the effective memory clock speed in MHz
  - `MemoryBusWidth` -> integer storing how much data can be transferred on a bus in bits per second
  - `FrameSync` -> string storing the frame synchronization technology supported by the GPU
  - `Length` ->  decimal storing the length of the GPU in mm
  - `ThermalDesignPower` ->  decimal storing the maximum heat the CPU can generate in Watts
  - `CaseExpansionSlotWidth` -> integer storing the number of case expansion slots the GPU occupies
  - `TotalSlotAmount` -> integer storing the total number of expansion slots the GPU occupies, accounting for the cooler size
  - `CoolingType` -> string storing the type of cooling solution

- MemoryComponent (stores data used by application currently running on the computer)
  - `Speed` -> decimal storing the memory speed in MHz
  - `RAMType` -> string storing which generation of the DDR the memory belongs to 
  - `FormFactor` -> string storing the design aspect that defines the size, shape, and other physical specifications of the RAM module
  - `Capacity` -> decimal storing the total capacity of the RAM kit in MB
  - `CASLatency` -> decimal storing the delay in clock cycles between the READ command and the moment data is available
  - `Timings` -> nullable string storing the specification of the clock latency of certain specific commands issued to RAM
  - `ModuleQuantity` -> integer storing the number of memory modules installed in the RAM
  - `ModuleCapacity` -> decimal storing the capacity per module in MB
  - `ECC` -> string storing the type of Error-Correcting Code used by the RAM
  - `RegisteredType` -> string storing the whether the RAM is registered or unbuffered 
  - `HaveHeatSpreader` -> boolean storing whether the RAM modules have a heat spreader used to dissipate excess heat
  - `HaveRGB` -> boolean storing whether the RAM modules have RGB lighting
  - `Height` -> decimal storing the height of the RAM module in mm
  - `Voltage` -> decimal storing the operating voltage of the RAM

- MonitorComponent (displays information from the computer to the user)
  - `ScreenSize` -> decimal storing the screen size in inches
  - `HorizontalResolution` -> integer storing screen's horizontal resolution in pixels
  - `VerticalResolution` -> integer storing screen's vertical resolution in pixels
  - `MaxRefreshRate` -> decimal storing the maximum monitor refresh rate in Hz
  - `PanelType` -> string storing the type of technology used to generate images on the monitor
  - `ResponseTime` -> decimal storing how much times it takes for the monitor to shift from one color to another in ms 
  - `ViewingAngle` -> string storing the maximum viewing angle where the screen is still visible to a human
  - `AspectRatio` -> string storing the aspect ratio of the monitor
  - `MaxBrightness` -> nullable decimal storing the maximum brightness of the monitor in nits
  - `HighDynamicRangeType` -> nullable string storing what type of HDR does the Monitor supports 
  - `AdaptiveSyncType` -> string storing the type of AdaptiveSync the monitor uses

- MotherboardComponent (connects all the other components together)
  - `SocketType` -> string storing the CPU socket type supported by the motherboard
  - `FormFactor` -> string storing the design aspect that defines the size, shape, and other physical specifications of the motherboard
  - `ChipsetType` -> string storing the chipset type used by the motherboard
  - `RAMType` -> string storing which generation of the DDR the motherboard supports 
  - `RAMSlotsAmount` -> integer storing the amount of expansion slots available for RAM
  - `MaxRAMAmount` -> integer storing the maximum amount of RAM the motherboard can support in GB
  - `SATA6GBsAmount` -> integer storing the amount of SATA with 6 GBs speed available in the motherboard
  - `SATA3GBsAmount` -> integer storing the amount of SATA with 3 GBs speed available in the motherboard
  - `U2PortAmount` -> integer storing the amount of U2 Ports used to connect SSD's available in the motherboard
  - `WirelessNetworkingStandard` -> string storing the supported WiFi standard
  - `CPUFanHeaderAmount` -> nullable integer storing the number of CPU fan headers
  - `CaseFanHeaderAmount` -> nullable integer storing the number of case fan headers
  - `PumpHeaderAmount` -> nullable integer storing the number of dedicated pump headers for liquid coolers in the motherboard
  - `CPUOptionalFanHeaderAmount` -> nullable integer storing the number of optional CPU fan headers in the motherboard
  - `ARGB5vHeaderAmount` -> nullable integer storing the number of ARGB headers in the motherboard
  - `RGB12vHeaderAmount` -> nullable integer storing the number of RGB headers in the motherboard
  - `HasPowerButtonHeader` -> boolean storing whether the motherboard has a power button header
  - `HasResetButtonHeader` -> boolean storing whether the motherboard has a reset button header
  - `HasPowerLEDHeader` -> boolean storing whether the motherboard has a power LED header
  - `HasHDDLEDHeader` -> boolean storing whether the motherboard has a HDDLED Header
  - `TemperatureSensorHeaderAmount` -> nullable integer storing the number of temperature sensor headers in the motherboard
  - `ThunderboltHeaderAmount` -> nullable integer storing the number of thunderbolt headers in the motherboard
  - `COMPortHeaderAmount` -> nullable integer storing the number of COM port headers in the motherboard
  - `MainPowerType` -> nullable string storing the main power connector specification
  - `HasECCSupport` -> boolean storing whether the motherboard supports ECC memory
  - `HasRAIDSupport` -> boolean storing whether the motherboard supports RAID configurations
  - `HasFlashback` -> boolean storing whether the board has BIOS backup capability in flashback
  - `HasCMOS` -> boolean storing whether the motherboard has a CMOS button
  - `AudioChipset` -> string storing the details of the audio chipset used in the motherboard
  - `MaxAudioChannels` -> decimal storing the maximum number of audio channels in the motherboard

- PowerSupplyComponent (delivers power necessary for the computer to function)
  - `PowerOutput` -> decimal storing the maximum power output in Watts
  - `FormFactor` -> string storing the design aspect that defines the size, shape, and other physical specifications of the power supply
  - `EfficiencyRating` -> nullable string storing the 80 PLUS efficiency certification level
  - `ModularityType` -> string storing the modularity type of the power supply cables
  - `Length` -> decimal storing the physical length of the power supply in mm
  - `IsFanless` -> boolean storing whether the power supply operates without a fan

- StorageComponent (virtual storage inside a computer)
  - `Series` -> string storing the storage series or model name
  - `Capacity` -> decimal storing the capacity of the storage device in GB
  - `DriveType` -> string storing the type of storage drive
  - `FormFactor` -> string storing the design aspect that defines the size, shape, and other physical specifications of the storage device
  - `Interface` -> string storing the interface used by the storage drive
  - `HasNVMe` -> boolean storing whether the storage drive supports the NVMe protocol

- BaseSubComponent (base class with common fields for all sub-components)
  - `Id` -> automatically assigned GUID
  - `Name` -> string storing the sub-component's name
  - `Type` -> Enum storing the type of the sub-component; used to distinguish between inherited classes in the database
  - `DatabaseEntryAt` -> date object storing when the entry was created in the database
  - `LastEditedAt` -> date object storing when the entry was last edited
  - `Note` -> nullable string storing any staff-only information

- CoolerSocketSubComponent (CPU cooler socket compatibility)
  - `SocketType` -> string storing the socket type supported by the cooler

- IntegratedGraphicsSubComponent (integrated graphics card attached to a CPU)
  - `Model` -> nullable string storing the model of the integrated graphics card
  - `BaseClockSpeed` -> integer storing the base clock speed of integrated graphics card in MHz
  - `BoostClockSpeed` -> integer storing the maximum boosted clock speed of the integrated graphics card in MHz
  - `CoreCount` -> integer storing the number of cores/shaders in an integrated graphics card

- M2SlotSubComponent (common motherboard slot of type M.2)
  - `Size` -> string storing the M.2 form factor size
  - `KeyType` -> string storing the key type of the M.2 slot
  - `Interface` -> string storing the M.2 interface specification

- OnboardEthernetSubComponent (motherboard's Onboard Ethernet)
  - `Speed` -> string storing the network speed
  - `Controller` -> string storing the network controller model

- PCIeSlotSubComponent (motherboard's PCIe slots)
  - `Gen` -> string storing the version of the PCIe slot
  - `Lanes` -> string storing the number of lanes for the PCIe slot

- PortSubComponent (generic port (e.g., USB, HDMI, DisplayPort))
  - `PortType` -> Enum storing the type of the port

## Controller methods
To see what fields should be provided in an API request check the swagger documentation.

### Basic CRUD API calls
- `GET/id` gets the specified object from the database using the id:
  - all users have access but returns differing amount of information.
- `POST/add` creates a new object with elements provided in the Body:
  - usually the user can create objects belonging to them;
  - staff can create objects related to user activity;
  - admins can create any object.
- `DELETE/id` removes the specified object from the database
  - usually the user can delete objects belonging to them;
  - staff can delete objects related to user activity;
  - admins can delete any object.
- `POST/get` gets a list of objects depending on the provided: allowed field values, sort order, page length and number:
  - all users have access but returns differing amount of information.
- `PUT/id` updates the specified object with the fields provided, only fields specified in the body get updated
  - all users can edit information related to themselves;
  - staff can edit sensitive user related information;
  - admins can modify any object.

### User specific API calls
- `Users/POST/change-password` allows the user to change their own password, requires the old and new password in the body

### Auth specific API calls
- `Auth/POST/login` allows anyone to login using their password and either Login or Email, sends confirmation email if enabled on user's account
- `Auth/POST/verify-2fa` redirect endpoint that verifies user login with 2fa, never call manually
- `Auth/POST/google-login` allows anyone to login using their google account, connects to google services, has some fields missing and requires further user account setup in the frontend (missing birth date)
- `Auth/POST/register` allows anyone to register a new account, requires providing all user account fields, sends confirmation email
- `Auth/POST/confirm-register` redirect endpoint that verifies user registration, never call manually, redirects to frontend
- `Auth/POST/reset-password` allows anyone to reset user's password, requires providing the old and new passwords, sends confirmation email
- `Auth/POST/confirm-reset-password` redirect endpoint that verifies password reset, never call manually, redirects to frontend

### Polymorphic class variation API calls
- `GET/id` works the same as the normal version except:
  - requires the user to specify what type of subclass to use in order to work properly
  - delivers a different response based on the type of subclass requested
- `POST/add` works the same as the normal version except:
  - requires the user to specify what type of subclass to use in order to work properly
  - the user has to provide specific fields correctly for each subclass
- `POST/get` works the same as the normal version except:
  - requires the user to specify what type of subclass to use in order to work properly
  - delivers a set of different responses based on the type of subclass requested
- `PUT/id` works the same as the normal version except:
  - requires the user to specify what type of subclass to use in order to work properly
  - the user has to provide specific fields correctly for each subclass
