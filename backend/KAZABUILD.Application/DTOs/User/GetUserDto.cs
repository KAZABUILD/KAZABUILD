using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace KAZABUILD.Application.DTOs.User
{
    public class GetUserDto
    {
        public bool Paging = false;

        [MinLength(1, ErrorMessage = "Page number must be greater than 0")]
        public int Page { get; set; }

        [MinLength(1, ErrorMessage = "Page length must be greater than 0")]
        public int PageLength { get; set; }

        public string? Query { get; set; } = "";

        public string? OrderBy { get; set; }

        public string SortDirection { get; set; } = "asc";
    }
}
