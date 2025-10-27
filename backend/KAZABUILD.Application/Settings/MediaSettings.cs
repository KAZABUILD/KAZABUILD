namespace KAZABUILD.Application.Settings
{
    public class MediaSettings
    {
        public string StorageRootPath { get; set; } = default!;
        public int MaxFileSizeMB { get; set; } = 25;
        public List<string> AllowedFileTypes { get; set; } = [];
    }
}
