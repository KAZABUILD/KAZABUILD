using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Validators
{
    /// <summary>
    /// Validator for checking if at least one of multiple attributes is present in an object.
    /// </summary>
    /// <param name="propertyNames"></param>
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = false)]
    public class RequireAtLeastOneAttribute(params string[] propertyNames) : ValidationAttribute
    {
        //Store names of properties to validate
        private readonly string[] _propertyNames = propertyNames;

        /// <summary>
        /// Checks if at least one of the objects was provided.
        /// </summary>
        /// <param name="value"></param>
        /// <param name="validationContext"></param>
        /// <returns></returns>
        protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
        {
            //Check for every property
            foreach (var propertyName in _propertyNames)
            {
                //Get the property and its value
                var property = validationContext.ObjectType.GetProperty(propertyName);
                var propertyValue = property?.GetValue(validationContext.ObjectInstance);

                //Return success if value is present
                if (propertyValue is not string && propertyValue != null || propertyValue is string str && !string.IsNullOrWhiteSpace(str))
                {
                    return ValidationResult.Success;
                }
            }

            //Return an error message if validation fails
            return new ValidationResult($"At least one of the following must be provided: {string.Join(", ", _propertyNames)}");
        }
    }
}
