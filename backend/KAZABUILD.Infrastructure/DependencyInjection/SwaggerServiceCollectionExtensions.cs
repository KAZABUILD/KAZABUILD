using KAZABUILD.Application.DTOs.Components.Components.BaseComponent;
using KAZABUILD.Application.DTOs.Components.SubComponents.BaseSubComponent;
using KAZABUILD.Application.Helpers;

using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi.Models;

namespace KAZABUILD.Infrastructure.DependencyInjection
{
    //Extension for adding authorization to the app services
    public static class SwaggerServiceCollectionExtension
    {
        public static IServiceCollection AddSwaggerSettings(this IServiceCollection services)
        {
            //Documentation with swagger
            services.AddSwaggerGen(c =>
            {
                //Enable adding a jwt security token
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header
                });

                //Inform swagger that endpoints require authorization
                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });

                //Enable handling null references
                c.SupportNonNullableReferenceTypes();

                //Enable comments in the swagger endpoints
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "My API", Version = "v1" });

                //Add comments from an XML files in all assemblies
                var xmlFiles = Directory.GetFiles(AppContext.BaseDirectory, "*.xml", SearchOption.TopDirectoryOnly);
                foreach (var xmlFile in xmlFiles)
                {
                    c.IncludeXmlComments(xmlFile, includeControllerXmlComments: true);
                }

                //Enable displaying polymorphic schemas in swagger endpoints
                c.EnableAnnotations();
                c.UseOneOfForPolymorphism();
                c.UseAllOfForInheritance();

                //Register detection of polymorphic classes
                c.SchemaFilter<PolymorphismSchemaFilter<UpdateBaseComponentDto>>();
                c.SchemaFilter<PolymorphismSchemaFilter<CreateBaseComponentDto>>();
                c.SchemaFilter<PolymorphismSchemaFilter<GetBaseComponentDto>>();
                c.SchemaFilter<PolymorphismSchemaFilter<BaseComponentResponseDto>>();
                c.SchemaFilter<PolymorphismSchemaFilter<UpdateBaseSubComponentDto>>();
                c.SchemaFilter<PolymorphismSchemaFilter<CreateBaseSubComponentDto>>();
                c.SchemaFilter<PolymorphismSchemaFilter<GetBaseSubComponentDto>>();
                c.SchemaFilter<PolymorphismSchemaFilter<BaseSubComponentResponseDto>>();

            });

            //Return the services with added authorization
            return services;
        }
    }
}
