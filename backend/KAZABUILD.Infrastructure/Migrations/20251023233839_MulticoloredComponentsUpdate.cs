using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class MulticoloredComponentsUpdate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP FULLTEXT INDEX ON ComponentVariants;", suppressTransaction: true);

            migrationBuilder.DropForeignKey(
                name: "FK_ComponentVariants_Colors_ColorCode",
                table: "ComponentVariants");

            migrationBuilder.DropIndex(
                name: "IX_ComponentVariants_ColorCode",
                table: "ComponentVariants");

            migrationBuilder.DropColumn(
                name: "ColorCode",
                table: "ComponentVariants");

            migrationBuilder.CreateTable(
                name: "ColorVariants",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ColorCode = table.Column<string>(type: "nvarchar(7)", maxLength: 7, nullable: false),
                    ComponentVariantId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ColorVariants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ColorVariants_Colors_ColorCode",
                        column: x => x.ColorCode,
                        principalTable: "Colors",
                        principalColumn: "ColorCode",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ColorVariants_ComponentVariants_ComponentVariantId",
                        column: x => x.ComponentVariantId,
                        principalTable: "ComponentVariants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ColorVariants_ColorCode",
                table: "ColorVariants",
                column: "ColorCode");

            migrationBuilder.CreateIndex(
                name: "IX_ColorVariants_ComponentVariantId",
                table: "ColorVariants",
                column: "ComponentVariantId");

            migrationBuilder.Sql(@"
                IF NOT EXISTS
                (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.ColorVariants'))
                    CREATE FULLTEXT INDEX ON ColorVariants(ColorCode LANGUAGE 0)
                    KEY INDEX PK_ColorVariants;
            ", suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ColorVariants");

            migrationBuilder.AddColumn<string>(
                name: "ColorCode",
                table: "ComponentVariants",
                type: "nvarchar(7)",
                maxLength: 7,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_ComponentVariants_ColorCode",
                table: "ComponentVariants",
                column: "ColorCode");

            migrationBuilder.AddForeignKey(
                name: "FK_ComponentVariants_Colors_ColorCode",
                table: "ComponentVariants",
                column: "ColorCode",
                principalTable: "Colors",
                principalColumn: "ColorCode",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON ColorVariants;", suppressTransaction: true);
        }
    }
}
