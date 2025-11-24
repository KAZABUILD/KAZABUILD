using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ImagesExpansion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "DeletedUserId",
                table: "UserComments",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "DeletedReceiverId",
                table: "Messages",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "DeletedSenderId",
                table: "Messages",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "MessageId",
                table: "Images",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "UserGuideId",
                table: "Images",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Images_MessageId",
                table: "Images",
                column: "MessageId");

            migrationBuilder.CreateIndex(
                name: "IX_Images_UserGuideId",
                table: "Images",
                column: "UserGuideId");

            migrationBuilder.AddForeignKey(
                name: "FK_Images_Messages_MessageId",
                table: "Images",
                column: "MessageId",
                principalTable: "Messages",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Images_UserGuides_UserGuideId",
                table: "Images",
                column: "UserGuideId",
                principalTable: "UserGuides",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Images_Messages_MessageId",
                table: "Images");

            migrationBuilder.DropForeignKey(
                name: "FK_Images_UserGuides_UserGuideId",
                table: "Images");

            migrationBuilder.DropIndex(
                name: "IX_Images_MessageId",
                table: "Images");

            migrationBuilder.DropIndex(
                name: "IX_Images_UserGuideId",
                table: "Images");

            migrationBuilder.DropColumn(
                name: "DeletedUserId",
                table: "UserComments");

            migrationBuilder.DropColumn(
                name: "DeletedReceiverId",
                table: "Messages");

            migrationBuilder.DropColumn(
                name: "DeletedSenderId",
                table: "Messages");

            migrationBuilder.DropColumn(
                name: "MessageId",
                table: "Images");

            migrationBuilder.DropColumn(
                name: "UserGuideId",
                table: "Images");
        }
    }
}
