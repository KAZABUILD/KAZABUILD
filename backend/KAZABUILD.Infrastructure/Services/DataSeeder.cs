using Bogus;
using KAZABUILD.Application.Interfaces;
using KAZABUILD.Domain.Entities.Users;
using KAZABUILD.Domain.Enums;
using KAZABUILD.Infrastructure.Data;
using System;
using System.Security.Cryptography;

namespace KAZABUILD.Infrastructure.Services
{
    /// <summary>
    /// Service used to seed the database with fake data.
    /// </summary>
    /// <param name="context"></param>
    /// <param name="hasher"></param>
    public class DataSeeder(KAZABUILDDBContext context, IHashingService hasher) : IDataSeeder
    {
        //Services used for data seeding
        private readonly KAZABUILDDBContext _context = context;
        private readonly IHashingService _hasher = hasher;

        /// <summary>
        /// Function used to seed the database with fake data.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <typeparam name="T2"></typeparam>
        /// <param name="count"></param>
        /// <param name="ids1"></param>
        /// <param name="ids2"></param>
        /// <param name="idsOptional"></param>
        /// <param name="password"></param>
        /// <returns></returns>
        public async Task<List<T2>> SeedAsync<T, T2>(int count, List<Guid>? ids1 = null, List<Guid>? ids2 = null, List<string>? idsOptional = null, string password = "password123!") where T : class
        {
            //Find the correct faker for this entity type
            var faker = GetFakerFor<T>(ids1, ids2, idsOptional, password);

            //Generate the entities using the faker
            var entities = faker.Generate(count);

            //List storing the return ids
            var savedIds = new List<T2>();

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
                    var id = (T2)entity.GetType().GetProperty("Id")!.GetValue(entity)! ?? (T2)entity.GetType().GetProperty("ColorCode")!.GetValue(entity)!;

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

            //Return the ids for the seeded table rows
            return savedIds;
        }

        /// <summary>
        /// Class for getting the correct faker factory
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        /// <exception cref="InvalidOperationException"></exception>
        private Faker<T> GetFakerFor<T>(List<Guid>? ids1, List<Guid>? ids2, List<string>? idsOptional, string password) where T : class
        {
            //Get the correct faker factory for the provided type
            if (typeof(T) == typeof(User))
            {
                List<UserRole> roles = [.. Enum.GetValues<UserRole>().Cast<UserRole>().Where(r => r != UserRole.SYSTEM && r != UserRole.OWNER)];
                List<ProfileAccessibility> accessibilities = [.. Enum.GetValues<ProfileAccessibility>().Cast<ProfileAccessibility>()];
                List<Theme> themes = [.. Enum.GetValues<Theme>().Cast<Theme>()];
                List<Language> languages = [.. Enum.GetValues<Language>().Cast<Language>()];

                return (Faker<T>)(object)GetUserFaker(roles, accessibilities, themes, languages, password);
            }

            if (typeof(T) == typeof(Notification))
            {
                List<NotificationType> notificationTypes = [.. Enum.GetValues<NotificationType>().Cast<NotificationType>()];

                var userIds = ids1 ?? [Guid.Empty];

                return (Faker<T>)(object)GetNotificationFaker(userIds, notificationTypes);
            }

            //Throw an exception if invalid class provided
            throw new InvalidOperationException($"No faker found for {typeof(T).Name}");
        }

        //Faker factories which create rules necessary to seed a specific model table
        private Faker<User> GetUserFaker(List<UserRole> roles, List<ProfileAccessibility> accessibilities, List<Theme> themes, List<Language> languages, string password) => new Faker<User>("en")
            .RuleFor(u => u.Id, f => Guid.NewGuid())
            .RuleFor(u => u.Login, f => f.Internet.UserName().PadRight(8, 'x')[..Math.Min(f.Internet.UserName().Length, 50)])
            .RuleFor(u => u.Email, (f, u) => f.Internet.Email(u.Login))
            .RuleFor(u => u.PasswordHash, f => _hasher.Hash(password))
            .RuleFor(u => u.DisplayName, f => f.Internet.UserName().PadRight(8, 'x')[..Math.Min(f.Internet.UserName().Length, 50)])
            .RuleFor(u => u.PhoneNumber, f => f.Random.Bool() ? f.Phone.PhoneNumber() : null)
            .RuleFor(u => u.Description, f => f.Random.Bool() ? $"<p>{f.Lorem.Paragraph()}</p>" : null)
            .RuleFor(u => u.Gender, f => f.PickRandom(new[] { "Male", "Female", "Non-binary", "Other" }))
            .RuleFor(u => u.UserRole, f => f.PickRandom(roles))
            .RuleFor(u => u.ImageUrl, f => "wwwroot/defaultuser.png")
            .RuleFor(u => u.Birth, f => f.Date.Past(60, DateTime.UtcNow.AddYears(-18)))
            .RuleFor(u => u.RegisteredAt, f => f.Date.Past(2))
            .RuleFor(u => u.Address, f => null)
            .RuleFor(u => u.ProfileAccessibility, f => f.PickRandom(accessibilities))
            .RuleFor(u => u.Theme, f => f.PickRandom(themes))
            .RuleFor(u => u.Language, f => f.PickRandom(languages))
            .RuleFor(u => u.Location, f => f.Random.Bool() ? f.Address.City() : null)
            .RuleFor(u => u.ReceiveEmailNotifications, f => f.Random.Bool())
            .RuleFor(u => u.EnableDoubleFactorAuthentication, f => f.Random.Bool())
            .RuleFor(u => u.GoogleId, f => null)
            .RuleFor(u => u.GoogleProfilePicture, f => null)
            .RuleFor(u => u.DatabaseEntryAt, f => DateTime.UtcNow)
            .RuleFor(u => u.LastEditedAt, f => f.Date.Recent(30))
            .RuleFor(u => u.Note, f => f.Random.Bool() ? f.Lorem.Sentence(5) : null);

        private Faker<Notification> GetNotificationFaker(List<Guid> userIds, List<NotificationType> notificationTypes) => new Faker<Notification>("en")
            .RuleFor(n => n.Id, f => Guid.NewGuid())
            .RuleFor(n => n.UserId, f => f.PickRandom(userIds))
            .RuleFor(n => n.NotificationType, f => f.PickRandom(notificationTypes))
            .RuleFor(n => n.Title, f => f.Lorem.Sentence(3)[..Math.Min(f.Lorem.Sentence(3).Length, 50)])
            .RuleFor(n => n.Body, f => $"<p>{f.Lorem.Paragraphs(1)}</p>")
            .RuleFor(n => n.LinkUrl, f => null)
            .RuleFor(n => n.SentAt, f => f.Date.Recent(30))
            .RuleFor(n => n.IsRead, f => f.Random.Bool(0.5f))
            .RuleFor(n => n.DatabaseEntryAt, f => DateTime.UtcNow)
            .RuleFor(n => n.LastEditedAt, f => f.Date.Recent(30))
            .RuleFor(n => n.Note, f => f.Random.Bool(0.2f) ? f.Lorem.Sentence() : null);
    }
}
