using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ComponentsDomain : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Color",
                columns: table => new
                {
                    ColorCode = table.Column<string>(type: "nvarchar(7)", maxLength: 7, nullable: false),
                    ColorName = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Color", x => x.ColorCode);
                });

            migrationBuilder.CreateTable(
                name: "Components",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Manufacturer = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Release = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Components", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SubComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubComponents", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CaseComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FormFactor = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PowerSupplyShrouded = table.Column<bool>(type: "bit", nullable: false),
                    PowerSupplyAmount = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    HasTransparentSidePanel = table.Column<bool>(type: "bit", nullable: false),
                    SidePanelType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    MaxVideoCardLength = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    MaxCPUCoolerHeight = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Internal35BayAmount = table.Column<int>(type: "int", nullable: false),
                    Internal25BayAmount = table.Column<int>(type: "int", nullable: false),
                    External35BayAmount = table.Column<int>(type: "int", nullable: false),
                    External525BayAmount = table.Column<int>(type: "int", nullable: false),
                    ExpansionSlotAmount = table.Column<int>(type: "int", nullable: false),
                    Dimensions_Depth = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Dimensions_Height = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Dimensions_Width = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Weight = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    SupportsRearConnectingMotherboard = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CaseComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CaseComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CaseFanComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Size = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Quantity = table.Column<int>(type: "int", nullable: false),
                    MinAirflow = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    MaxAirflow = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    MinNoiseLevel = table.Column<int>(type: "int", nullable: false),
                    MaxNoiseLevel = table.Column<int>(type: "int", nullable: true),
                    PulseWidthModulation = table.Column<bool>(type: "bit", nullable: false),
                    LEDType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    ConnectorType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    ControllerType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    StaticPressureAmount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    FlowDirection = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CaseFanComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CaseFanComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ComponentColor",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ColorCode = table.Column<string>(type: "nvarchar(7)", maxLength: 7, nullable: false),
                    IsAvailable = table.Column<bool>(type: "bit", nullable: false),
                    AdditionalPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ComponentColor", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ComponentColor_Color_ColorCode",
                        column: x => x.ColorCode,
                        principalTable: "Color",
                        principalColumn: "ColorCode",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ComponentColor_Components_ComponentId",
                        column: x => x.ComponentId,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ComponentCompatibility",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CompatibleComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ComponentCompatibility", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ComponentCompatibility_Components_CompatibleComponentId",
                        column: x => x.CompatibleComponentId,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ComponentCompatibility_Components_ComponentId",
                        column: x => x.ComponentId,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ComponentPrice",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SourceUrl = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    ComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    VendorName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    FetchedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Price = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "nvarchar(4)", maxLength: 4, nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ComponentPrice", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ComponentPrice_Components_ComponentId",
                        column: x => x.ComponentId,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ComponentReview",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SourceUrl = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    ReviewerName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FetchedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Rating = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    ReviewText = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ComponentReview", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ComponentReview_Components_ComponentId",
                        column: x => x.ComponentId,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CoolerComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MinFanRotationSpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    MaxFanRotationSpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    MinNoiseLevel = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    MaxNoiseLevel = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    Height = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    IsWaterCooled = table.Column<bool>(type: "bit", nullable: false),
                    RadiatorSize = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    CanOperateFanless = table.Column<bool>(type: "bit", nullable: false),
                    FanSize = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    FanQuantity = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CoolerComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CoolerComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CPUComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Series = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Microarchitecture = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    CoreFamily = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    SocketType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CoreTotal = table.Column<int>(type: "int", nullable: false),
                    PerformanceAmount = table.Column<int>(type: "int", nullable: true),
                    EfficiencyAmount = table.Column<int>(type: "int", nullable: true),
                    ThreadsAmount = table.Column<int>(type: "int", nullable: false),
                    BasePerformanceSpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    BoostPerformanceSpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    BaseEfficiencySpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    BoostEfficiencySpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    L1 = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    L2 = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    L3 = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    L4 = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    IncludesCooler = table.Column<bool>(type: "bit", nullable: false),
                    Lithography = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    SupportsSimultaneousMultithreading = table.Column<bool>(type: "bit", nullable: false),
                    MemoryType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    PackagingType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    SupportsErrorCorrectingCode = table.Column<bool>(type: "bit", nullable: false),
                    ThermalDesignPower = table.Column<decimal>(type: "decimal(18,2)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CPUComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CPUComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "GPUComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Chipset = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    VideoMemoryAmount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    VideoMemoryType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CoreBaseClockSpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    CoreBoostClockSpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    CoreCount = table.Column<int>(type: "int", nullable: false),
                    EffectiveMemoryClockSpeed = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    MemoryBusWidth = table.Column<int>(type: "int", nullable: false),
                    FrameSync = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Length = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    ThermalDesignPower = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    CaseExpansionSlotWidth = table.Column<int>(type: "int", nullable: false),
                    TotalSlotWidth = table.Column<int>(type: "int", nullable: false),
                    CoolingType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GPUComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GPUComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MemoryComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Speed = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    RAMType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    FormFactor = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Capacity = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    CASLatency = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Timings = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    ModuleQuantity = table.Column<int>(type: "int", nullable: false),
                    ModuleCapacity = table.Column<decimal>(type: "decimal(18,2)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MemoryComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MemoryComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MonitorComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ScreenSize = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    HorizontalResolution = table.Column<int>(type: "int", nullable: false),
                    VerticalResolution = table.Column<int>(type: "int", nullable: false),
                    MaxRefreshRate = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    PanelType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ResponseTime = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    ViewingAngle = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    AspectRatio = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    MaxBrightness = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    HighDynamicRangeType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    AdaptiveSyncType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MonitorComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MonitorComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MotherboardComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SocketType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    FormFactor = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ChipsetType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RAMType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RAMSlotsAmount = table.Column<decimal>(type: "decimal(18,2)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MotherboardComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MotherboardComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PowerSupplyComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PowerOutput = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    FormFactor = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    EfficiencyRating = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    ModularityType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Length = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    IsFanless = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PowerSupplyComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PowerSupplyComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StorageComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Series = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Capacity = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    DriveType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    FormFactor = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Interface = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    HasNVMe = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StorageComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StorageComponents_Components_Id",
                        column: x => x.Id,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ComponentPart",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SubComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ComponentPart", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ComponentPart_Components_ComponentId",
                        column: x => x.ComponentId,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ComponentPart_SubComponents_SubComponentId",
                        column: x => x.SubComponentId,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SubComponentPart",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MainSubComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SubComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubComponentPart", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SubComponentPart_SubComponents_MainSubComponentId",
                        column: x => x.MainSubComponentId,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SubComponentPart_SubComponents_SubComponentId",
                        column: x => x.SubComponentId,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ComponentColor_ColorCode",
                table: "ComponentColor",
                column: "ColorCode");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentColor_ComponentId",
                table: "ComponentColor",
                column: "ComponentId");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentCompatibility_CompatibleComponentId",
                table: "ComponentCompatibility",
                column: "CompatibleComponentId");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentCompatibility_ComponentId",
                table: "ComponentCompatibility",
                column: "ComponentId");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentPart_ComponentId",
                table: "ComponentPart",
                column: "ComponentId");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentPart_SubComponentId",
                table: "ComponentPart",
                column: "SubComponentId");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentPrice_ComponentId",
                table: "ComponentPrice",
                column: "ComponentId");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentReview_ComponentId",
                table: "ComponentReview",
                column: "ComponentId");

            migrationBuilder.CreateIndex(
                name: "IX_SubComponentPart_MainSubComponentId",
                table: "SubComponentPart",
                column: "MainSubComponentId");

            migrationBuilder.CreateIndex(
                name: "IX_SubComponentPart_SubComponentId",
                table: "SubComponentPart",
                column: "SubComponentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CaseComponents");

            migrationBuilder.DropTable(
                name: "CaseFanComponents");

            migrationBuilder.DropTable(
                name: "ComponentColor");

            migrationBuilder.DropTable(
                name: "ComponentCompatibility");

            migrationBuilder.DropTable(
                name: "ComponentPart");

            migrationBuilder.DropTable(
                name: "ComponentPrice");

            migrationBuilder.DropTable(
                name: "ComponentReview");

            migrationBuilder.DropTable(
                name: "CoolerComponents");

            migrationBuilder.DropTable(
                name: "CPUComponents");

            migrationBuilder.DropTable(
                name: "GPUComponents");

            migrationBuilder.DropTable(
                name: "MemoryComponents");

            migrationBuilder.DropTable(
                name: "MonitorComponents");

            migrationBuilder.DropTable(
                name: "MotherboardComponents");

            migrationBuilder.DropTable(
                name: "PowerSupplyComponents");

            migrationBuilder.DropTable(
                name: "StorageComponents");

            migrationBuilder.DropTable(
                name: "SubComponentPart");

            migrationBuilder.DropTable(
                name: "Color");

            migrationBuilder.DropTable(
                name: "Components");

            migrationBuilder.DropTable(
                name: "SubComponents");
        }
    }
}
