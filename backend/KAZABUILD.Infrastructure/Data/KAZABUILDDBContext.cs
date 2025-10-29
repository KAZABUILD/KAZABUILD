using KAZABUILD.Application.Helpers;
using KAZABUILD.Domain.Entities;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Entities.Components.SubComponents;
using KAZABUILD.Domain.Entities.Users;

using Microsoft.EntityFrameworkCore;

namespace KAZABUILD.Infrastructure.Data
{
    public class KAZABUILDDBContext : DbContext
    {
        public KAZABUILDDBContext(DbContextOptions<KAZABUILDDBContext> options) : base(options)
        {
        }

        //General tables
        public DbSet<Image> Images { get; set; } = default!;
        public DbSet<Log> Logs { get; set; } = default!;
        public DbSet<BlockedIp> BlockedIps { get; set; }

        //User related tables
        public DbSet<User> Users { get; set; } = default!;
        public DbSet<UserPreference> UserPreferences { get; set; } = default!;
        public DbSet<UserFollow> UserFollows { get; set; } = default!;
        public DbSet<UserToken> UserTokens { get; set; } = default!;
        public DbSet<UserComment> UserComments { get; set; } = default!;
        public DbSet<ForumPost> ForumPosts { get; set; } = default!;
        public DbSet<Message> Messages { get; set; } = default!;
        public DbSet<Notification> Notifications { get; set; } = default!;
        public DbSet<UserActivity> UserActivities { get; set; } = default!;

        //Component related tables
        public DbSet<BaseComponent> Components { get; set; } = default!;
        public DbSet<BaseSubComponent> SubComponents { get; set; } = default!;
        public DbSet<Color> Colors { get; set; } = default!;
        public DbSet<ComponentVariant> ComponentVariants { get; set; } = default!;
        public DbSet<ColorVariant> ColorVariants { get; set; } = default!;
        public DbSet<ComponentCompatibility> ComponentCompatibilities { get; set; } = default!;
        public DbSet<ComponentPart> ComponentParts { get; set; } = default!;
        public DbSet<ComponentPrice> ComponentPrices { get; set; } = default!;
        public DbSet<ComponentReview> ComponentReviews { get; set; } = default!;
        public DbSet<SubComponentPart> SubComponentParts { get; set; } = default!;

        //Build related tables
        public DbSet<Build> Builds { get; set; } = default!;
        public DbSet<BuildComponent> BuildComponents { get; set; } = default!;
        public DbSet<BuildInteraction> BuildInteractions { get; set; } = default!;
        public DbSet<Tag> Tags { get; set; } = default!;
        public DbSet<BuildTag> BuildTags { get; set; } = default!;

        //Declare enums and cascade delete behaviour
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            //Set the default precision for all decimal values in the database
            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
            {
                foreach (var property in entityType.GetProperties())
                {
                    if (property.ClrType == typeof(decimal) || property.ClrType == typeof(decimal?))
                    {
                        property.SetPrecision(18);
                        property.SetScale(6);
                    }
                }
            }

            //Register the db full-text search function
            modelBuilder
                .HasDbFunction(() => FullTextDbFunction.Contains(default!, default!))
                .HasName("CONTAINS");

            //====================================== USER ======================================//

            //Configure enums as strings
            modelBuilder
                .Entity<User>()
                .Property(u => u.UserRole)
                .HasConversion<string>();

            modelBuilder
                .Entity<User>()
                .Property(u => u.Theme)
                .HasConversion<string>();

            modelBuilder
                .Entity<User>()
                .Property(u => u.Language)
                .HasConversion<string>();

            modelBuilder
                .Entity<User>()
                .Property(u => u.ProfileAccessibility)
                .HasConversion<string>();

            //Unique index on email
            modelBuilder
                .Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            //Unique index on login
            modelBuilder
                .Entity<User>()
                .HasIndex(u => u.Login)
                .IsUnique();

            //Register address as a ValueObject
            modelBuilder.Entity<User>()
                .OwnsOne(u => u.Address);

            //====================================== USER FOLLOW ======================================//

