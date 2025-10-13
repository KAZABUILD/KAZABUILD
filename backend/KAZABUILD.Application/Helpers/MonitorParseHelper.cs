namespace KAZABUILD.Application.Helpers
{
    /// <summary>
    /// Helper class for parsing aspect ratio and viewing angles in the monitor. 
    /// </summary>
    public class MonitorParseHelper
    {
        /// <summary>
        /// Parsing function for Aspect Ratios in the MonitorComponent.
        /// </summary>
        /// <param name="ratio"></param>
        /// <returns>Returns either the parsed aspect ratios or a null value.</returns>
        public static double? ParseAspectRatio(string? ratio)
        {
            //Check if the string is valid
            if (string.IsNullOrWhiteSpace(ratio)) return null;

            //Split by the ":" symbol and check if there are two parts created
            var parts = ratio.Split(':');
            if (parts.Length != 2) return null;

            //Try parsing parts of the aspect ratio into doubles and return them as their ratio
            if (double.TryParse(parts[0], out var w) && double.TryParse(parts[1], out var h) && h != 0)
                return w / h;

            //Return null if parsing failed
            return null;
        }

        /// <summary>
        /// Parsing function for Viewing Angles in the MonitorComponent.
        /// </summary>
        /// <param name="angle"></param>
        /// <returns>Returns either the parsed viewing angles or a null values.</returns>
        public static double? ParseViewingAngle(string? angle)
        {
            //Check if the string is valid
            if (string.IsNullOrWhiteSpace(angle)) return null;

            //Remove the non numerical values
            var parsed = angle.Replace("H", string.Empty).Replace("°", string.Empty).Replace("V", string.Empty);

            //Split by the "x" symbol and check if there are two parts created
            var parts = parsed.Split('x', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length != 2) return null;

            //Try parsing the angle into doubles and return them as their multiplication
            if (double.TryParse(parts[0], out var h) && double.TryParse(parts[1], out var w))
                return w * h;

            //Return null if parsing failed
            return null;
        }
    }
}
