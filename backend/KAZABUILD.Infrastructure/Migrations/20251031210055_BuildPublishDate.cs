using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class BuildPublishDate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "PublishedAt",
                table: "Builds",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PublishedAt",
                table: "Builds");
        }
    }
}