            //Register relationships, disable cascade delete, must be handled in API calls
            modelBuilder.Entity<UserFollow>()
                .HasOne(f => f.Follower)
                .WithMany(u => u.Followed)
                .HasForeignKey(f => f.FollowerId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserFollow>()
                .HasOne(f => f.Followed)
                .WithMany(u => u.Followers)
                .HasForeignKey(f => f.FollowedId)
                .OnDelete(DeleteBehavior.NoAction);

            //====================================== USER TOKEN ======================================//

            //Configure TokenType enum as string
            modelBuilder
                .Entity<UserToken>()
                .Property(u => u.TokenType)
                .HasConversion<string>();

            //Register relationship with user
            modelBuilder.Entity<UserToken>()
                .HasOne(t => t.User)
                .WithMany(u => u.UserTokens)
                .HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== USER PREFERENCE ======================================//

            //Register relationship with user
            modelBuilder.Entity<UserPreference>()
                .HasOne(p => p.User)
                .WithMany(u => u.UserPreferences)
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== USER COMMENT ======================================//

            //Configure CommentTargetType enum as string
            modelBuilder
                .Entity<UserComment>()
                .Property(u => u.CommentTargetType)
                .HasConversion<string>();

            //Register relationships, restrict cascade delete as comments should remain on the website until removed manually
            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.User)
                .WithMany(u => u.UserComments)
                .HasForeignKey(c => c.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.ForumPost)
                .WithMany(u => u.Comments)
                .HasForeignKey(c => c.ForumPostId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.Component)
                .WithMany(u => u.Comments)
                .HasForeignKey(c => c.ComponentId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.ComponentReview)
                .WithMany(u => u.Comments)
                .HasForeignKey(c => c.ComponentReviewId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.Build)
                .WithMany(u => u.Comments)
                .HasForeignKey(c => c.BuildId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserComment>()
                .HasOne(c => c.ParentComment)
                .WithMany(pc => pc.ChildComments)
                .HasForeignKey(c => c.ParentCommentId)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== FORUM POST ======================================//

            //Register relationship with user
            modelBuilder.Entity<ForumPost>()
                .HasOne(p => p.Creator)
                .WithMany(u => u.ForumPosts)
                .HasForeignKey(p => p.CreatorId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== MESSAGE ======================================//

            //Configure MessageType enum as string
            modelBuilder
                .Entity<Message>()
                .Property(u => u.MessageType)
                .HasConversion<string>();

            //Register relationships, deleting messages should be handled in API calls
            modelBuilder.Entity<Message>()
                .HasOne(m => m.Sender)
                .WithMany(u => u.SentMessages)
                .HasForeignKey(m => m.SenderId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.Receiver)
                .WithMany(u => u.ReceivedMessages)
                .HasForeignKey(m => m.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.ParentMessage)
                .WithMany(pm => pm.ChildMessages)
                .HasForeignKey(m => m.ParentMessageId)
                .OnDelete(DeleteBehavior.NoAction);

            //====================================== NOTFICATION ======================================//

            //Configure NotificationType enum as string
            modelBuilder
                .Entity<Notification>()
                .Property(u => u.NotificationType)
                .HasConversion<string>();

            //Register relationship with user
            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== USER ACTIVITY ======================================//

            //Register relationship with user
            modelBuilder.Entity<UserActivity>()
                .HasOne(a => a.User)
                .WithMany(u => u.UserActivities)
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            //====================================== COMPONENT ======================================//

            //Configure ComponentType as string
            modelBuilder
                .Entity<BaseComponent>()
                .Property(c => c.Type)
                .HasConversion<string>();

            //Register a Table-Per-Table polymorphic relationship to subclasses
            modelBuilder.Entity<BaseComponent>().ToTable("Components");
            modelBuilder.Entity<CaseFanComponent>().ToTable("CaseFanComponents");
            modelBuilder.Entity<GPUComponent>().ToTable("GPUComponents");
            modelBuilder.Entity<CPUComponent>().ToTable("CPUComponents");
            modelBuilder.Entity<MemoryComponent>().ToTable("MemoryComponents");
            modelBuilder.Entity<MotherboardComponent>().ToTable("MotherboardComponents");
            modelBuilder.Entity<MonitorComponent>().ToTable("MonitorComponents");
            modelBuilder.Entity<CaseComponent>().ToTable("CaseComponents");
            modelBuilder.Entity<PowerSupplyComponent>().ToTable("PowerSupplyComponents");
            modelBuilder.Entity<StorageComponent>().ToTable("StorageComponents");
            modelBuilder.Entity<CoolerComponent>().ToTable("CoolerComponents");

            //Register dimension as a ValueObject
            modelBuilder.Entity<CaseComponent>()
                .OwnsOne(c => c.Dimensions);

            //====================================== COMPONENT VARIANT ======================================//

            //Register relationships with Component
            modelBuilder.Entity<ComponentVariant>()
                .HasOne(v => v.Component)
                .WithMany(u => u.Colors)
                .HasForeignKey(v => v.ComponentId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== COLOR VARIANT ======================================//

            //Register relationships, disable cascade delete for colors, must be handled in API calls
            modelBuilder.Entity<ColorVariant>()
                .HasOne(v => v.ComponentVariant)
                .WithMany(u => u.ColorVariants)
                .HasForeignKey(v => v.ComponentVariantId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ColorVariant>()
                .HasOne(v => v.Color)
                .WithMany(u => u.ColorVariants)
                .HasForeignKey(v => v.ColorCode)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== COMPONENT COMPATIBILITY ======================================//

            //Register relationships, disable cascade delete, must be handled in API calls
            modelBuilder.Entity<ComponentCompatibility>()
                .HasOne(c => c.Component)
                .WithMany(u => u.CompatibleComponents)
                .HasForeignKey(c => c.ComponentId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ComponentCompatibility>()
                .HasOne(c => c.CompatibleComponent)
                .WithMany(u => u.CompatibleToComponents)
                .HasForeignKey(c => c.CompatibleComponentId)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== COMPONENT PRICE ======================================//

            //Register relationship with component
            modelBuilder.Entity<ComponentPrice>()
                .HasOne(p => p.Component)
                .WithMany(u => u.Prices)
                .HasForeignKey(p => p.ComponentId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== COMPONENT REVIEW ======================================//

            //Register relationship with component
            modelBuilder.Entity<ComponentReview>()
                .HasOne(r => r.Component)
                .WithMany(u => u.Reviews)
                .HasForeignKey(r => r.ComponentId)
                .OnDelete(DeleteBehavior.Cascade);

            //====================================== COMPONENT PART ======================================//

            //Register relationships, disable cascade delete for subComponents, must be handled in API calls
            modelBuilder.Entity<ComponentPart>()
                .HasOne(p => p.Component)
                .WithMany(u => u.SubComponents)
                .HasForeignKey(p => p.ComponentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ComponentPart>()
                .HasOne(p => p.SubComponent)
                .WithMany(u => u.Components)
                .HasForeignKey(p => p.SubComponentId)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== SUBCOMPONENT ======================================//

            //Configure SubComponentType as string
            modelBuilder
                .Entity<BaseSubComponent>()
                .Property(c => c.Type)
                .HasConversion<string>();

            //Register a Table-Per-Table polymorphic relationship to subclasses
            modelBuilder.Entity<BaseSubComponent>().ToTable("SubComponents");
            modelBuilder.Entity<CoolerSocketSubComponent>().ToTable("CoolerSocketSubComponents");
            modelBuilder.Entity<IntegratedGraphicsSubComponent>().ToTable("IntegratedGraphicsSubComponents");
            modelBuilder.Entity<M2SlotSubComponent>().ToTable("M2SlotSubcomponents");
            modelBuilder.Entity<OnboardEthernetSubComponent>().ToTable("OnboardEthernetSubComponents");
            modelBuilder.Entity<PCIeSlotSubComponent>().ToTable("PCIeSlotSubComponents");
            modelBuilder.Entity<PortSubComponent>().ToTable("PortSubComponents");

            //Configure PortType as string
            modelBuilder
                .Entity<PortSubComponent>()
                .Property(c => c.PortType)
                .HasConversion<string>();

            //====================================== SUBCOMPONENT PART ======================================//

            //Register relationships, disable cascade delete for non-main subComponents, must be handled in API calls
            modelBuilder.Entity<SubComponentPart>()
                .HasOne(p => p.MainSubComponent)
                .WithMany(u => u.SubComponents)
                .HasForeignKey(p => p.MainSubComponentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<SubComponentPart>()
                .HasOne(p => p.SubComponent)
                .WithMany(u => u.MainSubComponents)
                .HasForeignKey(p => p.SubComponentId)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== BUILD ======================================//

            //Configure BuildStatus enum as string
            modelBuilder
                .Entity<Build>()
                .Property(u => u.Status)
                .HasConversion<string>();

            //Register relationship with user, restrict cascade delete and handle deletion separately
            modelBuilder.Entity<Build>()
                .HasOne(b => b.User)
                .WithMany(u => u.Builds)
                .HasForeignKey(b => b.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== BUILD COMPONENT ======================================//

            //Register relationships, disable cascade delete for components, should remain in database until the user deletes it
            modelBuilder.Entity<BuildComponent>()
                .HasOne(c => c.Build)
                .WithMany(u => u.Components)
                .HasForeignKey(c => c.BuildId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<BuildComponent>()
                .HasOne(c => c.Component)
                .WithMany(u => u.Builds)
                .HasForeignKey(c => c.ComponentId)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== BUILD INTERACTION ======================================//

            //Register relationships, disable cascade delete for builds, should remain in database until the user deletes it
            modelBuilder.Entity<BuildInteraction>()
                .HasOne(i => i.User)
                .WithMany(u => u.BuildInteractions)
                .HasForeignKey(i => i.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<BuildInteraction>()
                .HasOne(i => i.Build)
                .WithMany(u => u.Interactions)
                .HasForeignKey(i => i.BuildId)
                .OnDelete(DeleteBehavior.Restrict);

            //====================================== BUILD TAG ======================================//

            //Register relationships, disable cascade delete for builds, must be handled in API calls
            modelBuilder.Entity<BuildTag>()
                .HasOne(t => t.Tag)
                .WithMany(t => t.BuildTags)
                .HasForeignKey(t => t.TagId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<BuildTag>()
                .HasOne(t => t.Build)
                .WithMany(b => b.BuildTags)
                .HasForeignKey(t => t.BuildId)
                .OnDelete(DeleteBehavior.Restrict);

            //Register the lists which ignore the buildTag in the middle
            modelBuilder.Entity<Build>()
                .HasMany(b => b.Tags)
                .WithMany(t => t.Builds)
                .UsingEntity<Dictionary<string, object>>(
                    "BuildTag",
                    b => b.HasOne<Tag>().WithMany().HasForeignKey("TagId"),
                    b => b.HasOne<Build>().WithMany().HasForeignKey("BuildId")
                );

            //====================================== IMAGE ======================================//

            //Configure ImageTargetType enum as string
            modelBuilder
                .Entity<Image>()
                .Property(i => i.LocationType)
                .HasConversion<string>();

            //Register relationships, restrict cascade deletes, image deletes should be handled in the controllers
            modelBuilder.Entity<Image>()
                .HasOne(i => i.User)
                .WithMany(u => u.Images)
                .HasForeignKey(i => i.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Image>()
                .HasOne(i => i.ForumPost)
                .WithMany(u => u.Images)
                .HasForeignKey(i => i.ForumPostId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Image>()
                .HasOne(i => i.Component)
                .WithMany(u => u.Images)
                .HasForeignKey(i => i.ComponentId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Image>()
                .HasOne(i => i.SubComponent)
                .WithMany(u => u.Images)
                .HasForeignKey(i => i.SubComponentId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Image>()
                .HasOne(i => i.Build)
                .WithMany(u => u.Images)
                .HasForeignKey(i => i.BuildId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Image>()
                .HasOne(i => i.UserComment)
                .WithMany(pc => pc.Images)
                .HasForeignKey(i => i.UserCommentId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
