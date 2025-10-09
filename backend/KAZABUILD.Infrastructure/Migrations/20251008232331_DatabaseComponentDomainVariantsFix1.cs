using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DatabaseComponentDomainVariantsFix1 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_M2SlotSubcomponent_SubComponents_Id",
                table: "M2SlotSubcomponent");

            migrationBuilder.DropForeignKey(
                name: "FK_OnboardEthernetSubComponent_SubComponents_Id",
                table: "OnboardEthernetSubComponent");

            migrationBuilder.DropForeignKey(
                name: "FK_PCIeSlotSubComponent_SubComponents_Id",
                table: "PCIeSlotSubComponent");

            migrationBuilder.DropPrimaryKey(
                name: "PK_PCIeSlotSubComponent",
                table: "PCIeSlotSubComponent");

            migrationBuilder.DropPrimaryKey(
                name: "PK_OnboardEthernetSubComponent",
                table: "OnboardEthernetSubComponent");

            migrationBuilder.DropPrimaryKey(
                name: "PK_M2SlotSubcomponent",
                table: "M2SlotSubcomponent");

            migrationBuilder.RenameTable(
                name: "PCIeSlotSubComponent",
                newName: "PCIeSlotSubComponents");

            migrationBuilder.RenameTable(
                name: "OnboardEthernetSubComponent",
                newName: "OnboardEthernetSubComponents");

            migrationBuilder.RenameTable(
                name: "M2SlotSubcomponent",
                newName: "M2SlotSubcomponents");

            migrationBuilder.AddPrimaryKey(
                name: "PK_PCIeSlotSubComponents",
                table: "PCIeSlotSubComponents",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_OnboardEthernetSubComponents",
                table: "OnboardEthernetSubComponents",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_M2SlotSubcomponents",
                table: "M2SlotSubcomponents",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_M2SlotSubcomponents_SubComponents_Id",
                table: "M2SlotSubcomponents",
                column: "Id",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_OnboardEthernetSubComponents_SubComponents_Id",
                table: "OnboardEthernetSubComponents",
                column: "Id",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PCIeSlotSubComponents_SubComponents_Id",
                table: "PCIeSlotSubComponents",
                column: "Id",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_M2SlotSubcomponents_SubComponents_Id",
                table: "M2SlotSubcomponents");

            migrationBuilder.DropForeignKey(
                name: "FK_OnboardEthernetSubComponents_SubComponents_Id",
                table: "OnboardEthernetSubComponents");

            migrationBuilder.DropForeignKey(
                name: "FK_PCIeSlotSubComponents_SubComponents_Id",
                table: "PCIeSlotSubComponents");

            migrationBuilder.DropPrimaryKey(
                name: "PK_PCIeSlotSubComponents",
                table: "PCIeSlotSubComponents");

            migrationBuilder.DropPrimaryKey(
                name: "PK_OnboardEthernetSubComponents",
                table: "OnboardEthernetSubComponents");

            migrationBuilder.DropPrimaryKey(
                name: "PK_M2SlotSubcomponents",
                table: "M2SlotSubcomponents");

            migrationBuilder.RenameTable(
                name: "PCIeSlotSubComponents",
                newName: "PCIeSlotSubComponent");

            migrationBuilder.RenameTable(
                name: "OnboardEthernetSubComponents",
                newName: "OnboardEthernetSubComponent");

            migrationBuilder.RenameTable(
                name: "M2SlotSubcomponents",
                newName: "M2SlotSubcomponent");

            migrationBuilder.AddPrimaryKey(
                name: "PK_PCIeSlotSubComponent",
                table: "PCIeSlotSubComponent",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_OnboardEthernetSubComponent",
                table: "OnboardEthernetSubComponent",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_M2SlotSubcomponent",
                table: "M2SlotSubcomponent",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_M2SlotSubcomponent_SubComponents_Id",
                table: "M2SlotSubcomponent",
                column: "Id",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_OnboardEthernetSubComponent_SubComponents_Id",
                table: "OnboardEthernetSubComponent",
                column: "Id",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PCIeSlotSubComponent_SubComponents_Id",
                table: "PCIeSlotSubComponent",
                column: "Id",
                principalTable: "SubComponents",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
