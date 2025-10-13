using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.Validators
{
    //Validator for checking if the string object is a relative path (starts with "/")
    public class RelativePathAttribute : ValidationAttribute
    {
        //Method for checking the validity
        protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
        {
            //If null return a success since that should be verifies with [Required]
            if (value is not string path || string.IsNullOrWhiteSpace(path))
                return ValidationResult.Success;

            //Check if the path can be made into an URI and if it it starts with a '/'
            if (Uri.TryCreate(path, UriKind.Relative, out _) && path.StartsWith('/'))
                return ValidationResult.Success;

            //Return a validation error if the string is not a relative path
            return new ValidationResult("The path string must be a valid relative path starting with a '/'.");
        }
    }
}
