using Microsoft.AspNetCore.Mvc;

namespace KAZABUILD.API.Controllers
{
    public class ForumPostsController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
