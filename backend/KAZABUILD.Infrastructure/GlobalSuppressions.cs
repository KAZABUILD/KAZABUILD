// This file is used by Code Analysis to maintain SuppressMessage
// attributes that are applied to this project.
// Project-level suppressions either have no target or are given
// a specific target and scoped to a namespace, type, member, etc.

using System.Diagnostics.CodeAnalysis;

[assembly: SuppressMessage("Style", "IDE0290:Use primary constructor", Justification = "Necessary for the DB Context to function", Scope = "member", Target = "~M:KAZABUILD.Infrastructure.Data.KAZABUILDDBContext.#ctor(Microsoft.EntityFrameworkCore.DbContextOptions{KAZABUILD.Infrastructure.Data.KAZABUILDDBContext})")]
[assembly: SuppressMessage("Usage", "CA2254:Template should be a static expression", Justification = "Does not hinder Serilog functionality", Scope = "member", Target = "~M:KAZABUILD.Infrastructure.Services.LoggerService.LogAsync(System.Guid,System.String,System.String,System.String,System.Guid,KAZABUILD.Domain.Enums.PrivacyLevel,System.String)~System.Threading.Tasks.Task")]
[assembly: SuppressMessage("Naming", "VSSpell001:Spell Check", Justification = "IP can be spelled like this", Scope = "member", Target = "~P:KAZABUILD.Infrastructure.Data.KAZABUILDDBContext.BlockedIps")]
