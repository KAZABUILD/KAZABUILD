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
            ["Gaming"] = new(gpu: 0.015f, cpu: 0.0075f, memory: 0.0075f, storage: -0.01f, monitor: -0.01f, cooler: -0.01f, powerSupply: 0.0f),
            ["Video Editing"] = new(gpu: -0.005f, cpu: -0.005f, memory: 0.01f, storage: 0.01f, monitor: -0.005f, cooler: -0.005f, powerSupply: 0.0f),
            ["3D Modeling"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Graphic Design"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Livestreaming"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Music production"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Video Recording"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Coding"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Drawing"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["3D printing"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Social Media Activities"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Sports"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Sim Racing"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Watching Movies & Shows"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Browsing The Internet"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f)
        };
        public static Dictionary<string, ComponentAdjustment> UsageAdjustments = new()
        {
            ["General Everyday Use"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Gaming"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Work"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["School"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Video Editing"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["3D Art"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Graphic Design"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Livestreaming"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Multi-cast Streaming"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Music Production"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Video Recording"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Software Development"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Game Development"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Data Science"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["3D Printing"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Computer-Aided Design"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Social Media"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Server Hosting"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["AI Training"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Data Management"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f)
        };
        public static Dictionary<string, ComponentAdjustment> JobAdjustments = new()
        {
            ["Still In School"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Office Work"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Art"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Engineering"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Cyber-Security"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Software Development"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Data Science"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Game Development"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Music Production"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["AI Research"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Real Estate"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Architecture"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["IT"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Telecommunication"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Content Creation"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Livestreaming"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Healthcare"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Scientific Research"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Business"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Personal Use"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f)
        };
        public static Dictionary<string, ComponentAdjustment> PriorityAdjustments = new()
        {
            ["Reliability"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Quiet Operation"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Strong Graphics"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Fast Multitasking"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f),
            ["Looks"] = new(gpu: 0.0f, cpu: 0.0f, memory: 0.0f, storage: 0.0f, monitor: 0.0f, cooler: 0.0f, powerSupply: 0.0f)
        };

        public class ComponentAdjustment(float gpu, float cpu, float memory, float storage, float monitor, float cooler, float powerSupply)
        {
            public readonly float gpu = gpu;
            public readonly float cpu = cpu;
            public readonly float memory = memory;
            public readonly float storage = storage;
            public readonly float monitor = monitor;
            public readonly float cooler = cooler;
            public readonly float powerSupply = powerSupply;
        }
    }
}
