using System.Text;

namespace KAZABUILD.Application.Helpers
{
    /// <summary>
    /// Helper class for converting non-guid id's into guid for the logger.
    /// </summary>
    public class GuidConversionHelper
    {
        /// <summary>
        /// Function for converting from as string to a consistent guid.
        /// </summary>
        /// <param name="input"></param>
        /// <returns>The guid representation of the provided string.</returns>
        public static Guid FromString(string input)
        {
            //Get the string into a byte array form
            byte[] bytes = Encoding.UTF8.GetBytes(input);

            //Resize the bytes array is the size of a guid
            Array.Resize(ref bytes, 16);

            //Return the string as a guid
            return new Guid(bytes);
        }

        /// <summary>
        /// Function for converting back into a string from a guid.
        /// Running the function for a guid that was randomly generated will return nonsense.
        /// </summary>
        /// <param name="guid"></param>
        /// <returns>The original string from the guid provided.</returns>
        public static string FromGuid(Guid guid)
        {
            //Get the guid into a byte form
            byte[] bytes = guid.ToByteArray();

            //Remove trailing zeroes that came from Array.Resize and return the string in its original form
            return Encoding.UTF8.GetString(bytes).TrimEnd('\0');
        }
    }
}
