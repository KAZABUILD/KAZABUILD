using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class MessageEncryption : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Messages;", suppressTransaction: true);

            migrationBuilder.RenameColumn(
                name: "Token",
                table: "UserTokens",
                newName: "TokenHash");

            migrationBuilder.RenameColumn(
                name: "Content",
                table: "Messages",
                newName: "CipherText");

            migrationBuilder.AddColumn<string>(
                name: "IV",
                table: "Messages",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.Sql(@"
                IF NOT EXISTS
                (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Messages'))
                    CREATE FULLTEXT INDEX ON Messages(Title LANGUAGE 0)
                    KEY INDEX PK_Messages;
            ", suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IV",
                table: "Messages");

            migrationBuilder.RenameColumn(
                name: "TokenHash",
                table: "UserTokens",
                newName: "Token");

            migrationBuilder.RenameColumn(
                name: "CipherText",
                table: "Messages",
                newName: "Content");

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Messages;", suppressTransaction: true);
        }
    }
}
