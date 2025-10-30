using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KAZABUILD.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DatabaseComponentDomainIndexesFinal : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            //Add indexes on Component Domain tables
            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.PCIeSlotSubComponents'))
                    CREATE FULLTEXT INDEX ON PCIeSlotSubComponents(Gen LANGUAGE 0, Lanes LANGUAGE 0)
                    KEY INDEX PK_PCIeSlotSubComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.OnboardEthernetSubComponents'))
                    CREATE FULLTEXT INDEX ON OnboardEthernetSubComponents(Speed LANGUAGE 0, Controller LANGUAGE 0)
                    KEY INDEX PK_OnboardEthernetSubComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.M2SlotSubComponents'))
                    CREATE FULLTEXT INDEX ON M2SlotSubComponents(Size LANGUAGE 0, KeyType LANGUAGE 0, Interface LANGUAGE 0)
                    KEY INDEX PK_M2SlotSubComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.IntegratedGraphicsSubComponents'))
                    CREATE FULLTEXT INDEX ON IntegratedGraphicsSubComponents(Model LANGUAGE 0)
                    KEY INDEX PK_IntegratedGraphicsSubComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.CoolerSocketSubComponents'))
                    CREATE FULLTEXT INDEX ON CoolerSocketSubComponents(SocketType LANGUAGE 0)
                    KEY INDEX PK_CoolerSocketSubComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.PortSubComponents'))
                    CREATE FULLTEXT INDEX ON PortSubComponents(PortType LANGUAGE 0)
                    KEY INDEX PK_PortSubComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.SubComponents'))
                    CREATE FULLTEXT INDEX ON SubComponents(Name LANGUAGE 0, Type LANGUAGE 0)
                    KEY INDEX PK_SubComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.ComponentVariants'))
                    CREATE FULLTEXT INDEX ON ComponentVariants(ColorCode LANGUAGE 0)
                    KEY INDEX PK_ComponentVariants;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.StorageComponents'))
                    CREATE FULLTEXT INDEX ON StorageComponents(Series LANGUAGE 0, DriveType LANGUAGE 0, FormFactor LANGUAGE 0, Interface LANGUAGE 0)
                    KEY INDEX PK_StorageComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.PowerSupplyComponents'))
                    CREATE FULLTEXT INDEX ON PowerSupplyComponents(FormFactor LANGUAGE 0, EfficiencyRating LANGUAGE 0, ModularityType LANGUAGE 0)
                    KEY INDEX PK_PowerSupplyComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.MotherboardComponents'))
                    CREATE FULLTEXT INDEX ON MotherboardComponents(SocketType LANGUAGE 0, FormFactor LANGUAGE 0, ChipsetType LANGUAGE 0, RAMType LANGUAGE 0, WirelessNetworkingStandard LANGUAGE 0, MainPowerType LANGUAGE 0, AudioChipset LANGUAGE 0)
                    KEY INDEX PK_MotherboardComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.MonitorComponents'))
                    CREATE FULLTEXT INDEX ON MonitorComponents(PanelType LANGUAGE 0, ViewingAngle LANGUAGE 0, AspectRatio LANGUAGE 0, HighDynamicRangeType LANGUAGE 0, AdaptiveSyncType LANGUAGE 0)
                    KEY INDEX PK_MonitorComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.MemoryComponents'))
                    CREATE FULLTEXT INDEX ON MemoryComponents(RAMType LANGUAGE 0, FormFactor LANGUAGE 0, Timings LANGUAGE 0, ECC LANGUAGE 0, RegisteredType LANGUAGE 0)
                    KEY INDEX PK_MemoryComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.GPUComponents'))
                    CREATE FULLTEXT INDEX ON GPUComponents(VideoMemoryType LANGUAGE 0, FrameSync LANGUAGE 0, CoolingType LANGUAGE 0)
                    KEY INDEX PK_GPUComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.CPUComponents'))
                    CREATE FULLTEXT INDEX ON CPUComponents(Series LANGUAGE 0, Microarchitecture LANGUAGE 0, CoreFamily LANGUAGE 0, SocketType LANGUAGE 0, Lithography LANGUAGE 0, MemoryType LANGUAGE 0, PackagingType LANGUAGE 0)
                    KEY INDEX PK_CPUComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.CaseComponents'))
                    CREATE FULLTEXT INDEX ON CaseComponents(FormFactor LANGUAGE 0, SidePanelType LANGUAGE 0)
                    KEY INDEX PK_CaseComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.CaseFanComponents'))
                    CREATE FULLTEXT INDEX ON CaseFanComponents(LEDType LANGUAGE 0, ConnectorType LANGUAGE 0, ControllerType LANGUAGE 0, FlowDirection LANGUAGE 0)
                    KEY INDEX PK_CaseFanComponents;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Components'))
                    CREATE FULLTEXT INDEX ON Components(Name LANGUAGE 0, Manufacturer LANGUAGE 0, Type LANGUAGE 0)
                    KEY INDEX PK_Components;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.ComponentReviews'))
                    CREATE FULLTEXT INDEX ON ComponentReviews(ReviewerName LANGUAGE 0, ReviewText LANGUAGE 0)
                    KEY INDEX PK_ComponentReviews;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.ComponentPrices'))
                    CREATE FULLTEXT INDEX ON ComponentPrices(VendorName LANGUAGE 0, Currency LANGUAGE 0)
                    KEY INDEX PK_ComponentPrices;",
                suppressTransaction: true);

            migrationBuilder.Sql(@"
                IF NOT EXISTS (SELECT * FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('dbo.Colors'))
                    CREATE FULLTEXT INDEX ON Colors(ColorCode LANGUAGE 0, ColorName LANGUAGE 0)
                    KEY INDEX PK_Colors;",
                suppressTransaction: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            //Drop Indexes on Component Domain tables
            migrationBuilder.Sql("DROP FULLTEXT INDEX ON PCIeSlotSubComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON OnboardEthernetSubComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON M2SlotSubComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON IntegratedGraphicsSubComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON CoolerSocketSubComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON PortSubComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON SubComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON ComponentVariants;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON StorageComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON PowerSupplyComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON MotherboardComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON MonitorComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON MemoryComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON GPUComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON CPUComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON CaseFanComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON CaseComponents;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Components;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON ComponentReviews;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON ComponentPrices;", suppressTransaction: true);

            migrationBuilder.Sql("DROP FULLTEXT INDEX ON Colors;", suppressTransaction: true);
        }
    }
}
