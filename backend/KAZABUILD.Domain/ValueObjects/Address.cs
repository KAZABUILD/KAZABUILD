using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.ValueObjects
{
    public class Address
    {
        [StringLength(50)]
        public string? Country { get; set; }

        [StringLength(50)]
        public string? Province { get; set; }

        [StringLength(50)]
        public string? City { get; set; }

        [StringLength(50)]
        public string? Street { get; set; }

        [StringLength(8)]
        public string? StreetNumber { get; set; }

        [StringLength(8)]
        public string? PostalCode { get; set; }

        [StringLength(8)]
        public string? ApartmentNumber { get; set; }
    }
}
