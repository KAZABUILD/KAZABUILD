using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class MotherboardSataFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "SerialATAttachment6GBsAmount",
                table: "MotherboardComponents",
                newName: "SATA6GBsAmount");

            migrationBuilder.RenameColumn(
                name: "SerialATAttachment3GBsAmount",
                table: "MotherboardComponents",
                newName: "SATA3GBsAmount");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "SATA6GBsAmount",
                table: "MotherboardComponents",
                newName: "SerialATAttachment6GBsAmount");

            migrationBuilder.RenameColumn(
                name: "SATA3GBsAmount",
                table: "MotherboardComponents",
                newName: "SerialATAttachment3GBsAmount");
        }
    }
}
