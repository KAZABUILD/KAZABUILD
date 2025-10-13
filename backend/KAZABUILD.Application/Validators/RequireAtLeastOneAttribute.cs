using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Validators
{
    //Validator for checking if at least one of multiple attributes is present in an object
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = false)]
    public class RequireAtLeastOneAttribute(params string[] propertyNames) : ValidationAttribute
    {
        //Store the name of properties to validate
        private readonly string[] _propertyNames = propertyNames;

        //Method for checking the validity
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
