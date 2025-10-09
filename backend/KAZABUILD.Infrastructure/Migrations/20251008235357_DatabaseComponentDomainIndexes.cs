using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DatabaseComponentDomainIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ComponentColors");

            migrationBuilder.CreateTable(
                name: "ComponentVariants",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ColorCode = table.Column<string>(type: "nvarchar(7)", maxLength: 7, nullable: false),
                    IsAvailable = table.Column<bool>(type: "bit", nullable: false),
                    AdditionalPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 6, nullable: true),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ComponentVariants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ComponentVariants_Colors_ColorCode",
                        column: x => x.ColorCode,
                        principalTable: "Colors",
                        principalColumn: "ColorCode",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ComponentVariants_Components_ComponentId",
                        column: x => x.ComponentId,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ComponentVariants_ColorCode",
                table: "ComponentVariants",
                column: "ColorCode");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentVariants_ComponentId",
                table: "ComponentVariants",
                column: "ComponentId");

            migrationBuilder.RenameColumn(
                name: "ErrorCorrectingCode",
                table: "MemoryComponents",
                newName: "ECC");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ComponentVariants");

            migrationBuilder.CreateTable(
                name: "ComponentColors",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ColorCode = table.Column<string>(type: "nvarchar(7)", maxLength: 7, nullable: false),
                    ComponentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AdditionalPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 6, nullable: true),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsAvailable = table.Column<bool>(type: "bit", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ComponentColors", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ComponentColors_Colors_ColorCode",
                        column: x => x.ColorCode,
                        principalTable: "Colors",
                        principalColumn: "ColorCode",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ComponentColors_Components_ComponentId",
                        column: x => x.ComponentId,
                        principalTable: "Components",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ComponentColors_ColorCode",
                table: "ComponentColors",
                column: "ColorCode");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentColors_ComponentId",
                table: "ComponentColors",
                column: "ComponentId");

            migrationBuilder.RenameColumn(
                name: "ECC",
                table: "MemoryComponents",
                newName: "ErrorCorrectingCode");

        }
    }
}
