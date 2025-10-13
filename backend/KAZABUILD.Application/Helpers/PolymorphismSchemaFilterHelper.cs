using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Reflection;
using System.Text.Json.Serialization;

namespace KAZABUILD.Application.Helpers
{
    /// <summary>
    /// Helper Class for applying a filter in swagger to create a dropdown for polymorphic classes.
    /// Allows swagger to detect [JsonDerivedType] annotations properly.
    /// </summary>
    /// <typeparam name="TBase"></typeparam>
    public class PolymorphismSchemaFilter<TBase> : ISchemaFilter
    {
        //Function that applies the functionality of the class
        public void Apply(OpenApiSchema schema, SchemaFilterContext context)
        {
            //Only apply when generating the schema for the base type
            if (context.Type == typeof(TBase))
            {
                //Read all [JsonDerivedType] attributes from the base DTO
                var derivedTypes = typeof(TBase)
                    .GetCustomAttributes<JsonDerivedTypeAttribute>()
                    .Select(attr => attr.DerivedType)
                    .Distinct()
                    .ToList();

                //If there are no derived classes return
                if (derivedTypes.Count == 0)
                    return;

                //Create a OneOf XML schema to create a dropdown in swagger
                schema.OneOf = [];

                //Add each derived schema from the derived classes
                foreach (var derived in derivedTypes)
                {
                    //Generate a schema for the derived class
                    var derivedSchema = context.SchemaGenerator.GenerateSchema(derived, context.SchemaRepository);

                    //Add to the schema
                    schema.OneOf.Add(derivedSchema);
                }

                var derivedTypeAttributes = typeof(TBase)
                    .GetCustomAttributes<JsonDerivedTypeAttribute>()
                    .ToList();

                schema.Discriminator = new OpenApiDiscriminator
                {
                    PropertyName = "type",
                    Mapping = derivedTypeAttributes.ToDictionary(
                        attr => attr.TypeDiscriminator?.ToString() ?? attr.DerivedType.Name,
                        attr => $"#/components/schemas/{attr.DerivedType.Name}")
                };
            }
        }
    }
}
