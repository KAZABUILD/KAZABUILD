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
            //Check if the class has assignable derived classes and if it is an abstract class
            if (typeof(TBase).IsAssignableFrom(context.Type) && context.Type.IsAbstract)
            {
                //Get all class types which derive from the provided abstract class
                var derivedTypes = typeof(TBase).Assembly
                    .GetCustomAttributes<JsonDerivedTypeAttribute>()
                    .Select(attr => attr.DerivedType);

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
            }
        }
    }
}
