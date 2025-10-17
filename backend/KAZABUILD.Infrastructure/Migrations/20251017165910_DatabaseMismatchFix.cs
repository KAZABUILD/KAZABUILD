using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DatabaseMismatchFix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "SupportsErrorCorrectingCode",
                table: "CPUComponents",
                newName: "SupportsECC");

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Tags;", suppressTransaction: true);

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "Tags",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.BuildInteractions'))
                    CREATE FULLTEXT INDEX ON BuildInteractions(UserNote LANGUAGE 0)
                    KEY INDEX PK_BuildInteractions;",
                suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "SupportsECC",
                table: "CPUComponents",
                newName: "SupportsErrorCorrectingCode");

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "Tags",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(500)",
                oldMaxLength: 500);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Tags;", suppressTransaction: true);
        }
    }
}
