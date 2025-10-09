using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ComponentsDomainPrecisionFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ComponentColor_Color_ColorCode",
                table: "ComponentColor");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentColor_Components_ComponentId",
                table: "ComponentColor");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentCompatibility_Components_CompatibleComponentId",
                table: "ComponentCompatibility");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentCompatibility_Components_ComponentId",
                table: "ComponentCompatibility");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentPart_Components_ComponentId",
                table: "ComponentPart");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentPart_SubComponents_SubComponentId",
                table: "ComponentPart");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentPrice_Components_ComponentId",
                table: "ComponentPrice");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentReview_Components_ComponentId",
                table: "ComponentReview");

            migrationBuilder.DropForeignKey(
                name: "FK_SubComponentPart_SubComponents_MainSubComponentId",
                table: "SubComponentPart");

            migrationBuilder.DropForeignKey(
                name: "FK_SubComponentPart_SubComponents_SubComponentId",
                table: "SubComponentPart");

            migrationBuilder.DropPrimaryKey(
                name: "PK_SubComponentPart",
                table: "SubComponentPart");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentReview",
                table: "ComponentReview");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentPrice",
                table: "ComponentPrice");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentPart",
                table: "ComponentPart");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentCompatibility",
                table: "ComponentCompatibility");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentColor",
                table: "ComponentColor");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Color",
                table: "Color");

            migrationBuilder.RenameTable(
                name: "SubComponentPart",
                newName: "SubComponentParts");

            migrationBuilder.RenameTable(
                name: "ComponentReview",
                newName: "ComponentReviews");

            migrationBuilder.RenameTable(
                name: "ComponentPrice",
                newName: "ComponentPrices");

            migrationBuilder.RenameTable(
                name: "ComponentPart",
                newName: "ComponentParts");

            migrationBuilder.RenameTable(
                name: "ComponentCompatibility",
                newName: "ComponentCompatibilities");

            migrationBuilder.RenameTable(
                name: "ComponentColor",
                newName: "ComponentColors");

            migrationBuilder.RenameTable(
                name: "Color",
                newName: "Colors");

            migrationBuilder.RenameIndex(
                name: "IX_SubComponentPart_SubComponentId",
                table: "SubComponentParts",
                newName: "IX_SubComponentParts_SubComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_SubComponentPart_MainSubComponentId",
                table: "SubComponentParts",
                newName: "IX_SubComponentParts_MainSubComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentReview_ComponentId",
                table: "ComponentReviews",
                newName: "IX_ComponentReviews_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentPrice_ComponentId",
                table: "ComponentPrices",
                newName: "IX_ComponentPrices_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentPart_SubComponentId",
                table: "ComponentParts",
                newName: "IX_ComponentParts_SubComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentPart_ComponentId",
                table: "ComponentParts",
                newName: "IX_ComponentParts_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentCompatibility_ComponentId",
                table: "ComponentCompatibilities",
                newName: "IX_ComponentCompatibilities_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentCompatibility_CompatibleComponentId",
                table: "ComponentCompatibilities",
                newName: "IX_ComponentCompatibilities_CompatibleComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentColor_ComponentId",
                table: "ComponentColors",
                newName: "IX_ComponentColors_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentColor_ColorCode",
                table: "ComponentColors",
                newName: "IX_ComponentColors_ColorCode");

            migrationBuilder.AddPrimaryKey(
                name: "PK_SubComponentParts",
                table: "SubComponentParts",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentReviews",
                table: "ComponentReviews",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentPrices",
                table: "ComponentPrices",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentParts",
                table: "ComponentParts",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentCompatibilities",
                table: "ComponentCompatibilities",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentColors",
                table: "ComponentColors",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Colors",
                table: "Colors",
                column: "ColorCode");

            migrationBuilder.CreateTable(
                name: "CoolerSocketSubComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SocketType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CoolerSocketSubComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CoolerSocketSubComponents_SubComponents_Id",
                        column: x => x.Id,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "IntegratedGraphicsSubComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Model = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    BaseClockSpeed = table.Column<int>(type: "int", nullable: false),
                    BoostClockSpeed = table.Column<int>(type: "int", nullable: false),
                    CoreCount = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IntegratedGraphicsSubComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_IntegratedGraphicsSubComponents_SubComponents_Id",
                        column: x => x.Id,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PortSubComponents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    PortType = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PortSubComponents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PortSubComponents_SubComponents_Id",
                        column: x => x.Id,
                        principalTable: "SubComponents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentColors_Colors_ColorCode",
                table: "ComponentColors",
                column: "ColorCode",
                principalTable: "Colors",
                principalColumn: "ColorCode",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentColors_Components_ComponentId",
                table: "ComponentColors",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentCompatibilities_Components_CompatibleComponentId",
                table: "ComponentCompatibilities",
                column: "CompatibleComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentCompatibilities_Components_ComponentId",
                table: "ComponentCompatibilities",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentParts_Components_ComponentId",
                table: "ComponentParts",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentParts_SubComponents_SubComponentId",
                table: "ComponentParts",
                column: "SubComponentId",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentPrices_Components_ComponentId",
                table: "ComponentPrices",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentReviews_Components_ComponentId",
                table: "ComponentReviews",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_SubComponentParts_SubComponents_MainSubComponentId",
                table: "SubComponentParts",
                column: "MainSubComponentId",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_SubComponentParts_SubComponents_SubComponentId",
                table: "SubComponentParts",
                column: "SubComponentId",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ComponentColors_Colors_ColorCode",
                table: "ComponentColors");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentColors_Components_ComponentId",
                table: "ComponentColors");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentCompatibilities_Components_CompatibleComponentId",
                table: "ComponentCompatibilities");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentCompatibilities_Components_ComponentId",
                table: "ComponentCompatibilities");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentParts_Components_ComponentId",
                table: "ComponentParts");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentParts_SubComponents_SubComponentId",
                table: "ComponentParts");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentPrices_Components_ComponentId",
                table: "ComponentPrices");

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentReviews_Components_ComponentId",
                table: "ComponentReviews");

            migrationBuilder.DropForeignKey(
                name: "FK_SubComponentParts_SubComponents_MainSubComponentId",
                table: "SubComponentParts");

            migrationBuilder.DropForeignKey(
                name: "FK_SubComponentParts_SubComponents_SubComponentId",
                table: "SubComponentParts");

            migrationBuilder.DropTable(
                name: "CoolerSocketSubComponents");

            migrationBuilder.DropTable(
                name: "IntegratedGraphicsSubComponents");

            migrationBuilder.DropTable(
                name: "PortSubComponents");

            migrationBuilder.DropPrimaryKey(
                name: "PK_SubComponentParts",
                table: "SubComponentParts");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentReviews",
                table: "ComponentReviews");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentPrices",
                table: "ComponentPrices");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentParts",
                table: "ComponentParts");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentCompatibilities",
                table: "ComponentCompatibilities");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ComponentColors",
                table: "ComponentColors");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Colors",
                table: "Colors");

            migrationBuilder.RenameTable(
                name: "SubComponentParts",
                newName: "SubComponentPart");

            migrationBuilder.RenameTable(
                name: "ComponentReviews",
                newName: "ComponentReview");

            migrationBuilder.RenameTable(
                name: "ComponentPrices",
                newName: "ComponentPrice");

            migrationBuilder.RenameTable(
                name: "ComponentParts",
                newName: "ComponentPart");

            migrationBuilder.RenameTable(
                name: "ComponentCompatibilities",
                newName: "ComponentCompatibility");

            migrationBuilder.RenameTable(
                name: "ComponentColors",
                newName: "ComponentColor");

            migrationBuilder.RenameTable(
                name: "Colors",
                newName: "Color");

            migrationBuilder.RenameIndex(
                name: "IX_SubComponentParts_SubComponentId",
                table: "SubComponentPart",
                newName: "IX_SubComponentPart_SubComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_SubComponentParts_MainSubComponentId",
                table: "SubComponentPart",
                newName: "IX_SubComponentPart_MainSubComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentReviews_ComponentId",
                table: "ComponentReview",
                newName: "IX_ComponentReview_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentPrices_ComponentId",
                table: "ComponentPrice",
                newName: "IX_ComponentPrice_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentParts_SubComponentId",
                table: "ComponentPart",
                newName: "IX_ComponentPart_SubComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentParts_ComponentId",
                table: "ComponentPart",
                newName: "IX_ComponentPart_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentCompatibilities_ComponentId",
                table: "ComponentCompatibility",
                newName: "IX_ComponentCompatibility_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentCompatibilities_CompatibleComponentId",
                table: "ComponentCompatibility",
                newName: "IX_ComponentCompatibility_CompatibleComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentColors_ComponentId",
                table: "ComponentColor",
                newName: "IX_ComponentColor_ComponentId");

            migrationBuilder.RenameIndex(
                name: "IX_ComponentColors_ColorCode",
                table: "ComponentColor",
                newName: "IX_ComponentColor_ColorCode");

            migrationBuilder.AddPrimaryKey(
                name: "PK_SubComponentPart",
                table: "SubComponentPart",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentReview",
                table: "ComponentReview",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentPrice",
                table: "ComponentPrice",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentPart",
                table: "ComponentPart",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentCompatibility",
                table: "ComponentCompatibility",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ComponentColor",
                table: "ComponentColor",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Color",
                table: "Color",
                column: "ColorCode");

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentColor_Color_ColorCode",
                table: "ComponentColor",
                column: "ColorCode",
                principalTable: "Color",
                principalColumn: "ColorCode",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentColor_Components_ComponentId",
                table: "ComponentColor",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentCompatibility_Components_CompatibleComponentId",
                table: "ComponentCompatibility",
                column: "CompatibleComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentCompatibility_Components_ComponentId",
                table: "ComponentCompatibility",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentPart_Components_ComponentId",
                table: "ComponentPart",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentPart_SubComponents_SubComponentId",
                table: "ComponentPart",
                column: "SubComponentId",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentPrice_Components_ComponentId",
                table: "ComponentPrice",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentReview_Components_ComponentId",
                table: "ComponentReview",
                column: "ComponentId",
                principalTable: "Components",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_SubComponentPart_SubComponents_MainSubComponentId",
                table: "SubComponentPart",
                column: "MainSubComponentId",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_SubComponentPart_SubComponents_SubComponentId",
                table: "SubComponentPart",
                column: "SubComponentId",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
