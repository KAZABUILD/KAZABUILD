using Microsoft.AspNetCore.Mvc;

namespace KAZABUILD.API.Controllers
{
    public class UserPreferencesController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
