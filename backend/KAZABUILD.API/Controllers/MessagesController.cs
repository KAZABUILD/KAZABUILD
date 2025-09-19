using Microsoft.AspNetCore.Mvc;

namespace KAZABUILD.API.Controllers
{
    public class MessagesController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
