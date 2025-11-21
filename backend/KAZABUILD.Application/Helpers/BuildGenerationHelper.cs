using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Enums;

namespace KAZABUILD.Application.Helpers
{
    public static class BuildGenerationHelper
    {
        public static (float Min, float Max) AllocateBudget(float score, float totalScore, float minBudget, float maxBudget)
        {
            float baseAmount = score / totalScore;
            float min = baseAmount * minBudget * 0.98f;
            float max = baseAmount * maxBudget * 1.02f;
            return (min, max);
        }

        public static Dictionary<string, ComponentAdjustment> HobbyAdjustments = new()
        {
            ["Gaming"] = new(gpu: 5, cpu: 4, memory: 4, storage: 3, monitor: 3, cooler:  3),
            ["Video Editing"] = new(gpu: 4, cpu: 4, memory: 5, storage: 5, monitor: 4, cooler:  4),
            ["3D Modeling"] = new(gpu: 5, cpu: 4, memory: 4, storage: 4, monitor: 3, cooler:  4),
            ["Graphic Design"] = new(gpu: 3, cpu: 3, memory: 3, storage: 4, monitor: 4, cooler:  2),
            ["Livestreaming"] = new(gpu: 5, cpu: 5, memory: 4, storage: 4, monitor: 3, cooler:  4),
            ["Music production"] = new(gpu: 2, cpu: 3, memory: 3, storage: 4, monitor: 2, cooler:  2),
            ["Video Recording"] = new(gpu: 3, cpu: 4, memory: 4, storage: 5, monitor: 3, cooler:  2),
            ["Coding"] = new(gpu: 3, cpu: 4, memory: 4, storage: 5, monitor: 2, cooler:  2),
            ["Drawing"] = new(gpu: 2, cpu: 3, memory: 3, storage: 4, monitor: 2, cooler:  2),
            ["3D printing"] = new(gpu: 3, cpu: 4, memory: 4, storage: 4, monitor: 2, cooler:  3),
            ["Social Media Activities"] = new(gpu: 3, cpu: 3, memory: 3, storage: 4, monitor: 3, cooler:  3),
            ["Sports"] = new(gpu: 2, cpu: 2, memory: 2, storage: 4, monitor: 1, cooler:  1),
            ["Sim Racing"] = new(gpu: 5, cpu: 5, memory: 5, storage: 4, monitor: 4, cooler:  4),
            ["Watching Movies & Shows"] = new(gpu: 2, cpu: 3, memory: 2, storage: 3, monitor: 3, cooler:  1),
            ["Browsing The Internet"] = new(gpu: 2, cpu: 3, memory: 2, storage: 2, monitor: 1, cooler:  1)
        };
        public static Dictionary<string, ComponentAdjustment> UsageAdjustments = new()
        {
            ["General Everyday Use"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 2, cooler:  1),
            ["Gaming"] = new(gpu: 5, cpu: 4, memory: 4, storage: 3, monitor: 3, cooler:  3),
            ["Work"] = new(gpu: 2, cpu: 4, memory: 4, storage: 4, monitor: 3, cooler:  2),
            ["School"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 2, cooler:  1),
            ["Video Editing"] = new(gpu: 4, cpu: 4, memory: 5, storage: 5, monitor: 4, cooler:  4),
            ["3D Art"] = new(gpu: 5, cpu: 4, memory: 4, storage: 4, monitor: 3, cooler:  4),
            ["Graphic Design"] = new(gpu: 3, cpu: 3, memory: 3, storage: 4, monitor: 4, cooler:  2),
            ["Livestreaming"] = new(gpu: 5, cpu: 5, memory: 4, storage: 4, monitor: 3, cooler:  4),
            ["Multi-cast Streaming"] = new(gpu: 5, cpu: 5, memory: 5, storage: 4, monitor: 3, cooler:  4),
            ["Music Production"] = new(gpu: 2, cpu: 3, memory: 3, storage: 4, monitor: 2, cooler:  2),
            ["Video Recording"] = new(gpu: 3, cpu: 4, memory: 4, storage: 5, monitor: 3, cooler:  2),
            ["Software Development"] = new(gpu: 3, cpu: 4, memory: 4, storage: 5, monitor: 2, cooler:  2),
            ["Game Development"] = new(gpu: 5, cpu: 4, memory: 4, storage: 4, monitor: 3, cooler:  3),
            ["Data Science"] = new(gpu: 4, cpu: 5, memory: 5, storage: 5, monitor: 3, cooler:  3),
            ["3D Printing"] = new(gpu: 3, cpu: 4, memory: 4, storage: 4, monitor: 2, cooler:  3),
            ["Computer-Aided Design"] = new(gpu: 5, cpu: 5, memory: 5, storage: 4, monitor: 4, cooler:  4),
            ["Social Media"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 3, cooler:  2),
            ["Server Hosting"] = new(gpu: 1, cpu: 5, memory: 5, storage: 5, monitor: 1, cooler:  4),
            ["AI Training"] = new(gpu: 5, cpu: 5, memory: 5, storage: 5, monitor: 2, cooler:  4),
            ["Data Management"] = new(gpu: 1, cpu: 4, memory: 4, storage: 5, monitor: 2, cooler:  2)
        };
        public static Dictionary<string, ComponentAdjustment> JobAdjustments = new()
        {
            ["Still In School"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 2, cooler:  1),
            ["Office Work"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 2, cooler:  1),
            ["Art"] = new(gpu: 4, cpu: 3, memory: 4, storage: 4, monitor: 4, cooler:  2),
            ["Engineering"] = new(gpu: 5, cpu: 5, memory: 5, storage: 4, monitor: 4, cooler:  4),
            ["Cybersecurity"] = new(gpu: 3, cpu: 4, memory: 4, storage: 4, monitor: 2, cooler:  2),
            ["Software Development"] = new(gpu: 3, cpu: 4, memory: 4, storage: 5, monitor: 2, cooler:  2),
            ["Data Science"] = new(gpu: 5, cpu: 5, memory: 5, storage: 5, monitor: 3, cooler:  3),
            ["Game Development"] = new(gpu: 5, cpu: 4, memory: 4, storage: 4, monitor: 4, cooler:  3),
            ["Music Production"] = new(gpu: 2, cpu: 3, memory: 3, storage: 4, monitor: 2, cooler:  2),
            ["AI Research"] = new(gpu: 5, cpu: 5, memory: 5, storage: 5, monitor: 3, cooler:  4),
            ["Real Estate"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 2, cooler:  1),
            ["Architecture"] = new(gpu: 5, cpu: 4, memory: 4, storage: 4, monitor: 4, cooler:  3),
            ["IT"] = new(gpu: 3, cpu: 4, memory: 4, storage: 4, monitor: 2, cooler:  2),
            ["Telecommunication"] = new(gpu: 3, cpu: 4, memory: 4, storage: 4, monitor: 2, cooler:  2),
            ["Content Creation"] = new(gpu: 4, cpu: 4, memory: 4, storage: 5, monitor: 4, cooler:  3),
            ["Livestreaming"] = new(gpu: 5, cpu: 5, memory: 4, storage: 4, monitor: 3, cooler:  4),
            ["Healthcare"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 2, cooler:  1),
            ["Scientific Research"] = new(gpu: 5, cpu: 5, memory: 5, storage: 5, monitor: 3, cooler:  3),
            ["Business"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 2, cooler:  1),
            ["Personal Use"] = new(gpu: 2, cpu: 3, memory: 3, storage: 3, monitor: 2, cooler:  1)
        };
        public static Dictionary<string, ComponentAdjustment> PriorityAdjustments = new()
        {
            ["Reliability"] = new(gpu: 0, cpu: 0, memory: 0, storage: 0, monitor: 0, cooler: 0),
            ["Quiet Operation"] = new(gpu: 0, cpu: 0, memory: 0, storage: 0, monitor: 0, cooler: 0),
            ["Strong Graphics"] = new(gpu: 0, cpu: 0, memory: 0, storage: 0, monitor: 0, cooler: 0),
            ["Fast Multitasking"] = new(gpu: 0, cpu: 0, memory: 0, storage: 0, monitor: 0, cooler: 0),
            ["Looks"] = new(gpu: 0, cpu: 0, memory: 0, storage: 0, monitor: 0, cooler: 0)
        };

        public class ComponentAdjustment(int gpu, int cpu, int memory, int storage, int monitor, int cooler)
        {
            public readonly int gpu = gpu;
            public readonly int cpu = cpu;
            public readonly int memory = memory;
            public readonly int storage = storage;
            public readonly int monitor = monitor;
            public readonly int cooler = cooler;
        }
    }
}
