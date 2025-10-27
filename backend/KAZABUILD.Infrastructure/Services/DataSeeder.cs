using Bogus;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Entities.Builds;
using KAZABUILD.Domain.Entities.Components;
using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Entities.Components.SubComponents;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Domain.ValueObjects;
using KAZABUILD.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Service used to seed the database with fake data.
    /// </summary>
    /// <param name="context"></param>
    /// <param name="hasher"></param>
    /// <param name="aes"></param>
    public class DataSeeder(KAZABUILDDBContext context, IHashingService hasher, IEncryptionService aes) : IDataSeeder
    {
        //Services used for data seeding
        private readonly KAZABUILDDBContext _context = context;
        private readonly IHashingService _hasher = hasher;
        private readonly IEncryptionService _aes = aes;

        /// <summary>
        /// Function used to seed the database with fake data.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <typeparam name="T2"></typeparam>
        /// <param name="count"></param>
        /// <param name="ids1"></param>
        /// <param name="ids2"></param>
        /// <param name="ids3"></param>
        /// <param name="ids4"></param>
        /// <param name="ids5"></param>
        /// <param name="idsOptional"></param>
        /// <param name="password"></param>
        /// <returns></returns>
        public async Task<List<T2>> SeedAsync<T, T2>(int count = 100, List<Guid>? ids1 = null, List<Guid>? ids2 = null, List<Guid>? ids3 = null, List<Guid>? ids4 = null, List<Guid>? ids5 = null, List<string>? idsOptional = null, string? password = "password123!") where T : class
        {
            //Find the correct faker for this entity type
            var faker = await GetFakerForAsync<T>(ids1, ids2, ids3, ids4, ids5, idsOptional, password!);

            //Generate the entities using the faker
            var entities = faker.Generate(count);

            //List storing the return ids
            var savedIds = new List<T2>();

            _context.ChangeTracker.AutoDetectChangesEnabled = false;
            _context.ChangeTracker.QueryTrackingBehavior = QueryTrackingBehavior.NoTracking;

            //Add and save the entities to the database
            foreach (var entity in entities)
            {
                try
                {
                    //Try to add an entity
                    _context.Set<T>().Add(entity);

                    //Save changes to the database to see if it is possible
                    await _context.SaveChangesAsync();

                    //Add the ids to the return list
                    var id = entity.GetType().GetProperty("Id") != null ? (T2)entity.GetType().GetProperty("Id")!.GetValue(entity)! : (T2)entity.GetType().GetProperty("ColorCode")!.GetValue(entity)!;

                    //Throw an exception if no id found
                    if (id == null) throw new InvalidOperationException($"No ID property found for {typeof(T).Name}");

                    //Add the id to the return list
                    savedIds.Add(id);
                }
                catch
                {
                    //Clear failed state to add more entities
                    _context.ChangeTracker.Clear();
                }
            }

            _context.ChangeTracker.AutoDetectChangesEnabled = true;

            //Return the ids for the seeded table rows
            return savedIds;
        }

        /// <summary>
        /// Class for getting the correct faker factory
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        /// <exception cref="InvalidOperationException"></exception>
        private async Task<Faker<T>> GetFakerForAsync<T>(List<Guid>? ids1, List<Guid>? ids2, List<Guid>? ids3, List<Guid>? ids4, List<Guid>? ids5, List<string>? idsOptional, string password) where T : class
        {
            //Get the correct faker factory for the provided type
            if (typeof(T) == typeof(User))
            {
                List<UserRole> roles = [.. Enum.GetValues<UserRole>().Cast<UserRole>().Where(r => r != UserRole.SYSTEM && r != UserRole.OWNER)];

                return (Faker<T>)(object)GetUserFaker(roles, password);
            }
            else if (typeof(T) == typeof(Notification))
            {
                var userIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetNotificationFaker(userIds);
            }
            else if (typeof(T) == typeof(ForumPost))
            {
                var creatorIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetForumPostFaker(creatorIds);
            }
            else if (typeof(T) == typeof(Message))
            {
                List<MessageType> messageTypes = [.. Enum.GetValues<MessageType>().Cast<MessageType>()];

                var userIds = ids1 ?? [Guid.Empty];

                List<Guid> messageIds = await _context.Messages.Where(m => userIds.Contains(m.SenderId)).Select(m => m.Id).ToListAsync();

                return (Faker<T>)(object)GetMessageFaker(userIds, messageIds);
            }
            else if (typeof(T) == typeof(UserComment))
            {
                List<CommentTargetType> commentTargetTypes = [.. Enum.GetValues<CommentTargetType>().Cast<CommentTargetType>()];

                var userIds = ids1 ?? [Guid.Empty];
                var forumPostIds = ids2 ?? [Guid.Empty];
                var buildId = ids3 ?? [Guid.Empty];
                var componentId = ids4 ?? [Guid.Empty];
                var componentReviewId = ids5 ?? [Guid.Empty];

                //Get comments from the same generation batch
                var commentIds = await _context.UserComments.Where(c => userIds.Contains(c.UserId)).Select(c => c.Id).ToListAsync();

                return (Faker<T>)(object)GetUserCommentFaker(userIds, forumPostIds, buildId, componentId, componentReviewId, commentTargetTypes, commentIds);
            }
            else if (typeof(T) == typeof(UserFollow))
            {
                var userIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetUserFollowFaker(userIds);
            }
            else if (typeof(T) == typeof(UserPreference))
            {
                var userIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetUserPreferenceFaker(userIds);
            }
            else if (typeof(T) == typeof(BaseComponent))
            {
                return (Faker<T>)(object)GetBaseComponentFaker();
            }
            else if (typeof(T) == typeof(CaseComponent))
            {
                return (Faker<T>)(object)GetCaseComponentFaker();
            }
            else if (typeof(T) == typeof(CaseFanComponent))
            {
                return (Faker<T>)(object)GetCaseFanComponentFaker();
            }
            else if (typeof(T) == typeof(CoolerComponent))
            {
                return (Faker<T>)(object)GetCoolerComponentFaker();
            }
            else if (typeof(T) == typeof(CPUComponent))
            {
                return (Faker<T>)(object)GetCPUComponentFaker();
            }
            else if (typeof(T) == typeof(GPUComponent))
            {
                return (Faker<T>)(object)GetGPUComponentFaker();
            }
            else if (typeof(T) == typeof(MemoryComponent))
            {
                return (Faker<T>)(object)GetMemoryComponentFaker();
            }
            else if (typeof(T) == typeof(MonitorComponent))
            {
                return (Faker<T>)(object)GetMonitorComponentFaker();
            }
            else if (typeof(T) == typeof(MotherboardComponent))
            {
                return (Faker<T>)(object)GetMotherboardComponentFaker();
            }
            else if (typeof(T) == typeof(PowerSupplyComponent))
            {
                return (Faker<T>)(object)GetPowerSupplyComponentFaker();
            }
            else if (typeof(T) == typeof(StorageComponent))
            {
                return (Faker<T>)(object)GetStorageComponentFaker();
            }
            else if (typeof(T) == typeof(BaseSubComponent))
            {
                return (Faker<T>)(object)GetBaseSubComponentFaker();
            }
            else if (typeof(T) == typeof(CoolerSocketSubComponent))
            {
                return (Faker<T>)(object)GetCoolerSocketSubComponentFaker();
            }
            else if (typeof(T) == typeof(M2SlotSubComponent))
            {
                return (Faker<T>)(object)GetM2SlotSubComponentFaker();
            }
            else if (typeof(T) == typeof(IntegratedGraphicsSubComponent))
            {
                return (Faker<T>)(object)GetIntegratedGraphicsSubComponentFaker();
            }
            else if (typeof(T) == typeof(OnboardEthernetSubComponent))
            {
                return (Faker<T>)(object)GetOnboardEthernetSubComponentFaker();
            }
            else if (typeof(T) == typeof(PCIeSlotSubComponent))
            {
                return (Faker<T>)(object)GetPCIeSlotSubComponentFaker();
            }
            else if (typeof(T) == typeof(PortSubComponent))
            {
                return (Faker<T>)(object)GetPortSubComponentFaker();
            }
            else if (typeof(T) == typeof(Color))
            {
                return (Faker<T>)(object)GetColorFaker();
            }
            else if (typeof(T) == typeof(ComponentCompatibility))
            {
                var componentIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetComponentCompatibilityFaker(componentIds);
            }
            else if (typeof(T) == typeof(ComponentPart))
            {
                var componentIds = ids1 ?? [Guid.Empty];
                var subComponentIds = ids2 ?? [Guid.Empty];

                return (Faker<T>)(object)GetComponentPartFaker(componentIds, subComponentIds);
            }
            else if (typeof(T) == typeof(ComponentPrice))
            {
                var componentIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetComponentPriceFaker(componentIds);
            }
            else if (typeof(T) == typeof(ComponentReview))
            {
                var componentIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetComponentReviewFaker(componentIds);
            }
            else if (typeof(T) == typeof(ComponentVariant))
            {
                var componentIds = ids1 ?? [Guid.Empty];

                List<ComponentPrice> componentPrice = await _context.ComponentPrices.Where(p => componentIds.Contains(p.ComponentId)).OrderBy(p => p.Price).ToListAsync();
                return (Faker<T>)(object)GetComponentVariantFaker(componentIds, componentPrice);
            }
            else if (typeof(T) == typeof(ColorVariant))
            {
                var componentIds = ids1 ?? [Guid.Empty];
                var colorCodes = idsOptional ?? ["#FFFFFF"];

                return (Faker<T>)(object)GetColorVariantFaker(componentIds, colorCodes);
            }
            else if (typeof(T) == typeof(SubComponentPart))
            {
                var componentIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetSubComponentPartFaker(componentIds);
            }
            else if (typeof(T) == typeof(Build))
            {
                var userIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetBuildFaker(userIds);
            }
            else if (typeof(T) == typeof(Tag))
            {
                return (Faker<T>)(object)GetTagFaker();
            }
            else if (typeof(T) == typeof(BuildTag))
            {
                var buildIds = ids1 ?? [Guid.Empty];
                var tagIds = ids2 ?? [Guid.Empty];

                return (Faker<T>)(object)GetBuildTagFaker(buildIds, tagIds);
            }
            else if (typeof(T) == typeof(BuildComponent))
            {
                var buildIds = ids1 ?? [Guid.Empty];
                var componentIds = ids2 ?? [Guid.Empty];

                return (Faker<T>)(object)GetBuildComponentFaker(buildIds, componentIds);
            }
            else if (typeof(T) == typeof(BuildInteraction))
            {
                var buildIds = ids1 ?? [Guid.Empty];
                var userIds = ids2 ?? [Guid.Empty];

                return (Faker<T>)(object)GetBuildInteractionFaker(buildIds, userIds);
            }

            //Throw an exception if invalid class provided
            throw new InvalidOperationException($"No faker found for {typeof(T).Name}");
        }

        //Faker factories which create rules necessary to seed a specific model table
        private static readonly string[] genders = ["Male", "Female", "Non-binary", "Other"];
        private Faker<User> GetUserFaker(List<UserRole> roles, string password) => new Faker<User>("en")
            .RuleFor(u => u.Id, f => Guid.NewGuid())
            .RuleFor(u => u.Login, f =>
            {
                var username = f.Internet.UserName();
                username = username.PadRight(8, 'x');
                return username[..Math.Min(username.Length, 50)];
            })
            .RuleFor(u => u.Email, (f, u) => f.Internet.Email(u.Login))
            .RuleFor(u => u.PasswordHash, f => _hasher.Hash(password))
            .RuleFor(u => u.DisplayName, f =>
                {
                    var username = f.Internet.UserName();
                    username = username.PadRight(8, 'x');
                    return username[..Math.Min(username.Length, 50)];
                })
            .RuleFor(u => u.PhoneNumber, f => f.Random.Bool() ? f.Phone.PhoneNumber() : null)
            .RuleFor(u => u.Description, f => f.Random.Bool() ? $"<p>{f.Lorem.Paragraph()}</p>" : null)
            .RuleFor(u => u.Gender, f => f.PickRandom(genders))
            .RuleFor(u => u.UserRole, f => f.PickRandom(roles))
            .RuleFor(u => u.ImageUrl, f => "wwwroot/defaultuser.png")
            .RuleFor(u => u.Birth, f => f.Date.Past(60, DateTime.UtcNow.AddYears(-18)))
            .RuleFor(u => u.RegisteredAt, f => f.Date.Past(2))
            .RuleFor(u => u.Address, f => null)
            .RuleFor(u => u.BannedUntil, f => null)
            .RuleFor(u => u.ProfileAccessibility, f => f.PickRandom<ProfileAccessibility>())
            .RuleFor(u => u.Theme, f => f.PickRandom<Theme>())
            .RuleFor(u => u.Language, f => f.PickRandom<Language>())
            .RuleFor(u => u.Location, f => null)
            .RuleFor(u => u.ReceiveEmailNotifications, f => f.Random.Bool())
            .RuleFor(u => u.EnableDoubleFactorAuthentication, f => f.Random.Bool(0.1f))
            .RuleFor(u => u.GoogleId, f => null)
            .RuleFor(u => u.GoogleProfilePicture, f => null)
            .RuleFor(n => n.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(u => u.LastEditedAt, (f, u) => f.Date.Between(u.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(u => u.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<Notification> GetNotificationFaker(List<Guid> userIds) => new Faker<Notification>("en")
            .RuleFor(n => n.Id, f => Guid.NewGuid())
            .RuleFor(n => n.UserId, f => f.PickRandom(userIds))
            .RuleFor(n => n.NotificationType, f => f.PickRandom<NotificationType>())
            .RuleFor(n => n.Body, f => $"<p>{f.Lorem.Paragraphs(1)}</p>")
            .RuleFor(n => n.Title, f =>
            {
                var title = f.Lorem.Sentence(3);
                return title[..Math.Min(title.Length, 50)];
            })
            .RuleFor(n => n.LinkUrl, f => null)
            .RuleFor(n => n.SentAt, f => f.Date.Recent(30))
            .RuleFor(n => n.IsRead, f => f.Random.Bool(0.5f))
            .RuleFor(n => n.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(n => n.LastEditedAt, (f, n) => f.Date.Between(n.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(n => n.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private static readonly string[] topics = ["Troubleshoot", "Build Advice", "Show Off Your Build", "General Discussion"];
        private Faker<ForumPost> GetForumPostFaker(List<Guid> creatorIds) => new Faker<ForumPost>("en")
            .RuleFor(p => p.Id, f => Guid.NewGuid())
            .RuleFor(p => p.CreatorId, f => f.PickRandom(creatorIds))
            .RuleFor(p => p.Content, f => f.Lorem.Paragraph())
            .RuleFor(p => p.Title, f =>
            {
                var title = f.Lorem.Sentence(3);
                return title[..Math.Min(title.Length, 50)];
            })
            .RuleFor(p => p.Topic, f => f.PickRandom(topics))
            .RuleFor(p => p.PostedAt, f => f.Date.Recent(30))
            .RuleFor(n => n.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(p => p.LastEditedAt, (f, p) => f.Date.Between(p.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(p => p.Note, f => f.Random.Bool(0.2f) ? f.Lorem.Sentence() : null);

        private Faker<Message> GetMessageFaker(List<Guid> userIds, List<Guid> messageIds) => new Faker<Message>("en")
            .RuleFor(m => m.Id, f => Guid.NewGuid())
            .RuleFor(m => m.SenderId, f => f.PickRandom(userIds))
            .RuleFor(m => m.ReceiverId, f => f.PickRandom(userIds))
            .RuleFor(m => m.Title, f =>
            {
                var title = f.Lorem.Sentence(3);
                return title[..Math.Min(title.Length, 50)];
            })
            .RuleFor(m => m.SentAt, f => f.Date.Recent(30))
            .RuleFor(m => m.IsRead, f => f.Random.Bool(0.5f))
            .RuleFor(m => m.ParentMessageId, f =>
            {
                if (messageIds.Count == 0 || !f.Random.Bool(0.8f))
                    return null;

                return f.PickRandom(messageIds);
            })
            .RuleFor(m => m.MessageType, f => f.PickRandom<MessageType>())
            .RuleFor(m => m.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(m => m.LastEditedAt, (f, m) => f.Date.Between(m.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(m => m.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .FinishWith((f, m) =>
            {
                var plainText = f.Lorem.Paragraphs(1);

                var (cipher, iv) = _aes.Encrypt(plainText);
                m.CipherText = cipher;
                m.IV = iv;
            });

        private Faker<UserComment> GetUserCommentFaker(List<Guid> userIds, List<Guid> forumPostIds, List<Guid> buildIds, List<Guid> componentIds, List<Guid> componentReviewIds, List<CommentTargetType> commentTargetTypes, List<Guid> commentIds) => new Faker<UserComment>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.UserId, f => f.PickRandom(userIds))
            .RuleFor(c => c.Content, f => f.Lorem.Paragraphs(1))
            .RuleFor(c => c.PostedAt, f => f.Date.Recent(30))
            .RuleFor(c => c.ParentCommentId, f =>
            {
                if (commentIds.Count == 0 || !f.Random.Bool(0.8f))
                    return null;

                return f.PickRandom(commentIds);
            })
            .RuleFor(c => c.CommentTargetType, f => f.PickRandom(commentTargetTypes))
            .RuleFor(c => c.ForumPostId, (f, c) => c.CommentTargetType == CommentTargetType.FORUM ? f.PickRandom(forumPostIds) : null)
            .RuleFor(c => c.BuildId, (f, c) => c.CommentTargetType == CommentTargetType.BUILD ? f.PickRandom(buildIds) : null)
            .RuleFor(c => c.ComponentId, (f, c) => c.CommentTargetType == CommentTargetType.COMPONENT ? f.PickRandom(componentIds) : null)
            .RuleFor(c => c.ComponentReviewId, (f, c) => c.CommentTargetType == CommentTargetType.REVIEW ? f.PickRandom(componentReviewIds) : null)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<UserFollow> GetUserFollowFaker(List<Guid> userIds) => new Faker<UserFollow>("en")
            .RuleFor(f => f.Id, f => Guid.NewGuid())
            .RuleFor(f => f.FollowerId, f => f.PickRandom(userIds))
            .RuleFor(f => f.FollowedId, f => f.PickRandom(userIds))
            .RuleFor(f => f.FollowedAt, f => f.Date.Recent(30))
            .RuleFor(f => f.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(f => f.LastEditedAt, (f, fo) => f.Date.Between(fo.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(f => f.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<UserPreference> GetUserPreferenceFaker(List<Guid> userIds) => new Faker<UserPreference>("en")
            .RuleFor(p => p.Id, f => Guid.NewGuid())
            .RuleFor(p => p.UserId, f => f.PickRandom(userIds))
            .RuleFor(p => p.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(p => p.LastEditedAt, (f, p) => f.Date.Between(p.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(p => p.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<BaseComponent> GetBaseComponentFaker() => new Faker<BaseComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Name, f => $"{f.Commerce.ProductName()} {f.Random.AlphaNumeric(3).ToUpper()}")
            .RuleFor(c => c.Manufacturer, f =>
            {
                var nmanufacturer = f.Company.CompanyName();
                return nmanufacturer[..Math.Min(nmanufacturer.Length, 50)];
            })
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, f => f.PickRandom<ComponentType>())
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private static readonly string[] caseManufacturers = ["Corsair", "NZXT", "Cooler Master", "Fractal Design", "Lian Li", "Thermaltake", "Be Quiet!"];
        private static readonly string[] caseFormFactors = ["ATX Mid Tower", "ATX Full Tower", "Mini ITX Tower", "Micro ATX Tower", "Cube Case", "Open Frame"];
        private static readonly string[] transparentSidePanels = ["Tempered Glass", "Acrylic"];
        private static readonly string[] sidePanels = ["Tempered Glass", "Acrylic", "Solid Steel", "Mesh", "Plastic"];
        private static readonly string[] caseSeries = ["P", "H", "NZXT", "MasterBox", "TUF", "Define", "Lancool", "O11", "Qube", "Crystal"];
        private static readonly string[] caseSizeTags = ["Mini", "Mid", "Full"];
        private static readonly string[] caseSuffixes = ["TG", "ARGB", "Elite", "Pro", "RGB", "Silent", "Mesh", "Compact"];
        private Faker<CaseComponent> GetCaseComponentFaker() => new Faker<CaseComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(caseManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.CASE)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.FormFactor, f => f.PickRandom(caseFormFactors))
            .RuleFor(c => c.PowerSupplyShrouded, f => f.Random.Bool())
            .RuleFor(c => c.PowerSupplyAmount, f => f.Random.Bool(0.5f) ? f.Random.Decimal(300, 1000) : null)
            .RuleFor(c => c.HasTransparentSidePanel, f => f.Random.Bool(0.6f))
            .RuleFor(c => c.SidePanelType, (f, c) => c.HasTransparentSidePanel ? f.PickRandom(transparentSidePanels) : f.PickRandom(sidePanels))
            .RuleFor(c => c.MaxVideoCardLength, f => f.Random.Decimal(200, 450))
            .RuleFor(c => c.MaxCPUCoolerHeight, f => f.Random.Decimal(120, 190))
            .RuleFor(c => c.Internal35BayAmount, f => f.Random.Int(0, 6))
            .RuleFor(c => c.Internal25BayAmount, f => f.Random.Int(0, 6))
            .RuleFor(c => c.External35BayAmount, f => f.Random.Int(0, 2))
            .RuleFor(c => c.External525BayAmount, f => f.Random.Int(0, 2))
            .RuleFor(c => c.ExpansionSlotAmount, f => f.Random.Int(4, 10))
            .RuleFor(c => c.Dimensions, f => new Dimension
            {
                Height = f.Random.Decimal(350, 600),
                Width = f.Random.Decimal(180, 400),
                Depth = f.Random.Decimal(350, 550)
            })
            .RuleFor(c => c.Weight, f => f.Random.Decimal(4, 18))
            .RuleFor(c => c.SupportsRearConnectingMotherboard, f => f.Random.Bool(0.2f))
            .RuleFor(c => c.Name, (f, c) =>
            {
                var series = f.PickRandom(caseSeries);
                var sizeTag = f.PickRandom(caseSizeTags);
                var suffix = f.PickRandom(caseSuffixes);
                var number = f.Random.Int(100, 800);

                return $"{c.Manufacturer} {series} {number} {suffix}";
            });


        private static readonly string[] ledTypes = ["None", "RGB", "ARGB", "White LED", "Blue LED"];
        private static readonly string[] connectorTypes = ["3-pin", "4-pin", "Proprietary", "USB"];
        private static readonly string[] controllerTypes = ["None", "Motherboard", "External Hub", "Remote"];
        private static readonly string[] flowDirections = ["Standard", "Reverse"];
        private static readonly string[] caseFanManufacturers = ["Noctua", "Corsair", "be quiet!", "Cooler Master", "Arctic", "Thermaltake", "NZXT", "Fractal Design"];
        private static readonly string[] caseFanSeries = ["SilentWings", "AF", "LL", "ML", "Vortex", "T30", "Prisma", "Uni Fan"];
        private Faker<CaseFanComponent> GetCaseFanComponentFaker() => new Faker<CaseFanComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(caseFanManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.CASE_FAN)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.Size, f => f.Random.Decimal(80, 200))
            .RuleFor(c => c.Quantity, f => f.Random.Int(1, 5))
            .RuleFor(c => c.MinAirflow, f => f.Random.Decimal(5m, 15m))
            .RuleFor(c => c.MaxAirflow, (f, c) => f.Random.Bool(0.8f) ? f.Random.Decimal(c.MinAirflow, 25m) : null)
            .RuleFor(c => c.MinNoiseLevel, f => f.Random.Decimal(10m, 25m))
            .RuleFor(c => c.MaxNoiseLevel, (f, c) => f.Random.Bool(0.8f) ? f.Random.Decimal(c.MinNoiseLevel, 40m) : null)
            .RuleFor(c => c.PulseWidthModulation, f => f.Random.Bool(0.7f))
            .RuleFor(c => c.LEDType, f => f.PickRandom(ledTypes))
            .RuleFor(c => c.ConnectorType, f => f.PickRandom(connectorTypes))
            .RuleFor(c => c.ControllerType, f => f.PickRandom(controllerTypes))
            .RuleFor(c => c.StaticPressureAmount, f => f.Random.Decimal(0.5m, 5.0m))
            .RuleFor(c => c.FlowDirection, f => f.PickRandom(flowDirections))
            .RuleFor(c => c.Name, (f, c) =>
            {
                var series = f.PickRandom(caseFanSeries);
                var rpmLabel = $"{(int)(f.Random.Decimal(800, 2500) / 100) * 100}RPM";
                var ledSuffix = c.LEDType != null && c.LEDType != "None" ? $"{c.LEDType}" : "";
                var pwmTag = c.PulseWidthModulation ? "PWM" : "";

                return $"{c.Manufacturer} {series} {c.Size}mm {pwmTag} {ledSuffix}".Trim();
            });

        private static readonly string[] coolerManufacturers = ["Noctua", "Corsair", "Cooler Master", "NZXT", "Arctic", "DeepCool", "Thermaltake", "be quiet!"];
        private static readonly decimal[] radiatorSizes = [120m, 240m, 280m, 360m, 420m];
        private static readonly string[] waterCoolerSeries = ["Kraken", "Hydro", "Liquid Freezer", "Neptune", "ML", "CoreLiquid"];
        private static readonly string[] fanCoolerSeries = ["Hyper", "Dark Rock", "NH", "Assassin", "TUF Tower"];
        private Faker<CoolerComponent> GetCoolerComponentFaker() => new Faker<CoolerComponent>("en")
            .RuleFor(c => c.Id, _ => Guid.NewGuid())
            .RuleFor(c => c.IsWaterCooled, f => f.Random.Bool(0.4f))
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(coolerManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.COOLER)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.MinFanRotationSpeed, f => f.Random.Bool(0.9f) ? f.Random.Decimal(400, 800) : null)
            .RuleFor(c => c.MaxFanRotationSpeed, (f, c) => (f.Random.Bool(0.8f) && c.MinFanRotationSpeed != null) ? f.Random.Decimal(c.MinFanRotationSpeed ?? 800, 2500) : null)
            .RuleFor(c => c.MinNoiseLevel, f => f.Random.Bool(0.9f) ? f.Random.Decimal(10, 25) : null)
            .RuleFor(c => c.MaxNoiseLevel, (f, c) => (f.Random.Bool(0.8f) && c.MinNoiseLevel != null) ? f.Random.Decimal(c.MinNoiseLevel ?? 15, 40) : null)
            .RuleFor(c => c.Height, f => f.Random.Decimal(50, 180))
            .RuleFor(c => c.RadiatorSize, (f, c) => c.IsWaterCooled ? f.PickRandom(radiatorSizes) : null)
            .RuleFor(c => c.CanOperateFanless, f => f.Random.Bool(0.2f))
            .RuleFor(c => c.FanSize, (f, c) => c.IsWaterCooled ? f.Random.Decimal(120, 140) : f.Random.Decimal(80, 140))
            .RuleFor(c => c.FanQuantity, (f, c) => c.IsWaterCooled ? f.Random.Int(1, 3) : f.Random.Int(1, 2))
            .RuleFor(c => c.Name, (f, c) =>
            {
                if (c.IsWaterCooled)
                {
                    var series = f.PickRandom(waterCoolerSeries);
                    var radiatorLabel = $"{c.RadiatorSize?.ToString("0")}mm";
                    return $"{c.Manufacturer} {series} {radiatorLabel}";
                }
                else
                {
                    var series = f.PickRandom(fanCoolerSeries);
                    var number = f.Random.Int(2, 15);
                    var fanSize = $"{c.FanSize?.ToString("0")}mm";
                    return $"{c.Manufacturer} {series} {number} {fanSize}";
                }
            });

        private static readonly string[] cpuManufacturers = ["Intel", "AMD"];
        private static readonly string[] cpuIntelSeries = ["Core i3", "Core i5", "Core i7", "Core i9", "Xeon"];
        private static readonly string[] cpuIntelMicroarchitectures = ["Alder Lake", "Raptor Lake", "Meteor Lake", "Arrow Lake", "Sapphire Rapids"];
        private static readonly string[] cpuIntelCoreFamilies = ["Raptor Cove", "Golden Cove", "Gracemont"];
        private static readonly string[] cpuIntelSocketTypes = ["LGA 1700", "LGA 1851", "LGA 4677"];
        private static readonly string[] cpuIntelLithographies = ["High-NA EUV", "Intel 3", "Intel 4"];
        private static readonly string[] cpuAMDSeries = ["Ryzen 3", "Ryzen 5", "Ryzen 7", "Ryzen 9", "Threadripper"];
        private static readonly string[] cpuAMDMicroarchitectures = ["Zen 2", "Zen 3", "Zen 4", "Zen 5"];
        private static readonly string[] cpuAMDCoreFamilies = ["Granite Ridge", "Raphael", "Matisse"];
        private static readonly string[] cpuAMDSocketTypes = ["AM4", "AM5", "sTRX4"];
        private static readonly string[] cpuAMDLithographies = ["TSMC 7nm", "TSMC 5nm"];
        private static readonly string[] memoryTypes = ["DDR4", "DDR5"];
        private static readonly string[] packagingTypes = ["Box", "Tray/OEM"];
        private static readonly string[] cpuSuffixes = ["", "K", "KF", "X", "XT", "F", "G"];
        private static readonly string[] cpuExtras = ["", "X", "XT", "X3D"];
        private Faker<CPUComponent> GetCPUComponentFaker() => new Faker<CPUComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(cpuManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.CPU)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.Series, (f, c) => c.Manufacturer == "Intel" ? f.PickRandom(cpuIntelSeries) : f.PickRandom(cpuAMDSeries))
            .RuleFor(c => c.Microarchitecture, (f, c) => c.Manufacturer == "Intel" ? f.PickRandom(cpuIntelMicroarchitectures) : f.PickRandom(cpuAMDMicroarchitectures))
            .RuleFor(c => c.CoreFamily, (f, c) => c.Manufacturer == "Intel" ? f.PickRandom(cpuIntelCoreFamilies) : f.PickRandom(cpuAMDCoreFamilies))
            .RuleFor(c => c.SocketType, (f, c) => c.Manufacturer == "Intel" ? f.PickRandom(cpuIntelSocketTypes) : f.PickRandom(cpuAMDSocketTypes))
            .RuleFor(c => c.CoreTotal, f => f.Random.Int(2, 256))
            .RuleFor(c => c.PerformanceAmount, (f, c) => c.CoreTotal > 8 && f.Random.Bool(0.5f) ? f.Random.Int(4, c.CoreTotal - 2) : null)
            .RuleFor(c => c.EfficiencyAmount, (f, c) => c.PerformanceAmount.HasValue ? c.CoreTotal - c.PerformanceAmount.Value : null)
            .RuleFor(c => c.ThreadsAmount, (f, c) => c.SupportsSimultaneousMultithreading ? c.CoreTotal * 2 : c.CoreTotal)
            .RuleFor(c => c.BasePerformanceSpeed, f => f.Random.Decimal(2500, 4000))
            .RuleFor(c => c.BoostPerformanceSpeed, (f, c) => c.BasePerformanceSpeed + f.Random.Decimal(300, 1200))
            .RuleFor(c => c.BaseEfficiencySpeed, (f, c) => c.EfficiencyAmount.HasValue ? f.Random.Decimal(1500, 3000) : null)
            .RuleFor(c => c.BoostEfficiencySpeed, (f, c) => c.BaseEfficiencySpeed.HasValue ? c.BaseEfficiencySpeed + f.Random.Decimal(200, 800) : null)
            .RuleFor(c => c.L1, f => f.Random.Decimal(128, 1024))
            .RuleFor(c => c.L2, f => f.Random.Decimal(512, 5120))
            .RuleFor(c => c.L3, f => f.Random.Decimal(4, 64))
            .RuleFor(c => c.L4, f => f.Random.Decimal(0, 512))
            .RuleFor(c => c.IncludesCooler, f => f.Random.Bool(0.6f))
            .RuleFor(c => c.SupportsSimultaneousMultithreading, f => f.Random.Bool(0.9f))
            .RuleFor(c => c.SupportsECC, f => f.Random.Bool(0.3f))
            .RuleFor(c => c.Lithography, (f, c) => c.Manufacturer == "Intel" ? f.PickRandom(cpuIntelLithographies) : f.PickRandom(cpuAMDLithographies))
            .RuleFor(c => c.MemoryType, f => f.PickRandom(memoryTypes))
            .RuleFor(c => c.PackagingType, f => f.PickRandom(packagingTypes))
            .RuleFor(c => c.ThermalDesignPower, f => f.Random.Decimal(35, 350))
            .RuleFor(c => c.Name, (f, c) =>
            {
                var series = c.Series;
                var coreCount = $"{c.CoreTotal}-Core";
                var suffix = f.PickRandom(cpuSuffixes);
                var gen = f.Random.Int(9, 15);

                if (c.Manufacturer.Contains("Intel", StringComparison.OrdinalIgnoreCase))
                {
                    return $"{c.Manufacturer} {series}-{gen}{f.Random.Int(100, 999)}{suffix}";
                }
                else if (c.Manufacturer.Contains("AMD", StringComparison.OrdinalIgnoreCase))
                {
                    var model = f.PickRandom(cpuAMDSeries);
                    var number = f.Random.Int(5000, 9000);
                    var extra = f.PickRandom(cpuExtras);
                    return $"{c.Manufacturer} {model} {number}{extra}";
                }
                else
                {
                    return $"{c.Manufacturer} {series} {coreCount}";
                }
            });

        private static readonly string[] gpuNameAppendixes = ["RTX", "RX", "ARC", "XEON"];
        private static readonly string[] gpuManufacturers = ["NVIDIA", "AMD", "Intel", "ASUS", "MSI", "Gigabyte", "Zotac"];
        private static readonly string[] videoMemoryTypes = ["GDDR5", "GDDR6", "GDDR6X", "HBM2", "HBM3"];
        private static readonly int[] memoryBusWidths = [64, 128, 192, 256, 320, 384, 512];
        private static readonly string[] frameSyncTechnologies = ["G-SYNC", "FreeSync", "Adaptive Sync", "None"];
        private static readonly string[] coolingTypes = ["1 Fan", "2 Fans", "3 Fans", "Blower", "Water Cooled"];
        private static readonly string[] gpuSuffixes = ["", "OC", "Gaming", "Ventus", "Eagle", "TUF", "STRIX", "SUPRIM", "AERO", "Phantom"];
        private Faker<GPUComponent> GetGPUComponentFaker() => new Faker<GPUComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(gpuManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.GPU)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.Chipset, (f, c) => $"{c.Manufacturer} {f.PickRandom(gpuNameAppendixes)} {f.Random.Int(250, 5090)}")
            .RuleFor(c => c.VideoMemoryAmount, f => f.Random.Decimal(512, 65536))
            .RuleFor(c => c.VideoMemoryType, f => f.PickRandom(videoMemoryTypes))
            .RuleFor(c => c.CoreBaseClockSpeed, f => f.Random.Decimal(800, 3000))
            .RuleFor(c => c.CoreBoostClockSpeed, (f, c) => c.CoreBaseClockSpeed + f.Random.Decimal(100, 600))
            .RuleFor(c => c.CoreCount, f => f.Random.Int(512, 18432))
            .RuleFor(c => c.EffectiveMemoryClockSpeed, f => f.Random.Decimal(5000, 24000))
            .RuleFor(c => c.MemoryBusWidth, f => f.PickRandom(memoryBusWidths))
            .RuleFor(c => c.FrameSync, f => f.PickRandom(frameSyncTechnologies))
            .RuleFor(c => c.Length, f => f.Random.Decimal(180, 400))
            .RuleFor(c => c.ThermalDesignPower, f => f.Random.Decimal(75, 600))
            .RuleFor(c => c.CaseExpansionSlotWidth, f => f.Random.Int(2, 4))
            .RuleFor(c => c.TotalSlotAmount, (f, c) => Math.Max(c.CaseExpansionSlotWidth, f.Random.Int(2, 4)))
            .RuleFor(c => c.CoolingType, f => f.PickRandom(coolingTypes))
            .RuleFor(c => c.Name, (f, c) =>
            {
                var chipset = c.Chipset;
                var suffix = f.PickRandom(gpuSuffixes);
                var vram = $"{(int)(c.VideoMemoryAmount / 1024)}GB";

                return $"{c.Manufacturer} {chipset} {suffix} {vram}";
            });

        private static readonly string[] memoryModelSeries = ["Vengeance", "Trident Z", "Ripjaws", "Dominators", "Ballistix", "HyperX Fury", "T-Force Delta"];
        private static readonly string[] memoryManufacturers = ["Corsair", "G.Skill", "Kingston", "Crucial", "ADATA", "TeamGroup", "Patriot"];
        private static readonly string[] ramTypes = ["DDR3", "DDR4", "DDR5", "LPDDR5"];
        private static readonly string[] memoryFormFactors = ["DIMM", "SO-DIMM"];
        private static readonly string[] eccs = ["Non-ECC", "ECC"];
        private static readonly string[] registeredTypes = ["Unbuffered", "Registered", "Load Reduced"];
        private Faker<MemoryComponent> GetMemoryComponentFaker() => new Faker<MemoryComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(memoryManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.MEMORY)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.Speed, (f, c) => f.Random.Decimal(1333, 8533))
            .RuleFor(c => c.RAMType, f => f.PickRandom(ramTypes))
            .RuleFor(c => c.FormFactor, f => f.PickRandom(memoryFormFactors))
            .RuleFor(c => c.CASLatency, f => f.Random.Decimal(10, 40))
            .RuleFor(c => c.Timings, f => $"{f.Random.Int(14, 36)}-{f.Random.Int(14, 36)}-{f.Random.Int(14, 46)}-{f.Random.Int(30, 90)}")
            .RuleFor(c => c.ModuleQuantity, f => f.Random.Int(1, 4))
            .RuleFor(c => c.ModuleCapacity, f => f.Random.Decimal(1024, 32768))
            .RuleFor(c => c.Capacity, (f, c) => c.ModuleCapacity * c.ModuleQuantity)
            .RuleFor(c => c.ECC, f => f.PickRandom(eccs))
            .RuleFor(c => c.RegisteredType, f => f.PickRandom(registeredTypes))
            .RuleFor(c => c.HaveHeatSpreader, f => f.Random.Bool(0.75f))
            .RuleFor(c => c.HaveRGB, (f, c) => c.HaveHeatSpreader && f.Random.Bool(0.4f))
            .RuleFor(c => c.Height, (f, c) => f.Random.Bool(0.9f) ? (c.FormFactor == "DIMM" ? f.Random.Decimal(30, 60) : f.Random.Decimal(20, 35)) : null)
            .RuleFor(c => c.Voltage, f => f.Random.Bool(0.9f) ? f.Random.Decimal(0.9m, 1.65m) : null)
            .RuleFor(c => c.Name, (f, c) =>
            {
                var speed = $"{c.Speed}MHz";
                var capacity = $"{(int)(c.Capacity / 1024)}GB";
                var type = c.RAMType;
                var rgb = c.HaveRGB ? "RGB" : "";
                var series = f.PickRandom(memoryModelSeries);

                var modulePair = $"({c.ModuleQuantity}x{(int)(c.ModuleCapacity / 1024)}GB)";
                return $"{c.Manufacturer} {series} {rgb} {capacity} {modulePair} {type} {speed}".Trim();
            });

        private static readonly string[] monitorManufacturers = ["Samsung", "LG", "ASUS", "Acer", "Dell", "BenQ", "MSI", "Gigabyte", "Philips", "ViewSonic", "HP", "Lenovo"];
        private static readonly string[] panelTypes = ["IPS", "VA", "TN", "OLED", "Mini-LED", "QNED"];
        private static readonly string[] aspectRatios = ["16:9", "21:9", "32:9", "16:10", "3:2"];
        private static readonly int[] aspectRatio16_9 = [1280, 1920, 2560, 3440, 3840, 5120, 7680];
        private static readonly int[] aspectRatio21_9 = [2560, 3440, 5120];
        private static readonly int[] aspectRatio32_9 = [3840, 5120, 7680];
        private static readonly int[] aspectRatio16_10 = [1920, 2560, 3840];
        private static readonly int[] aspectRatio3_2 = [2160, 3000, 3240];
        private static readonly int[] aspectRatioOther = [1280, 1920, 2560, 3840];
        private static readonly decimal[] refreshRates = [60m, 75m, 120m, 144m, 165m, 240m, 360m];
        private static readonly string[] adaptiveSyncTypes = ["FreeSync", "G-SYNC", "Adaptive-Sync", "None"];
        private static readonly string[] hdrTypes = ["None", "HDR10", "HDR400", "HDR600", "HDR1000", "Dolby Vision"];
        private static readonly string[] monitorModelSeries = ["ProView", "UltraSharp", "Odyssey", "Predator", "Nitro", "Legion", "ROG Strix", "Momentum"];
        private Faker<MonitorComponent> GetMonitorComponentFaker() => new Faker<MonitorComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(monitorManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.MONITOR)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.ScreenSize, f => f.Random.Decimal(13, 65))
            .RuleFor(c => c.AspectRatio, f => f.PickRandom(aspectRatios))
            .RuleFor(c => c.HorizontalResolution, (f, c) =>
            {
                return c.AspectRatio switch
                {
                    "16:9" => f.PickRandom(aspectRatio16_9),
                    "21:9" => f.PickRandom(aspectRatio21_9),
                    "32:9" => f.PickRandom(aspectRatio32_9),
                    "16:10" => f.PickRandom(aspectRatio16_10),
                    "3:2" => f.PickRandom(aspectRatio3_2),
                    _ => f.PickRandom(aspectRatioOther)
                };
            })
            .RuleFor(c => c.VerticalResolution, (f, c) =>
            {
                return c.AspectRatio switch
                {
                    "16:9" => (int)(c.HorizontalResolution / (16m / 9m)),
                    "21:9" => (int)(c.HorizontalResolution / (21m / 9m)),
                    "32:9" => (int)(c.HorizontalResolution / (32m / 9m)),
                    "16:10" => (int)(c.HorizontalResolution / (16m / 10m)),
                    "3:2" => (int)(c.HorizontalResolution / (3m / 2m)),
                    _ => (int)(c.HorizontalResolution / (16m / 9m))
                };
            })
            .RuleFor(c => c.MaxRefreshRate, f => f.PickRandom(refreshRates))
            .RuleFor(c => c.PanelType, f => f.PickRandom(panelTypes))
            .RuleFor(c => c.ResponseTime, (f, c) =>
            {
                return c.PanelType switch
                {
                    "VA" => f.Random.Decimal(2, 8),
                    "TN" => f.Random.Decimal(0.5m, 3),
                    "OLED" => f.Random.Decimal(0.01m, 1),
                    _ => f.Random.Decimal(1, 5)
                };
            })
            .RuleFor(c => c.ViewingAngle, (f, m) => m.PanelType == "TN" ? "170° H x 160° V" : "178° H x 178° V")
            .RuleFor(c => c.MaxBrightness, f => f.Random.Decimal(200, 2000))
            .RuleFor(c => c.HighDynamicRangeType, (f, m) => m.MaxBrightness > 400 ? f.PickRandom(hdrTypes.Where(h => h != "None").ToList()) : "None")
            .RuleFor(c => c.AdaptiveSyncType, f => f.PickRandom(adaptiveSyncTypes))
            .RuleFor(c => c.Name, (f, c) =>
            {
                var resLabel = c.HorizontalResolution switch
                {
                    <= 1920 => "FHD",
                    <= 2560 => "QHD",
                    <= 3840 => "4K",
                    <= 5120 => "5K",
                    _ => "8K"
                };

                var hdrSuffix = c.HighDynamicRangeType != "None" ? $" {c.HighDynamicRangeType}" : "";

                return $"{c.Manufacturer} {f.PickRandom(monitorModelSeries)} " + $"{Math.Round(c.ScreenSize)}\" {resLabel} {c.MaxRefreshRate}Hz {c.PanelType} {hdrSuffix}".Trim();
            });

        private static readonly string[] motherboardManufacturers = ["ASUS", "MSI", "Gigabyte", "ASRock", "Biostar", "EVGA"];
        private static readonly string[] motherboardSockets = ["LGA1700", "AM5", "AM4", "LGA1200"];
        private static readonly string[] motherboardChipsets = ["Z690", "Z790", "B660", "H610", "X670E", "X670", "B650", "A620", "X570", "B550", "A520", "Z590", "B560", "H510"];
        private static readonly string[] motherboardFormFactors = ["ATX", "Micro-ATX", "Mini-ITX", "E-ATX"];
        private static readonly string[] wifiStandards = ["WiFi 5", "WiFi 6", "WiFi 6E", "WiFi 7"];
        private static readonly string[] powerTypes = ["24-pin", "4-pin ATX12V", "8-pin EPS12V"];
        private static readonly string[] audioChips = ["Realtek ALC897", "Realtek ALC1220", "Realtek ALC4080", "ESS Sabre9218", "SupremeFX S1220"];
        private static readonly decimal[] audioChannels = [2, 5.1m, 7.1m];
        private static readonly string[] motherboardLines = ["ROG Strix", "TUF Gaming", "PRO", "Tomahawk", "AORUS Elite", "Steel Legend", "Phantom Gaming", "Creator"];
        private Faker<MotherboardComponent> GetMotherboardComponentFaker() => new Faker<MotherboardComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(motherboardManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.MOTHERBOARD)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.SocketType, f => f.PickRandom(motherboardSockets))
            .RuleFor(c => c.FormFactor, f => f.PickRandom(motherboardFormFactors))
            .RuleFor(c => c.ChipsetType, f => f.PickRandom(motherboardChipsets))
            .RuleFor(c => c.RAMType, f => f.PickRandom(ramTypes))
            .RuleFor(c => c.RAMSlotsAmount, f => f.Random.Int(2, 8))
            .RuleFor(c => c.MaxRAMAmount, (f, c) =>
            {
                return c.FormFactor switch
                {
                    "E-ATX" or "ATX" => f.Random.Decimal(64, 256),
                    "Micro-ATX" => f.Random.Decimal(32, 128),
                    _ => f.Random.Decimal(16, 64)
                };
            })
            .RuleFor(c => c.SATA6GBsAmount, f => f.Random.Int(2, 8))
            .RuleFor(c => c.SATA3GBsAmount, f => f.Random.Int(0, 4))
            .RuleFor(c => c.U2PortAmount, f => f.Random.Int(0, 2))
            .RuleFor(c => c.WirelessNetworkingStandard, f => f.PickRandom(wifiStandards))
            .RuleFor(c => c.CPUFanHeaderAmount, f => f.Random.Int(1, 4))
            .RuleFor(c => c.CaseFanHeaderAmount, f => f.Random.Int(1, 8))
            .RuleFor(c => c.PumpHeaderAmount, f => f.Random.Int(0, 2))
            .RuleFor(c => c.CPUOptionalFanHeaderAmount, f => f.Random.Int(0, 2))
            .RuleFor(c => c.ARGB5vHeaderAmount, f => f.Random.Int(0, 4))
            .RuleFor(c => c.RGB12vHeaderAmount, f => f.Random.Int(0, 4))
            .RuleFor(c => c.HasPowerButtonHeader, f => f.Random.Bool(0.7f))
            .RuleFor(c => c.HasResetButtonHeader, f => f.Random.Bool(0.7f))
            .RuleFor(c => c.HasPowerLEDHeader, f => f.Random.Bool(0.6f))
            .RuleFor(c => c.HasHDDLEDHeader, f => f.Random.Bool(0.6f))
            .RuleFor(c => c.TemperatureSensorHeaderAmount, f => f.Random.Int(0, 3))
            .RuleFor(c => c.ThunderboltHeaderAmount, f => f.Random.Int(0, 2))
            .RuleFor(c => c.COMPortHeaderAmount, f => f.Random.Int(0, 2))
            .RuleFor(c => c.MainPowerType, f => f.Random.Bool(0.95f) ? f.PickRandom(powerTypes) : null)
            .RuleFor(c => c.HasECCSupport, f => f.Random.Bool(0.1f))
            .RuleFor(c => c.HasRAIDSupport, f => f.Random.Bool(0.8f))
            .RuleFor(c => c.HasFlashback, f => f.Random.Bool(0.5f))
            .RuleFor(c => c.HasCMOS, f => f.Random.Bool(0.7f))
            .RuleFor(c => c.AudioChipset, f => f.PickRandom(audioChips))
            .RuleFor(c => c.MaxAudioChannels, f => f.PickRandom(audioChannels))
            .RuleFor(c => c.Name, (f, c) =>
            {
                var line = f.PickRandom(motherboardLines);

                var wifiSuffix = c.WirelessNetworkingStandard.Contains("WiFi", StringComparison.OrdinalIgnoreCase)
                    ? $"WiFi {c.WirelessNetworkingStandard.Replace("WiFi ", "")}"
                    : "";

                return $"{c.Manufacturer} {line} {c.ChipsetType}-{c.FormFactor} {wifiSuffix}".Trim();
            });

        private static readonly string[] powerSupplyManufacturers = ["Corsair", "Seasonic", "EVGA", "Cooler Master", "be quiet!", "Thermaltake", "ASUS", "MSI"];
        private static readonly string[] powerSupplyFormFactors = ["ATX", "SFX", "SFX-L", "TFX", "Flex ATX"];
        private static readonly string[] efficiencyRatings = ["80+ White", "80+ Bronze", "80+ Silver", "80+ Gold", "80+ Platinum", "80+ Titanium"];
        private static readonly string[] modularityTypes = ["Full Modular", "Semi-Modular", "Non-Modular"];
        private static readonly string[] powerSupplySeries = ["RMx", "Prime", "Toughpower", "Focus GX", "Straight Power", "ROG Loki", "MPG A", "V Gold"];
        private Faker<PowerSupplyComponent> GetPowerSupplyComponentFaker() => new Faker<PowerSupplyComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(powerSupplyManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.POWER_SUPPLY)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.FormFactor, f => f.PickRandom(powerSupplyFormFactors))
            .RuleFor(c => c.PowerOutput, (f, c) =>
            {
                return c.FormFactor switch
                {
                    "SFX" or "SFX-L" => f.Random.Decimal(300, 1000),
                    "TFX" or "Flex ATX" => f.Random.Decimal(200, 500),
                    _ => f.Random.Decimal(400, 2000)
                };
            })
            .RuleFor(c => c.EfficiencyRating, f => f.Random.Bool(0.9f) ? f.PickRandom(efficiencyRatings) : null)
            .RuleFor(c => c.ModularityType, f => f.PickRandom(modularityTypes))
            .RuleFor(c => c.Length, f => f.Random.Decimal(80, 200))
            .RuleFor(c => c.IsFanless, (f, c) => c.PowerOutput < 600 && f.Random.Bool(0.1f))
            .RuleFor(c => c.Name, (f, c) =>
            {
                var series = f.PickRandom(powerSupplySeries);

                var fanlessSuffix = c.IsFanless ? "Fanless" : "";
                var rating = c.EfficiencyRating != null ? c.EfficiencyRating?.Replace("80+", "").Trim() : "";

                return $"{c.Manufacturer} {series} {Math.Round(c.PowerOutput)}W {rating} {c.ModularityType} {fanlessSuffix}".Trim();
            });

        private static readonly string[] storageManufacturers = ["Samsung", "Western Digital", "Seagate", "Crucial", "Kingston", "Corsair", "ADATA", "Intel", "Toshiba", "Sabrent"];
        private static readonly string[] driveTypes = ["SSD", "HDD", "NVMe", "SSHD"];
        private static readonly string[] storageFormFactor = ["3.5\"", "2.5\"", "M.2-2280", "mSATA", "M.2-22110", "Add-in Card",];
        private static readonly string[] interfaces = ["SATA", "PCIe 3.0", "PCIe 4.0", "PCIe 5.0"];
        private static readonly string[] storageSeries = ["870 EVO", "980 Pro", "Blue", "Black", "Barracuda", "IronWolf", "MX500", "P5 Plus", "A2000", "KC3000", "MP600", "MP700", "XPG SX8200", "Legend 960", "660p", "670p", "X300", "P300", "Rocket 4 Plus", "Rocket 5"];

        private Faker<StorageComponent> GetStorageComponentFaker() => new Faker<StorageComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.Manufacturer, f => f.PickRandom(storageManufacturers))
            .RuleFor(c => c.Release, f => f.Date.Past(15, DateTime.UtcNow))
            .RuleFor(c => c.Type, _ => ComponentType.STORAGE)
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null)
            .RuleFor(c => c.Series, f => f.PickRandom(storageSeries))
            .RuleFor(c => c.Capacity, f => f.Random.Decimal(128, 16000))
            .RuleFor(c => c.DriveType, f => f.PickRandom(driveTypes))
            .RuleFor(c => c.FormFactor, f => f.PickRandom(storageFormFactor))
            .RuleFor(c => c.Interface, f => f.PickRandom(interfaces))
            .RuleFor(c => c.HasNVMe, (f, c) => c.DriveType == "NVMe")
            .RuleFor(c => c.Name, (f, c) =>
            {
                var capacityLabel = c.Capacity >= 1000 ? $"{c.Capacity / 1000}TB" : $"{c.Capacity}GB";

                var nvmeLabel = c.HasNVMe ? "NVMe" : "";

                return $"{c.Manufacturer} {c.Series} {nvmeLabel} {capacityLabel} {c.FormFactor} {c.Interface}".Trim();
            });

        private Faker<BaseSubComponent> GetBaseSubComponentFaker() => new Faker<BaseSubComponent>("en")
            .RuleFor(s => s.Id, f => Guid.NewGuid())
            .RuleFor(s => s.Name, f => $"{f.Commerce.ProductName()} {f.Random.AlphaNumeric(3).ToUpper()}")
            .RuleFor(s => s.Type, f => f.PickRandom<SubComponentType>())
            .RuleFor(s => s.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(s => s.LastEditedAt, f => f.Date.Recent(60))
            .RuleFor(s => s.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private static readonly string[] socketTypes = ["AM4", "AM5", "LGA1200", "LGA1700", "TR4", "sTRX4", "SP5"];
        private Faker<CoolerSocketSubComponent> GetCoolerSocketSubComponentFaker() => new Faker<CoolerSocketSubComponent>("en")
            .RuleFor(s => s.Id, _ => Guid.NewGuid())
            .RuleFor(s => s.Type, _ => SubComponentType.COOLER_SCOKET)
            .RuleFor(s => s.SocketType, f => f.PickRandom(socketTypes))
            .RuleFor(s => s.Name, (f, s) => $"Socket Compatibility: {s.SocketType}")
            .RuleFor(s => s.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(s => s.LastEditedAt, f => f.Date.Recent(60))
            .RuleFor(s => s.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private static readonly string[] m2Sizes = ["2230", "2242", "2260", "2280", "22110"];
        private static readonly string[] m2KeyTypes = ["M key", "B key", "B+M key"];
        private static readonly string[] m2Interfaces = ["PCIe 3.0 x4", "PCIe 4.0 x4", "PCIe 5.0 x4", "SATA"];
        private Faker<M2SlotSubComponent> GetM2SlotSubComponentFaker() => new Faker<M2SlotSubComponent>("en")
            .RuleFor(s => s.Id, _ => Guid.NewGuid())
            .RuleFor(s => s.Type, _ => SubComponentType.M2_SLOT)
            .RuleFor(s => s.Size, f => f.PickRandom(m2Sizes))
            .RuleFor(s => s.KeyType, f => f.PickRandom(m2KeyTypes))
            .RuleFor(s => s.Interface, f => f.PickRandom(m2Interfaces))
            .RuleFor(s => s.Name, (f, s) => $"M.2 {s.Size} {s.KeyType} ({s.Interface}) Slot")
            .RuleFor(s => s.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(s => s.LastEditedAt, f => f.Date.Recent(60))
            .RuleFor(s => s.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);


        private static readonly string[] igpuModels = ["Radeon 780M", "Radeon 680M", "Intel UHD 770", "Intel Iris Xe 96EU", "Radeon Vega 8"];
        private Faker<IntegratedGraphicsSubComponent> GetIntegratedGraphicsSubComponentFaker() => new Faker<IntegratedGraphicsSubComponent>("en")
            .RuleFor(s => s.Id, _ => Guid.NewGuid())
            .RuleFor(s => s.Type, _ => SubComponentType.INTEGRATED_GRAPHICS)
            .RuleFor(s => s.Model, f => f.PickRandom(igpuModels))
            .RuleFor(s => s.BaseClockSpeed, f => f.Random.Int(300, 2000))
            .RuleFor(s => s.BoostClockSpeed, (f, s) => s.BaseClockSpeed + f.Random.Int(200, 1000))
            .RuleFor(s => s.CoreCount, f => f.Random.Int(128, 8192))
            .RuleFor(s => s.Name, (f, s) => $"{s.Model} ({s.CoreCount} cores, {s.BoostClockSpeed} MHz boost)")
            .RuleFor(s => s.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(s => s.LastEditedAt, f => f.Date.Recent(60))
            .RuleFor(s => s.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private static readonly string[] ethernetSpeeds = ["1 Gb/s", "2.5 Gb/s", "5 Gb/s", "10 Gb/s"];
        private static readonly string[] ethernetControllers = ["Intel I225-V", "Intel I219-V", "Realtek RTL8125B", "Marvell AQtion AQC113", "Killer E3100G"];
        private Faker<OnboardEthernetSubComponent> GetOnboardEthernetSubComponentFaker() => new Faker<OnboardEthernetSubComponent>("en")
            .RuleFor(s => s.Id, _ => Guid.NewGuid())
            .RuleFor(s => s.Type, _ => SubComponentType.ONBOARD_ETHERNET)
            .RuleFor(s => s.Speed, f => f.PickRandom(ethernetSpeeds))
            .RuleFor(s => s.Controller, f => f.PickRandom(ethernetControllers))
            .RuleFor(s => s.Name, (f, s) => $"{s.Controller} ({s.Speed}) Ethernet")
            .RuleFor(s => s.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(s => s.LastEditedAt, f => f.Date.Recent(60))
            .RuleFor(s => s.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private static readonly string[] pcieGens = ["3.0", "4.0", "5.0"];
        private static readonly string[] pcieLanes = ["x1", "x4", "x8", "x16"];
        private Faker<PCIeSlotSubComponent> GetPCIeSlotSubComponentFaker() => new Faker<PCIeSlotSubComponent>("en")
            .RuleFor(s => s.Id, _ => Guid.NewGuid())
            .RuleFor(s => s.Type, _ => SubComponentType.PCIE_SLOT)
            .RuleFor(s => s.Gen, f => f.PickRandom(pcieGens))
            .RuleFor(s => s.Lanes, f => f.PickRandom(pcieLanes))
            .RuleFor(s => s.Name, (f, s) => $"PCIe Gen {s.Gen} {s.Lanes} Slot")
            .RuleFor(s => s.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(s => s.LastEditedAt, f => f.Date.Recent(60))
            .RuleFor(s => s.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<PortSubComponent> GetPortSubComponentFaker() => new Faker<PortSubComponent>("en")
            .RuleFor(s => s.Id, _ => Guid.NewGuid())
            .RuleFor(s => s.Type, _ => SubComponentType.PORT)
            .RuleFor(s => s.PortType, f => f.PickRandom<PortType>())
            .RuleFor(s => s.Name, (f, s) => $"{s.PortType} Port")
            .RuleFor(s => s.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(s => s.LastEditedAt, f => f.Date.Recent(60))
            .RuleFor(s => s.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<Color> GetColorFaker() => new Faker<Color>("en")
            .RuleFor(c => c.ColorCode, f => "#" + f.Random.Hexadecimal(6, string.Empty).ToUpper())
            .RuleFor(c => c.ColorName, f => f.Commerce.Color())
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<ComponentCompatibility> GetComponentCompatibilityFaker(List<Guid> componentIds) => new Faker<ComponentCompatibility>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.ComponentId, f => f.PickRandom(componentIds))
            .RuleFor(c => c.CompatibleComponentId, (f, c) =>
            {
                var unassignedIds = componentIds.Where(id => id != c.ComponentId).ToList();
                return f.PickRandom(unassignedIds);
            })
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<ComponentPart> GetComponentPartFaker(List<Guid> componentIds, List<Guid> subComponentIds) => new Faker<ComponentPart>("en")
            .RuleFor(p => p.Id, f => Guid.NewGuid())
            .RuleFor(p => p.ComponentId, f => f.PickRandom(componentIds))
            .RuleFor(p => p.SubComponentId, f => f.PickRandom(subComponentIds))
            .RuleFor(p => p.Amount, f => f.Random.Int(1, 4))
            .RuleFor(p => p.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(p => p.LastEditedAt, (f, p) => f.Date.Between(p.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(p => p.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<ComponentPrice> GetComponentPriceFaker(List<Guid> componentIds) => new Faker<ComponentPrice>("en")
            .RuleFor(p => p.Id, f => Guid.NewGuid())
            .RuleFor(p => p.SourceUrl, f => "https://allegro.pl/?tag=gx-pl-allegro-allegro-sd-def")
            .RuleFor(p => p.ComponentId, f => f.PickRandom(componentIds))
            .RuleFor(p => p.VendorName, f => f.Company.CompanyName())
            .RuleFor(p => p.FetchedAt, f => f.Date.Recent(30))
            .RuleFor(p => p.Price, f => f.Random.Decimal(100, 10000))
            .RuleFor(p => p.Currency, f => f.Finance.Currency().Code)
            .RuleFor(p => p.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(p => p.LastEditedAt, (f, p) => f.Date.Between(p.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(p => p.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<ComponentReview> GetComponentReviewFaker(List<Guid> componentIds) => new Faker<ComponentReview>("en")
            .RuleFor(r => r.Id, f => Guid.NewGuid())
            .RuleFor(r => r.SourceUrl, f => "https://www.tomshardware.com/reviews/gpu-hierarchy,4388.html")
            .RuleFor(r => r.ComponentId, f => f.PickRandom(componentIds))
            .RuleFor(r => r.ReviewerName, f => f.Company.CompanyName())
            .RuleFor(r => r.FetchedAt, f => f.Date.Recent(30))
            .RuleFor(r => r.CreatedAt, f => f.Date.Past(5, DateTime.UtcNow))
            .RuleFor(r => r.Rating, f => f.Random.Int(0, 100))
            .RuleFor(r => r.ReviewText, f => f.Rant.Review())
            .RuleFor(r => r.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(r => r.LastEditedAt, (f, r) => f.Date.Between(r.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(r => r.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<ComponentVariant> GetComponentVariantFaker(List<Guid> componentIds, List<ComponentPrice> prices) => new Faker<ComponentVariant>("en")
            .RuleFor(v => v.Id, f => Guid.NewGuid())
            .RuleFor(v => v.ComponentId, f => f.PickRandom(componentIds))
            .RuleFor(v => v.IsAvailable, f => f.Random.Bool(0.9f))
            .RuleFor(v => v.AdditionalPrice, (f, v) =>
            {
                ComponentPrice? componentPrice = prices.Where(p => p.ComponentId == v.ComponentId).FirstOrDefault();

                if (componentPrice == null || f.Random.Bool(0.9f))
                    return null;

                decimal price = componentPrice.Price;
                decimal additionalPrice = f.Random.Decimal(-100, 100);

                if (price + additionalPrice < 0)
                    return null;

                return additionalPrice;
            })
            .RuleFor(v => v.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(v => v.LastEditedAt, (f, v) => f.Date.Between(v.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(v => v.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<ColorVariant> GetColorVariantFaker(List<Guid> componentVariantIds, List<string> colorCodes) => new Faker<ColorVariant>("en")
            .RuleFor(v => v.Id, f => Guid.NewGuid())
            .RuleFor(v => v.ComponentVariantId, f => f.PickRandom(componentVariantIds))
            .RuleFor(v => v.ColorCode, f => f.PickRandom(colorCodes))
            .RuleFor(v => v.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(v => v.LastEditedAt, (f, v) => f.Date.Between(v.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(v => v.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<SubComponentPart> GetSubComponentPartFaker(List<Guid> subComponentIds) => new Faker<SubComponentPart>("en")
            .RuleFor(p => p.Id, f => Guid.NewGuid())
            .RuleFor(p => p.MainSubComponentId, f => f.PickRandom(subComponentIds))
            .RuleFor(p => p.SubComponentId, (f, c) =>
            {
                var unassignedIds = subComponentIds.Where(id => id != c.MainSubComponentId).ToList();
                return f.PickRandom(unassignedIds);
            })
            .RuleFor(p => p.Amount, f => f.Random.Int(1, 4))
            .RuleFor(p => p.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(p => p.LastEditedAt, (f, p) => f.Date.Between(p.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(p => p.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<Build> GetBuildFaker(List<Guid> userIds) => new Faker<Build>("en")
            .RuleFor(b => b.Id, f => Guid.NewGuid())
            .RuleFor(b => b.UserId, f => f.PickRandom(userIds))
            .RuleFor(b => b.Name, f => $"{f.Hacker.Adjective()} {f.Hacker.Noun()} Build")
            .RuleFor(b => b.Description, f => f.Lorem.Sentence(10, 5))
            .RuleFor(b => b.Status, f => f.PickRandom<BuildStatus>())
            .RuleFor(b => b.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(b => b.LastEditedAt, (f, b) => f.Date.Between(b.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(b => b.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<Tag> GetTagFaker() => new Faker<Tag>("en")
            .RuleFor(t => t.Id, f => Guid.NewGuid())
            .RuleFor(t => t.Name, f => $"{f.Hacker.Adjective()} {f.Hacker.Noun()}")
            .RuleFor(t => t.Description, f => f.Lorem.Sentence(8, 4))
            .RuleFor(t => t.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(t => t.LastEditedAt, (f, t) => f.Date.Between(t.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(t => t.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<BuildTag> GetBuildTagFaker(List<Guid> buildIds, List<Guid> tagIds) => new Faker<BuildTag>("en")
            .RuleFor(bt => bt.Id, f => Guid.NewGuid())
            .RuleFor(bt => bt.BuildId, f => f.PickRandom(buildIds))
            .RuleFor(bt => bt.TagId, f => f.PickRandom(tagIds))
            .RuleFor(bt => bt.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(bt => bt.LastEditedAt, (f, bt) => f.Date.Between(bt.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(bt => bt.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<BuildComponent> GetBuildComponentFaker(List<Guid> buildIds, List<Guid> componentIds) => new Faker<BuildComponent>("en")
            .RuleFor(c => c.Id, f => Guid.NewGuid())
            .RuleFor(c => c.BuildId, f => f.PickRandom(buildIds))
            .RuleFor(c => c.ComponentId, f => f.PickRandom(componentIds))
            .RuleFor(c => c.Quantity, f => f.Random.Int(1, 4))
            .RuleFor(c => c.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(c => c.LastEditedAt, (f, c) => f.Date.Between(c.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(c => c.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);

        private Faker<BuildInteraction> GetBuildInteractionFaker(List<Guid> userIds, List<Guid> buildIds) => new Faker<BuildInteraction>("en")
            .RuleFor(i => i.Id, f => Guid.NewGuid())
            .RuleFor(i => i.UserId, f => f.PickRandom(userIds))
            .RuleFor(i => i.BuildId, f => f.PickRandom(buildIds))
            .RuleFor(i => i.IsWishlisted, f => f.Random.Bool(0.3f))
            .RuleFor(i => i.IsLiked, f => f.Random.Bool(0.6f))
            .RuleFor(i => i.Rating, (f, i) => i.IsLiked ? f.Random.Int(60, 100) : f.Random.Int(0, 70))
            .RuleFor(i => i.UserNote, f => f.Random.Bool(0.25f) ? f.Lorem.Sentence() : null)
            .RuleFor(i => i.DatabaseEntryAt, f => f.Date.Past(2, DateTime.UtcNow))
            .RuleFor(i => i.LastEditedAt, (f, bi) => f.Date.Between(bi.DatabaseEntryAt, DateTime.UtcNow))
            .RuleFor(i => i.Note, f => f.Random.Bool(0.4f) ? f.Lorem.Sentence() : null);
    }
}
