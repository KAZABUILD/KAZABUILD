using Microsoft.AspNetCore.Mvc;

namespace KAZABUILD.API.Controllers.Components
{
    //Controller for User related endpoints
    [ApiController]
    [Route("[controller]")]
    public class GPUsController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
