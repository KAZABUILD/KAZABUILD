using System.ComponentModel.DataAnnotations;

namespace KAZABUILD.Domain.ValueObjects
{
    public class Address
    {
        [Required]
        [StringLength(50)]
        public string Country { get; set; } = default!;

        [StringLength(50)]
        public string? Province { get; set; }

        [Required]
        [StringLength(50)]
        public string City { get; set; } = default!;

        [Required]
        [StringLength(50)]
        public string Street { get; set; } = default!;

        [Required]
        [StringLength(8)]
        public string StreetNumber { get; set; } = default!;

        [Required]
        [StringLength(8)]
        public string PostalCode { get; set; } = default!;

        [StringLength(8)]
        public string? ApartmentNumber { get; set; }
    }
}
