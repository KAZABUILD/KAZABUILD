using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Validators
{
    /// <summary>
    /// Validator for checking if only one of multiple attributes is present in an object.
    /// </summary>
    /// <param name="propertyNames"></param>
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = false)]
    public class RequireOnlyOneAttribute(params string[] propertyNames) : ValidationAttribute
    {
        //Store names of properties to validate
        private readonly string[] _propertyNames = propertyNames;

        /// <summary>
        /// Checks if only one of the objects was provided.
        /// </summary>
        /// <param name="value"></param>
        /// <param name="validationContext"></param>
        /// <returns></returns>
        protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
        {
            int counter = 0;

            //Check for every property
            foreach (var propertyName in _propertyNames)
            {
                //Get the property and its value
                var property = validationContext.ObjectType.GetProperty(propertyName);
                var propertyValue = property?.GetValue(validationContext.ObjectInstance);

                //Return an error message if too many properties were provided
                if (propertyValue is not string && propertyValue != null || propertyValue is string str && !string.IsNullOrWhiteSpace(str))
                {
                    if (++counter > 1)
                    {
                        return new ValidationResult($"Only one of the following must be provided: {string.Join(", ", _propertyNames)}");
                    }
                }
            }

            //Return success if only one value is present
            if (counter == 1)
            {
                return ValidationResult.Success;
            }

            //Return an error message if no property was provided
            return new ValidationResult($"One of the following must be provided: {string.Join(", ", _propertyNames)}");
        }
    }
}
