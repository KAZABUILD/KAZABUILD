using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Application.DTOs.Components.ComponentCompatibility
{
    public class GetComponentCompatibilityDto
    {
        //Filter By fields
        public Guid? ComponentId { get; set; }

        public Guid? CompatibleComponentId { get; set; }

        //Paging related fields
        public bool Paging = false;

        [MinLength(1, ErrorMessage = "Page number must be greater than 0")]
        public int? Page { get; set; }

        [MinLength(1, ErrorMessage = "Page length must be greater than 0")]
        public int? PageLength { get; set; }

        //Query search string
        public string? Query { get; set; } = "";

        //Sorting related fields
        public string? OrderBy { get; set; }

        public string SortDirection { get; set; } = "asc";
    }
}
