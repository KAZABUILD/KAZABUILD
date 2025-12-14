using System.Reflection;

using KAZABUILD.Application.DTOs.Components.Components.ComponentFilter;
using KAZABUILD.Domain.Entities.Components.Components;

namespace KAZABUILD.Application.Helpers
{
    /// <summary>
    /// Helper build class that generates component filters based on a list of components.
    /// </summary>
    public static class ComponentFilterBuilder
    {
        /// <summary>
        /// Function that goes over all properties of the provided components and builds filter fields accordingly.
        /// </summary>
        /// <param name="components"></param>
        /// <returns></returns>
        public static ComponentFiltersDto Build(IEnumerable<BaseComponent> components)
        {
            //Declare the initial result list 
            var result = new ComponentFiltersDto();

            //Convert components to a list and check if it's not empty
            var list = components?.ToList() ?? [];
            if (list.Count == 0)
                return result;

            //Declare sets of different allowed types
            var numericTypes = new HashSet<Type>
            {
                typeof(byte), typeof(short), typeof(int), typeof(long),
                typeof(float), typeof(double), typeof(decimal),
                typeof(byte?), typeof(short?), typeof(int?), typeof(long?),
                typeof(float?), typeof(double?), typeof(decimal?)
            };
            var dateTypes = new HashSet<Type> { typeof(DateTime), typeof(DateTime?) };
            var fields = new Dictionary<string, FilterFieldDto>(StringComparer.OrdinalIgnoreCase);

            //Iterate over each component and its properties
            foreach (var component in list)
            {
                //Get all properties of the component
                var properties = component.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);

                //Iterate over each property in a component
                foreach (var property in properties)
                {
                    //Skip over the unwanted properties and those that are missing a getter
                    if (property.Name.Equals("Id", StringComparison.OrdinalIgnoreCase))
                        continue;
                    if (property.Name.Equals("Name", StringComparison.OrdinalIgnoreCase))
                        continue;
                    if (property.Name.Equals("LastEditedAt", StringComparison.OrdinalIgnoreCase))
                        continue;
                    if (property.Name.Equals("DatabaseEntryAt", StringComparison.OrdinalIgnoreCase))
                        continue;
                    if (property.Name.Equals("Note", StringComparison.OrdinalIgnoreCase))
                        continue;
                    if (property.GetMethod == null)
                        continue;

                    //Get the property type
                    var propertyType = property.PropertyType;

                    //Skip over collection types (except string) to avoid processing other table connections
                    if (propertyType != typeof(string) && typeof(System.Collections.IEnumerable).IsAssignableFrom(propertyType))
                        continue;

                    //Flatten nested complex properties
                    if (!propertyType.IsPrimitive && propertyType != typeof(string) && !propertyType.IsEnum && !numericTypes.Contains(propertyType) && !dateTypes.Contains(propertyType) && propertyType != typeof(bool) && propertyType != typeof(bool?))
                    {
                        //Try to get nested properties
                        var nestedProperties = propertyType.GetProperties(BindingFlags.Public | BindingFlags.Instance);
                        if (nestedProperties.Length != 0)
                        {
                            //Get the nested object
                            var nestedObject = property.GetValue(component);

                            //Check if the nested object isn't null
                            if (nestedObject == null)
                                continue;

                            //Iterate over each nested property
                            foreach (var np in nestedProperties)
                            {
                                //Create a new key for the nested property in order to get the correct ranges and lists
                                var key = $"{property.Name}.{np.Name}";

                                //Process the nested property value
                                ProcessPropertyValue(np.PropertyType, np.GetValue(nestedObject), key, fields, numericTypes, dateTypes);
                            }
                            continue;
                        }
                    }

                    //Process the property value
                    ProcessPropertyValue(propertyType, property.GetValue(component), property.Name, fields, numericTypes, dateTypes);
                }
            }

            //Assign the built fields to the result and return it
            result.Fields = fields;
            return result;
        }

        /// <summary>
        /// Function that processes the provided property value based on its type and updates the fields dictionary accordingly.
        /// </summary>
        /// <param name="propertyType"></param>
        /// <param name="value"></param>
        /// <param name="key"></param>
        /// <param name="fields"></param>
        /// <param name="numericTypes"></param>
        /// <param name="dateTypes"></param>
        private static void ProcessPropertyValue(Type propertyType, object? value, string key, Dictionary<string, FilterFieldDto> fields, HashSet<Type> numericTypes, HashSet<Type> dateTypes)
        {
            //Process if the property is a string type
            if (propertyType == typeof(string))
            {
                if (!fields.TryGetValue(key, out var field))
                {
                    field = new FilterFieldDto { Type = FilterFieldType.String, StringValues = new List<string>() };
                    fields[key] = field;
                }
                var s = value as string;
                if (!string.IsNullOrWhiteSpace(s) && !field.StringValues!.Contains(s))
                    field.StringValues!.Add(s);
            }
            //Process if the property is a numeric type
            else if (numericTypes.Contains(propertyType))
            {
                if (!fields.TryGetValue(key, out var field))
                {
                    field = new FilterFieldDto { Type = FilterFieldType.Numeric };
                    fields[key] = field;
                }
                if (value != null)
                {
                    decimal v = Convert.ToDecimal(value);
                    field.MinNumeric = field.MinNumeric.HasValue ? Math.Min(field.MinNumeric.Value, v) : v;
                    field.MaxNumeric = field.MaxNumeric.HasValue ? Math.Max(field.MaxNumeric.Value, v) : v;
                }
                else
                {
                    //For nullable fields, set MinNumeric to 0 to indicate that null values exist
                    field.MinNumeric = field.MinNumeric.HasValue ? Math.Min(field.MinNumeric.Value, 0) : 0;
                }
            }
            //Process if the property is a date type
            else if (dateTypes.Contains(propertyType))
            {
                if (!fields.TryGetValue(key, out var field))
                {
                    field = new FilterFieldDto { Type = FilterFieldType.Date };
                    fields[key] = field;
                }
                if (value is DateTime dt && dt != DateTime.MinValue)
                {
                    field.MinDate = field.MinDate.HasValue ? field.MinDate.Value < dt ? field.MinDate : dt : dt;
                    field.MaxDate = field.MaxDate.HasValue ? field.MaxDate.Value > dt ? field.MaxDate : dt : dt;
                }
            }
            //Process if the property is a boolean type
            else if (propertyType == typeof(bool) || propertyType == typeof(bool?))
            {
                if (!fields.TryGetValue(key, out var field))
                {
                    field = new FilterFieldDto { Type = FilterFieldType.Boolean };
                    fields[key] = field;
                }
                if (value is bool b)
                {
                    if (b) field.HasTrue = true;
                    else field.HasFalse = true;
                }
            }
            //Ignore other property types
        }
    }
}
