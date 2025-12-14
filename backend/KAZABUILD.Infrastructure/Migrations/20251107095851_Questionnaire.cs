using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Questionnaire : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserPreferences_Users_UserId",
                table: "UserPreferences");

            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_UserId",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "UserPreferences");

            migrationBuilder.AddColumn<string>(
                name: "Question",
                table: "UserPreferences",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "UserPreferenceAnswerId",
                table: "UserPreferences",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "UserPreferenceAnswers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserPreferenceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Answer = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserPreferenceAnswers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserPreferenceAnswers_UserPreferences_UserPreferenceId",
                        column: x => x.UserPreferenceId,
                        principalTable: "UserPreferences",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserAnswers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserPreferenceAnswerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DatabaseEntryAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastEditedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserAnswers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserAnswers_UserPreferenceAnswers_UserPreferenceAnswerId",
                        column: x => x.UserPreferenceAnswerId,
                        principalTable: "UserPreferenceAnswers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UserAnswers_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_UserPreferenceAnswerId",
                table: "UserPreferences",
                column: "UserPreferenceAnswerId",
                unique: true,
                filter: "[UserPreferenceAnswerId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_UserAnswers_UserId",
                table: "UserAnswers",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAnswers_UserPreferenceAnswerId",
                table: "UserAnswers",
                column: "UserPreferenceAnswerId");

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferenceAnswers_UserPreferenceId",
                table: "UserPreferenceAnswers",
                column: "UserPreferenceId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserPreferences_UserPreferenceAnswers_UserPreferenceAnswerId",
                table: "UserPreferences",
                column: "UserPreferenceAnswerId",
                principalTable: "UserPreferenceAnswers",
                principalColumn: "Id");

            migrationBuilder.Sql(@"
                IF NOT EXISTS
                (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.UserPreferences'))
                    CREATE FULLTEXT INDEX ON UserPreferences(Question LANGUAGE 0)
                    KEY INDEX PK_UserPreferences;
            ", suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS
                (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.UserPreferenceAnswers'))
                    CREATE FULLTEXT INDEX ON UserPreferenceAnswers(Answer LANGUAGE 0)
                    KEY INDEX PK_UserPreferenceAnswers;
            ", suppressTransaction: true);

        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserPreferences_UserPreferenceAnswers_UserPreferenceAnswerId",
                table: "UserPreferences");

            migrationBuilder.DropTable(
                name: "UserAnswers");

            migrationBuilder.DropTable(
                name: "UserPreferenceAnswers");

            migrationBuilder.DropIndex(
                name: "IX_UserPreferences_UserPreferenceAnswerId",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "Question",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "UserPreferenceAnswerId",
                table: "UserPreferences");

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "UserPreferences",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_UserPreferences_UserId",
                table: "UserPreferences",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserPreferences_Users_UserId",
                table: "UserPreferences",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON UserPreferences;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON UserPreferenceAnswers;", suppressTransaction: true);
        }
    }
}
