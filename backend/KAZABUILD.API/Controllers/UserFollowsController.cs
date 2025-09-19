using Microsoft.AspNetCore.Mvc;

namespace KAZABUILD.API.Controllers
{
    public class UserFollowsController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
