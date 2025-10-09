using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DatabaseComponentDomainFinal : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "RAMSlotsAmount",
                table: "MotherboardComponents",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ARGB5vHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AudioChipset",
                table: "MotherboardComponents",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "COMPortHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CPUOptionalFanHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CaseFanHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CPUFanHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "HasCMOS",
                table: "MotherboardComponents",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasECCSupport",
                table: "MotherboardComponents",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasFlashback",
                table: "MotherboardComponents",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasHDDLEDHeader",
                table: "MotherboardComponents",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "HasPowerButtonHeader",
                table: "MotherboardComponents",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "HasPowerLEDHeader",
                table: "MotherboardComponents",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "HasRAIDSupport",
                table: "MotherboardComponents",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HasResetButtonHeader",
                table: "MotherboardComponents",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MainPowerType",
                table: "MotherboardComponents",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "MaxAudioChannels",
                table: "MotherboardComponents",
                type: "decimal(3,1)",
                precision: 3,
                scale: 1,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "MaxRAMAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "PumpHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RGB12vHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SerialATAttachment3GBsAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SerialATAttachment6GBsAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TemperatureSensorHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ThunderboltHeaderAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "U2PortAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "WirelessNetworkingStandard",
                table: "MotherboardComponents",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AlterColumn<int>(
                name: "ModuleCapacity",
                table: "MemoryComponents",
                type: "int",
                precision: 8,
                scale: 2,
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(8,2)",
                oldPrecision: 8,
                oldScale: 2);

            migrationBuilder.AddColumn<string>(
                name: "ErrorCorrectingCode",
                table: "MemoryComponents",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<bool>(
                name: "HaveHeatSpreader",
                table: "MemoryComponents",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "HaveRGB",
                table: "MemoryComponents",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "Height",
                table: "MemoryComponents",
                type: "decimal(6,2)",
                precision: 6,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RegisteredType",
                table: "MemoryComponents",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<decimal>(
                name: "Voltage",
                table: "MemoryComponents",
                type: "decimal(4,2)",
                precision: 4,
                scale: 2,
                nullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "Length",
                table: "GPUComponents",
                type: "decimal(7,4)",
                precision: 7,
                scale: 4,
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(5,2)",
                oldPrecision: 5,
                oldScale: 2);

            migrationBuilder.AddColumn<int>(
                name: "Amount",
                table: "ComponentParts",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "DatabaseEntryAt",
                table: "Colors",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "LastEditedAt",
                table: "Colors",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "Note",
                table: "Colors",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "M2SlotSubcomponent",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Size = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    KeyType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Interface = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_M2SlotSubcomponent", x => x.Id);
                    table.ForeignKey(
                        name: "FK_M2SlotSubcomponent_SubComponents_Id",
                        column: x => x.Id,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "OnboardEthernetSubComponent",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Speed = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Controller = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OnboardEthernetSubComponent", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OnboardEthernetSubComponent_SubComponents_Id",
                        column: x => x.Id,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PCIeSlotSubComponent",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Gen = table.Column<string>(type: "nvarchar(5)", maxLength: 5, nullable: false),
                    Lanes = table.Column<string>(type: "nvarchar(5)", maxLength: 5, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PCIeSlotSubComponent", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PCIeSlotSubComponent_SubComponents_Id",
                        column: x => x.Id,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "M2SlotSubcomponent");

            migrationBuilder.DropTable(
                name: "OnboardEthernetSubComponent");

            migrationBuilder.DropTable(
                name: "PCIeSlotSubComponent");

            migrationBuilder.DropColumn(
                name: "ARGB5vHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "AudioChipset",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "COMPortHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "CPUOptionalFanHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "CaseFanHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "CPUFanHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "HasCMOS",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "HasECCSupport",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "HasFlashback",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "HasHDDLEDHeader",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "HasPowerButtonHeader",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "HasPowerLEDHeader",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "HasRAIDSupport",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "HasResetButtonHeader",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "MainPowerType",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "MaxAudioChannels",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "MaxRAMAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "PumpHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "RGB12vHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "SerialATAttachment3GBsAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "SerialATAttachment6GBsAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "TemperatureSensorHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "ThunderboltHeaderAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "U2PortAmount",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "WirelessNetworkingStandard",
                table: "MotherboardComponents");

            migrationBuilder.DropColumn(
                name: "ErrorCorrectingCode",
                table: "MemoryComponents");

            migrationBuilder.DropColumn(
                name: "HaveHeatSpreader",
                table: "MemoryComponents");

            migrationBuilder.DropColumn(
                name: "HaveRGB",
                table: "MemoryComponents");

            migrationBuilder.DropColumn(
                name: "Height",
                table: "MemoryComponents");

            migrationBuilder.DropColumn(
                name: "RegisteredType",
                table: "MemoryComponents");

            migrationBuilder.DropColumn(
                name: "Voltage",
                table: "MemoryComponents");

            migrationBuilder.DropColumn(
                name: "Amount",
                table: "ComponentParts");

            migrationBuilder.DropColumn(
                name: "DatabaseEntryAt",
                table: "Colors");

            migrationBuilder.DropColumn(
                name: "LastEditedAt",
                table: "Colors");

            migrationBuilder.DropColumn(
                name: "Note",
                table: "Colors");

            migrationBuilder.AlterColumn<int>(
                name: "RAMSlotsAmount",
                table: "MotherboardComponents",
                type: "int",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<decimal>(
                name: "ModuleCapacity",
                table: "MemoryComponents",
                type: "decimal(8,2)",
                precision: 8,
                scale: 2,
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldPrecision: 8,
                oldScale: 2);

            migrationBuilder.AlterColumn<decimal>(
                name: "Length",
                table: "GPUComponents",
                type: "decimal(5,2)",
                precision: 5,
                scale: 2,
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(7,4)",
                oldPrecision: 7,
                oldScale: 4);
        }
    }
}
