using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UserGuide : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "UserGuides",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Text = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Author = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Category = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    TimeToRead = table.Column<decimal>(type: "decimal(18,6)", precision: 18, scale: 6, nullable: false),
                    PostedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserGuides", x => x.Id);
                });

            migrationBuilder.Sql(@"
                IF NOT EXISTS
                (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.UserGuides'))
                    CREATE FULLTEXT INDEX ON UserGuides(Title LANGUAGE 0, Text LANGUAGE 0, Author LANGUAGE 0)
                    KEY INDEX PK_UserGuides;
            ", suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserGuides");

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON UserGuides;", suppressTransaction: true);
        }
    }
}
