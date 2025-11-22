using KAZABUILD.Domain.Entities.Components.Components;
using KAZABUILD.Domain.Enums;
using System.Linq.Expressions;

namespace KAZABUILD.Application.Helpers
{
    /// <summary>
    /// Helper that contains functions used to simplify build generation.
    /// </summary>
    public static class BuildGenerationHelper
    {
        /// <summary>
        /// Calculates minimum and maximum allocated budget to a component.
        /// </summary>
        /// <param name="ratio"></param>
        /// <param name="totalRatio"></param>
        /// <param name="minBudget"></param>
        /// <param name="maxBudget"></param>
        /// <returns></returns>
        public static (float Min, float Max) AllocateBudget(float ratio, float totalRatio, float minBudget, float maxBudget)
        {
            float baseAmount = ratio / totalRatio;
            float min = baseAmount * minBudget * 0.98f;
            float max = baseAmount * maxBudget * 1.02f;
            return (min, max);
        }

        /// <summary>
        /// Dictionaries containing score adjustments for components.
        /// Follows this metric:
        /// 5 - extremely necessary
        /// 4 - really necessary
        /// 3 - necessary
        /// 2 - can be just alright
        /// 1 - anything will suffice
        /// </summary>
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
            ["Reliability"] = new(gpu: 0, cpu: 0, memory: 5, storage: 5, monitor: 0, cooler: 0),
            ["Quiet Operation"] = new(gpu: 5, cpu: 1, memory: 5, storage: 5, monitor: 5, cooler: 1),
            ["Strong Graphics"] = new(gpu: 1, cpu: 5, memory: 0, storage: 0, monitor: 4, cooler: 4),
            ["Fast Multitasking"] = new(gpu: 3, cpu: 0, memory: 0, storage: 0, monitor: 0, cooler: 0),
            ["Looks"] = new(gpu: 0, cpu: 0, memory: 0, storage: 0, monitor: 3, cooler: 0)
        };

        /// <summary>
        /// Additional model for assigning the adjustments.
        /// </summary>
        /// <param name="gpu"></param>
        /// <param name="cpu"></param>
        /// <param name="memory"></param>
        /// <param name="storage"></param>
        /// <param name="monitor"></param>
        /// <param name="cooler"></param>
        public class ComponentAdjustment(int gpu, int cpu, int memory, int storage, int monitor, int cooler)
        {
            public readonly int gpu = gpu;
            public readonly int cpu = cpu;
            public readonly int memory = memory;
            public readonly int storage = storage;
            public readonly int monitor = monitor;
            public readonly int cooler = cooler;
        }

        /// <summary>
        /// Additional entity framework query extension method for sorting based on a conditional.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <typeparam name="TKey"></typeparam>
        /// <param name="source"></param>
        /// <param name="condition"></param>
        /// <param name="keySelector"></param>
        /// <returns></returns>
        public static IOrderedQueryable<T> OrderByIf<T, TKey>(this IQueryable<T> source, bool condition, Expression<Func<T, TKey>> keySelector)
        {
            return condition ? source.OrderBy(keySelector) : (IOrderedQueryable<T>)source;
        }

        /// <summary>
        /// Additional entity framework query extension method for sorting in descending order based on a conditional.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <typeparam name="TKey"></typeparam>
        /// <param name="source"></param>
        /// <param name="condition"></param>
        /// <param name="keySelector"></param>
        /// <returns></returns>
        public static IOrderedQueryable<T> OrderByDescendingIf<T, TKey>(this IQueryable<T> source, bool condition, Expression<Func<T, TKey>> keySelector)
        {
            return condition ? source.OrderByDescending(keySelector) : (IOrderedQueryable<T>)source;
        }

        /// <summary>
        /// Additional entity framework query extension method for applying secondary sorting based on a conditional.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <typeparam name="TKey"></typeparam>
        /// <param name="source"></param>
        /// <param name="condition"></param>
        /// <param name="keySelector"></param>
        /// <returns></returns>
        public static IOrderedQueryable<T> ThenByIf<T, TKey>(this IOrderedQueryable<T> source, bool condition, Expression<Func<T, TKey>> keySelector)
        {
            return condition ? source.ThenBy(keySelector) : source;
        }

        /// <summary>
        /// Additional entity framework query extension method for applying secondary sorting in descending order based on a conditional.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <typeparam name="TKey"></typeparam>
        /// <param name="source"></param>
        /// <param name="condition"></param>
        /// <param name="keySelector"></param>
        /// <returns></returns>
        public static IOrderedQueryable<T> ThenByDescendingIf<T, TKey>(this IOrderedQueryable<T> source, bool condition, Expression<Func<T, TKey>> keySelector)
        {
            return condition ? source.ThenByDescending(keySelector) : source;
        }
    }
}
