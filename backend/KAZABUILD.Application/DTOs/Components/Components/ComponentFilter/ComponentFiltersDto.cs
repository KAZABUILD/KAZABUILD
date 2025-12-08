namespace KAZABUILD.Application.DTOs.Components.Components.ComponentFilter
{
    public enum FilterFieldType
    {
        String,
        Numeric,
        Date,
        Boolean
    }

    /// <summary>
    /// Represents a filter field used to specify criteria for filtering data.
    /// Can be either a string, a numeric, a date, or a boolean field.
    /// </summary>
    public class FilterFieldDto
    {
        //Type of the field
        public FilterFieldType Type { get; set; }

        //List of all possible string values
        public List<string>? StringValues { get; set; }

        //Numeric ranges
        public decimal? MinNumeric { get; set; }
        public decimal? MaxNumeric { get; set; }

        // Date ranges
        public DateTime? MinDate { get; set; }
        public DateTime? MaxDate { get; set; }

        //Whether a boolean field has true or false values
        public bool? HasTrue { get; set; }
        public bool? HasFalse { get; set; }
    }

    /// <summary>
    /// The actual list of filters returned to the user.
    /// </summary>
    public class ComponentFiltersDto
    {
        public Dictionary<string, FilterFieldDto> Fields { get; set; } = new();
    }
}
