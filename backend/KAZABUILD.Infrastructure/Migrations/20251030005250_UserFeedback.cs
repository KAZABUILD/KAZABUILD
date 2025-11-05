using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UserFeedback : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "UserFeedback",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Feedback = table.Column<string>(type: "nvarchar(max)", maxLength: 5000, nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserFeedback", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserFeedback_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserFeedback_UserId",
                table: "UserFeedback",
                column: "UserId");

            migrationBuilder.Sql(@"
                IF NOT EXISTS
                (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.UserFeedback'))
                    CREATE FULLTEXT INDEX ON UserFeedback(Feedback LANGUAGE 0)
                    KEY INDEX PK_UserFeedback;
            ", suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserFeedback");

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON UserFeedback;", suppressTransaction: true);
        }
    }
}
