/// This file defines the core data models for the KazaBuild application,
/// representing all aspects of PC components and their related data.
///
/// It includes:
/// - Enums for categorizing component types (`ComponentType`, `SubComponentType`).
/// - Abstract base classes for components (`BaseComponent`) and sub-components
///   (`BaseSubComponent`) to enforce a common structure.
/// - Concrete data models for each specific type of PC part, such as `CPUComponent`,
///   `GPUComponent`, `MotherboardComponent`, etc., detailing their unique specifications.
/// - Supporting data models for peripheral information like pricing (`ComponentPrice`),
///   user/professional reviews (`ComponentReview`), color variants (`ComponentVariant`),
///   and compatibility rules (`ComponentCompatibility`).
///
/// All models are designed to be immutable (`@immutable`) to ensure data integrity
/// and predictability throughout the application's state management.
library;

import 'package:flutter/foundation.dart';
import 'dart:math';

// enums
/// Represents the main categories of PC components that can be selected or viewed.
/// This is used to differentiate between component types throughout the app.
enum ComponentType {
  cpu,
  gpu,
  motherboard,
  ram,
  storage,
  psu,
  cooler,
  caseFan,
  pcCase,
  monitor,
}

/// Represents the types of sub-components that can be part of a main component.
enum SubComponentType {
  coolerSocket,
  integratedGraphics,
  m2Slot,
  onboardEthernet,
  pcieSlot,
  port,
}

/// Defines the types of physical ports on a component.
enum PortType { usb, hdmi, displayPort }

// domain models

/// Represents a globally defined color option that can be referenced by components.
/// This allows for consistent color management across the database.
@immutable
class KazaColor {
  /// The hexadecimal color code (e.g., "#FFFFFF").
  final String colorCode;

  /// The human-readable name of the color (e.g., "Matte Black").
  final String colorName;

  /// The timestamp when this entry was created in the database.
  final DateTime databaseEntryAt;

  /// The timestamp of the last modification to this entry.
  final DateTime lastEditedAt;

  /// An optional note for internal use.
  final String? note;

  const KazaColor({
    required this.colorCode,
    required this.colorName,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    this.note,
  });
}

/// Represents a specific variant of a main component.
/// This is typically used for variations in color or other minor physical attributes
/// that might affect price or availability.
@immutable
class ComponentVariant {
  /// The unique identifier for this variant.
  final String id;

  /// The color code associated with this variant, linking to a `KazaColor`.
  final String colorCode;

  /// Indicates whether this specific variant is currently available for purchase.
  final bool? isAvailable;

  /// The price difference relative to the base component price. Can be positive or negative.
  final double? additionalPrice;

  /// The timestamp when this entry was created in the database.
  final DateTime databaseEntryAt;

  /// The timestamp of the last modification to this entry.
  final DateTime lastEditedAt;
  final String? note;

  const ComponentVariant({
    required this.id,
    required this.colorCode,
    this.isAvailable,
    this.additionalPrice,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    this.note,
  });
}

/// Defines a compatibility relationship between two components in the database.
/// This is used by the compatibility checker to validate a user's build.
@immutable
class ComponentCompatibility {
  final String id;
  final String componentId;
  final String compatibleComponentId;
  final DateTime databaseEntryAt;
  final DateTime lastEditedAt;
  final String? note;

  const ComponentCompatibility({
    required this.id,
    required this.componentId,
    required this.compatibleComponentId,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    this.note,
  });
}

/// Represents a price point for a component from a specific vendor at a specific time.
@immutable
class ComponentPrice {
  /// The unique identifier for this price entry.
  final String id;

  /// The URL of the product page where the price was found.
  final String sourceUrl;

  /// The ID of the component this price belongs to.
  final String componentId;

  /// The name of the vendor or store (e.g., "Amazon", "Newegg").
  final String vendorName;

  /// The timestamp when the price was fetched.
  final DateTime fetchedAt;

  /// The price of the component.
  final double price;

  /// The currency of the price (e.g., "USD", "EUR").
  final String currency;

  /// The timestamp when this entry was created in the database.
  final DateTime databaseEntryAt;

  /// The timestamp of the last modification to this entry.
  final DateTime lastEditedAt;

  /// An optional note for internal use.
  final String? note;

  const ComponentPrice({
    required this.id,
    required this.sourceUrl,
    required this.componentId,
    required this.vendorName,
    required this.fetchedAt,
    required this.price,
    required this.currency,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    this.note,
  });
}

/// Represents a user-submitted or professional review for a component.
@immutable
class ComponentReview {
  /// The unique identifier for this review.
  final String id;

  /// The URL where the original review can be found.
  final String sourceUrl;

  /// The ID of the component being reviewed.
  final String componentId;

  /// The name of the person or entity that wrote the review.
  final String reviewerName;

  /// The timestamp when the review data was fetched.
  final DateTime fetchedAt;

  /// The original creation date of the review.
  final DateTime createdAt;

  /// The rating given in the review, typically on a scale (e.g., 1-100).
  final double rating;

  /// The full text content of the review.
  final String reviewText;

  /// The timestamp when this entry was created in the database.
  final DateTime databaseEntryAt;

  /// The timestamp of the last modification to this entry.
  final DateTime lastEditedAt;

  /// An optional note for internal use.
  final String? note;

  const ComponentReview({
    required this.id,
    required this.sourceUrl,
    required this.componentId,
    required this.reviewerName,
    required this.fetchedAt,
    required this.createdAt,
    required this.rating,
    required this.reviewText,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    this.note,
  });
}

/// Links a main component to one of its sub-component parts.
@immutable
class ComponentPart {
  final String id;
  final String componentId;
  final String subComponentId;
  final int amount;
  final DateTime databaseEntryAt;
  final DateTime lastEditedAt;
  final String? note;

  const ComponentPart({
    required this.id,
    required this.componentId,
    required this.subComponentId,
    required this.amount,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    this.note,
  });
}

/// Represents a link between a sub-component and another sub-component.
/// This allows for creating nested or composite parts.
@immutable
class SubComponentPart {
  final String id;
  final String mainSubComponentId;
  final String subComponentId;
  final int amount;
  final DateTime databaseEntryAt;
  final DateTime lastEditedAt;
  final String? note;

  const SubComponentPart({
    required this.id,
    required this.mainSubComponentId,
    required this.subComponentId,
    required this.amount,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    this.note,
  });
}

/// The abstract base class for all sub-components.
@immutable
abstract class BaseSubComponent {
  /// The unique identifier for this sub-component.
  final String id;

  /// The display name of the sub-component.
  final String name;

  /// The type of the sub-component, from the `SubComponentType` enum.
  final SubComponentType type;

  /// The timestamp when this entry was created in the database.
  final DateTime databaseEntryAt;

  /// The timestamp of the last modification to this entry.
  final DateTime lastEditedAt;

  /// An optional note for internal use.
  final String? note;

  const BaseSubComponent({
    required this.id,
    required this.name,
    required this.type,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    this.note,
  });
}

/// A sub-component representing a cooler socket type (e.g., AM4, LGA1700).
@immutable
class CoolerSocketSubComponent extends BaseSubComponent {
  /// The specific socket identifier (e.g., "AM4", "LGA1700").
  final String socketType;

  const CoolerSocketSubComponent({
    required super.id,
    required super.name,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required this.socketType,
    super.note,
  }) : super(type: SubComponentType.coolerSocket);
}

/// A sub-component representing the integrated graphics processor (iGPU) within a CPU.
@immutable
class IntegratedGraphicsSubComponent extends BaseSubComponent {
  /// The model name of the integrated graphics (e.g., "Intel UHD Graphics 770").
  final String? model;

  /// The base clock speed of the iGPU in MHz.
  final int baseClockSpeed;

  /// The maximum boost clock speed of the iGPU in MHz.
  final int boostClockSpeed;

  /// The number of execution units or cores in the iGPU.
  final int coreCount;

  const IntegratedGraphicsSubComponent({
    required super.id,
    required super.name,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    this.model,
    required this.baseClockSpeed,
    required this.boostClockSpeed,
    required this.coreCount,
    super.note,
  }) : super(type: SubComponentType.integratedGraphics);
}

/// A sub-component representing an M.2 slot on a motherboard.
@immutable
class M2SlotSubComponent extends BaseSubComponent {
  /// The physical size of the M.2 slot (e.g., "2280", "22110").
  final String size;

  /// The key type of the slot (e.g., "M Key", "B Key"), which determines compatibility.
  final String keyType;

  /// The data interface used by the slot (e.g., "PCIe 4.0 x4", "SATA").
  final String interface;

  const M2SlotSubComponent({
    required super.id,
    required super.name,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required this.size,
    required this.keyType,
    required this.interface,
    super.note,
  }) : super(type: SubComponentType.m2Slot);
}

/// A sub-component representing an onboard Ethernet port.
@immutable
class OnboardEthernetSubComponent extends BaseSubComponent {
  /// The maximum speed of the Ethernet port (e.g., "1 Gbit/s", "2.5 Gbit/s").
  final String speed;

  /// The manufacturer and model of the network controller chip.
  final String controller;

  const OnboardEthernetSubComponent({
    required super.id,
    required super.name,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required this.speed,
    required this.controller,
    super.note,
  }) : super(type: SubComponentType.onboardEthernet);
}

/// A sub-component representing a PCIe slot on a motherboard.
@immutable
class PCIeSlotSubComponent extends BaseSubComponent {
  /// The PCIe generation (e.g., "4.0", "5.0").
  final String gen;

  /// The number of lanes the slot provides (e.g., "x16", "x4").
  final String lanes;

  const PCIeSlotSubComponent({
    required super.id,
    required super.name,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required this.gen,
    required this.lanes,
    super.note,
  }) : super(type: SubComponentType.pcieSlot);
}

/// A sub-component representing a generic port (e.g., USB, HDMI).
@immutable
class PortSubComponent extends BaseSubComponent {
  /// The type of the port, from the `PortType` enum.
  final PortType portType;

  const PortSubComponent({
    required super.id,
    required super.name,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required this.portType,
    super.note,
  }) : super(type: SubComponentType.port);
}

/// The abstract base class for all main PC components (CPU, GPU, etc.).
@immutable
abstract class BaseComponent {
  /// The unique identifier for this component.
  final String id;

  /// The full product name of the component.
  final String name;

  /// The name of the manufacturer (e.g., "Intel", "NVIDIA", "ASUS").
  final String manufacturer;

  /// The official release date of the component.
  final DateTime? release;

  /// The type of the component, from the `ComponentType` enum.
  final ComponentType type;

  /// The timestamp when this entry was created in the database.
  final DateTime databaseEntryAt;

  /// The timestamp of the last modification to this entry.
  final DateTime lastEditedAt;

  /// An optional note for internal use.
  final String? note;

  /// A URL to an image of the component.
  final String imageUrl;

  /// A list of `ComponentPrice` objects from various vendors.
  final List<ComponentPrice> prices;

  /// A list of `ComponentVariant` objects, such as different colors.
  final List<ComponentVariant> variants;

  /// A list of `ComponentReview` objects for this component.
  final List<ComponentReview> reviews;

  /// A list of `ComponentPart` objects, linking to sub-components.
  final List<ComponentPart> parts;

  const BaseComponent({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.type,
    required this.databaseEntryAt,
    required this.lastEditedAt,
    required this.imageUrl,
    this.release,
    this.note,
    this.prices = const [],
    this.variants = const [],
    this.reviews = const [],
    this.parts = const [],
  });

  /// Calculates the lowest price from the list of available prices.
  double? get lowestPrice {
    if (prices.isEmpty) return null;
    return prices.map((p) => p.price).reduce(min);
  }

  /// Calculates the average rating from all reviews.
  /// Assumes original ratings are on a 1-100 scale and converts it to a 0-5 scale.
  double? get averageRating {
    if (reviews.isEmpty) return null;
    final totalRating = reviews.map((r) => r.rating).reduce((a, b) => a + b);
    final avg = totalRating / reviews.length;
    return avg / 20.0;
  }
}

/// Represents a PC Case component with its physical specifications.
@immutable
class CaseComponent extends BaseComponent {
  /// The motherboard form factors it supports (e.g., "ATX", "Micro-ATX").
  final String formFactor;

  /// Indicates if the case has a shroud to hide the power supply.
  final bool powerSupplyShrouded;

  /// The wattage of an included power supply, if any.
  final double? powerSupplyAmount;

  /// Indicates if the case has a transparent side panel (e.g., tempered glass).
  final bool hasTransparentSidePanel;

  /// The material of the side panel if it's transparent.
  final String? sidePanelType;

  /// The maximum length of a video card that can fit, in millimeters.
  final double maxVideoCardLength;

  /// The maximum height of a CPU cooler that can fit, in millimeters.
  final int maxCPUCoolerHeight;

  /// The number of internal 3.5" drive bays.
  final int internal35BayAmount;

  /// The number of internal 2.5" drive bays.
  final int internal25BayAmount;

  /// The number of external 3.5" drive bays.
  final int external35BayAmount;

  /// The number of external 5.25" drive bays (for optical drives).
  final int external525BayAmount;

  /// The number of expansion slots available for PCIe cards.
  final int expansionSlotAmount;

  /// The width of the case in millimeters.
  final double width;

  /// The height of the case in millimeters.
  final double height;

  /// The depth (length) of the case in millimeters.
  final double depth;

  /// The internal volume of the case in liters.
  final double volume;

  /// The weight of the case in kilograms.
  final double weight;

  /// Indicates if the case supports motherboards with rear-facing connectors.
  final bool supportsRearConnectingMotherboard;

  const CaseComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.formFactor,
    required this.powerSupplyShrouded,
    this.powerSupplyAmount,
    required this.hasTransparentSidePanel,
    this.sidePanelType,
    required this.maxVideoCardLength,
    required this.maxCPUCoolerHeight,
    required this.internal35BayAmount,
    required this.internal25BayAmount,
    required this.external35BayAmount,
    required this.external525BayAmount,
    required this.expansionSlotAmount,
    required this.width,
    required this.height,
    required this.depth,
    required this.volume,
    required this.weight,
    required this.supportsRearConnectingMotherboard,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.pcCase);
}

/// Represents a Case Fan component with its performance and physical characteristics.
@immutable
class CaseFanComponent extends BaseComponent {
  /// The size of the fan in millimeters (e.g., 120, 140).
  final double size;

  /// The number of fans included in the package.
  final int quantity;

  /// The minimum airflow of the fan in Cubic Feet per Minute (CFM).
  final double minAirflow;

  /// The maximum airflow of the fan in CFM.
  final double? maxAirflow;

  /// The minimum noise level in decibels (dBA) at the lowest speed.
  final double minNoiseLevel;

  /// The maximum noise level in dBA at the highest speed.
  final double? maxNoiseLevel;

  /// Indicates if the fan speed can be controlled via PWM.
  final bool pulseWidthModulation;

  /// The type of LED lighting, if any (e.g., "RGB", "ARGB").
  final String? ledType;

  /// The type of power connector (e.g., "3-pin", "4-pin PWM").
  final String? connectorType;

  /// How the fan's lighting or speed is controlled (e.g., "Motherboard", "Hub").
  final String controllerType;

  /// The static pressure of the fan, important for radiators and heatsinks.
  final double staticPressureAmount;

  /// The direction of airflow (e.g., "Intake", "Exhaust").
  final String flowDirection;

  const CaseFanComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.size,
    required this.quantity,
    required this.minAirflow,
    this.maxAirflow,
    required this.minNoiseLevel,
    this.maxNoiseLevel,
    required this.pulseWidthModulation,
    this.ledType,
    this.connectorType,
    required this.controllerType,
    required this.staticPressureAmount,
    required this.flowDirection,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.caseFan);
}

/// Represents a CPU Cooler, which can be air or water-cooled.
@immutable
class CoolerComponent extends BaseComponent {
  /// The minimum fan speed in RPM.
  final double? minFanRotationSpeed;

  /// The maximum fan speed in RPM.
  final double? maxFanRotationSpeed;

  /// The minimum noise level in decibels (dBA).
  final double? minNoiseLevel;

  /// The maximum noise level in decibels (dBA).
  final double? maxNoiseLevel;

  /// The height of the cooler in millimeters (for air coolers).
  final double height;

  /// Indicates if it's a liquid/water cooler.
  final bool isWaterCooled;

  /// The size of the radiator in millimeters (e.g., 240, 360) for water coolers.
  final double? radiatorSize;

  /// Indicates if the cooler can run without the fan at low loads.
  final bool canOperateFanless;

  /// The size of the fan(s) in millimeters.
  final double? fanSize;

  /// The number of fans included with the cooler.
  final int fanQuantity;

  const CoolerComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    this.minFanRotationSpeed,
    this.maxFanRotationSpeed,
    this.minNoiseLevel,
    this.maxNoiseLevel,
    required this.height,
    required this.isWaterCooled,
    this.radiatorSize,
    required this.canOperateFanless,
    this.fanSize,
    required this.fanQuantity,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.cooler);
}

/// Represents a Central Processing Unit (CPU) component.
@immutable
class CPUComponent extends BaseComponent {
  /// The product series (e.g., "Core i9", "Ryzen 7").
  final String series;

  /// The underlying microarchitecture (e.g., "Zen 4", "Raptor Lake").
  final String microarchitecture;

  /// The family of cores used (e.g., "Raphael").
  final String coreFamily;

  /// The physical socket type on the motherboard (e.g., "AM5", "LGA1700").
  final String socketType;

  /// The total number of physical cores.
  final int coreTotal;

  /// The number of high-performance cores (P-cores).
  final int? performanceAmount;

  /// The number of energy-efficient cores (E-cores).
  final int? efficiencyAmount;

  /// The total number of threads.
  final int threadsAmount;

  /// The base clock speed of performance cores in GHz.
  final double? basePerformanceSpeed;

  /// The boost clock speed of performance cores in GHz.
  final double? boostPerformanceSpeed;

  /// The base clock speed of efficiency cores in GHz.
  final double? baseEfficiencySpeed;

  /// The boost clock speed of efficiency cores in GHz.
  final double? boostEfficiencySpeed;

  /// The amount of L1, L2, L3, and L4 cache in megabytes.
  final double? l1, l2, l3, l4;

  /// Indicates if a stock cooler is included in the box.
  final bool includesCooler;

  /// The manufacturing process size in nanometers (e.g., "7 nm").
  final String lithography;

  /// Indicates if the CPU supports SMT (e.g., Hyper-Threading).
  final bool supportsSimultaneousMultithreading;

  /// The type of RAM supported (e.g., "DDR5").
  final String memoryType;

  /// The type of packaging (e.g., "Boxed", "Tray").
  final String packagingType;

  /// Indicates if the CPU supports ECC memory.
  final bool supportsECC;

  /// The Thermal Design Power in watts, indicating heat output.
  final double thermalDesignPower;

  /// The name of the integrated graphics, if any.
  final String graphics;

  const CPUComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.series,
    required this.microarchitecture,
    required this.coreFamily,
    required this.socketType,
    required this.coreTotal,
    required this.threadsAmount,
    required this.includesCooler,
    required this.lithography,
    required this.supportsSimultaneousMultithreading,
    required this.memoryType,
    required this.packagingType,
    required this.supportsECC,
    required this.thermalDesignPower,
    required this.graphics,
    this.performanceAmount,
    this.efficiencyAmount,
    this.basePerformanceSpeed,
    this.boostPerformanceSpeed,
    this.baseEfficiencySpeed,
    this.boostEfficiencySpeed,
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.cpu);
}

/// Represents a Graphics Processing Unit (GPU) or Video Card.
@immutable
class GPUComponent extends BaseComponent {
  /// The name of the graphics processor (e.g., "GeForce RTX 4090").
  final String chipset;

  /// The amount of video memory (VRAM) in gigabytes.
  final double videoMemoryAmount;

  /// The type of video memory (e.g., "GDDR6X").
  final String videoMemoryType;

  /// The base clock speed of the GPU core in MHz.
  final double coreBaseClockSpeed;

  /// The boost clock speed of the GPU core in MHz.
  final double coreBoostClockSpeed;

  /// The number of shading units, CUDA cores, or stream processors.
  final int coreCount;

  /// The effective speed of the video memory in MHz.
  final double effectiveMemoryClockSpeed;

  /// The width of the memory interface in bits.
  final int memoryBusWidth;

  /// The adaptive sync technology supported (e.g., "G-Sync", "FreeSync").
  final String frameSync;

  /// The length of the card in millimeters.
  final double length;

  /// The Thermal Design Power in watts, indicating power consumption and heat.
  final double thermalDesignPower;

  /// The number of case expansion slots the card occupies.
  final int caseExpansionSlotWidth;

  /// The total number of physical slots the cooler occupies.
  final int totalSlotAmount;

  /// The type of cooling solution (e.g., "Air", "Liquid", "Hybrid").
  final String coolingType;

  const GPUComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.chipset,
    required this.videoMemoryAmount,
    required this.videoMemoryType,
    required this.coreBaseClockSpeed,
    required this.coreBoostClockSpeed,
    required this.coreCount,
    required this.effectiveMemoryClockSpeed,
    required this.memoryBusWidth,
    required this.frameSync,
    required this.length,
    required this.thermalDesignPower,
    required this.caseExpansionSlotWidth,
    required this.totalSlotAmount,
    required this.coolingType,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.gpu);
}

/// Represents a Memory (RAM) module.
@immutable
class MemoryComponent extends BaseComponent {
  /// The clock speed of the RAM in MHz.
  final double speed;

  /// The generation of RAM (e.g., "DDR4", "DDR5").
  final String ramType;

  /// The physical form factor (e.g., "DIMM" for desktops, "SO-DIMM" for laptops).
  final String formFactor;

  /// The total capacity of the kit in gigabytes.
  final double capacity;

  /// The CAS (Column Address Strobe) latency. Lower is generally better.
  final double casLatency;

  /// The full timing string (e.g., "16-18-18-38").
  final String? timings;

  /// The number of individual RAM sticks in the kit.
  final int moduleQuantity;

  /// The capacity of a single module in gigabytes.
  final double moduleCapacity;

  /// Indicates if the RAM is ECC (Error-Correcting Code) or non-ECC.
  final String ecc;

  /// Indicates if the RAM is registered (buffered) or unbuffered.
  final String registeredType;

  /// Indicates if the modules have heat spreaders.
  final bool haveHeatSpreader;

  /// Indicates if the modules have RGB lighting.
  final bool haveRGB;

  /// The height of the RAM module in millimeters, for cooler clearance.
  final double height;

  /// The operating voltage of the RAM.
  final double voltage;

  const MemoryComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.speed,
    required this.ramType,
    required this.formFactor,
    required this.capacity,
    required this.casLatency,
    this.timings,
    required this.moduleQuantity,
    required this.moduleCapacity,
    required this.ecc,
    required this.registeredType,
    required this.haveHeatSpreader,
    required this.haveRGB,
    required this.height,
    required this.voltage,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.ram);
}

/// Represents a computer Monitor.
@immutable
class MonitorComponent extends BaseComponent {
  /// The diagonal size of the screen in inches.
  final double screenSize;

  /// The number of horizontal pixels.
  final int horizontalResolution;

  /// The number of vertical pixels.
  final int verticalResolution;

  /// The maximum refresh rate in Hertz (Hz).
  final double maxRefreshRate;

  /// The type of display panel technology (e.g., "IPS", "VA", "OLED").
  final String panelType;

  /// The response time in milliseconds (ms), typically Grey-to-Grey.
  final double responseTime;

  /// The viewing angles, horizontal and vertical.
  final String viewingAngle;

  /// The ratio of width to height (e.g., "16:9", "21:9").
  final String aspectRatio;

  /// The maximum brightness in nits (cd/m²).
  final double? maxBrightness;

  /// The HDR (High Dynamic Range) standard supported (e.g., "HDR10", "DisplayHDR 400").
  final String? highDynamicRangeType;

  /// The adaptive sync technology supported (e.g., "FreeSync Premium", "G-Sync Compatible").
  final String adaptiveSyncType;

  const MonitorComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.screenSize,
    required this.horizontalResolution,
    required this.verticalResolution,
    required this.maxRefreshRate,
    required this.panelType,
    required this.responseTime,
    required this.viewingAngle,
    required this.aspectRatio,
    this.maxBrightness,
    this.highDynamicRangeType,
    required this.adaptiveSyncType,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.monitor);
}

/// Represents a Motherboard component.
@immutable
class MotherboardComponent extends BaseComponent {
  /// The CPU socket type (e.g., "AM5", "LGA1700").
  final String socketType;

  /// The physical size of the motherboard (e.g., "ATX", "Micro-ATX").
  final String formFactor;

  /// The main chipset (e.g., "B650", "Z790").
  final String chipsetType;

  /// The type of RAM supported (e.g., "DDR5").
  final String ramType;

  /// The number of RAM slots available.
  final int ramSlotsAmount;

  /// The maximum amount of RAM supported in gigabytes.
  final int maxRAMAmount;

  /// The number of SATA 6 Gbit/s ports.
  final int sata6GBsAmount;

  /// The number of SATA 3 Gbit/s ports.
  final int sata3GBsAmount;

  /// The number of U.2 ports for high-speed storage.
  final int u2PortAmount;

  /// The standard of the built-in wireless networking, if any (e.g., "Wi-Fi 6E").
  final String wirelessNetworkingStandard;

  /// The number of headers for CPU fans.
  final int? cpuFanHeaderAmount;

  /// The number of headers for case fans.
  final int? caseFanHeaderAmount;

  /// The number of headers for water cooling pumps.
  final int? pumpHeaderAmount;

  /// The number of headers for optional/secondary CPU fans.
  final int? cpuOptionalFanHeaderAmount;

  /// The number of 3-pin 5V addressable RGB headers.
  final int? argb5vHeaderAmount;

  /// The number of 4-pin 12V RGB headers.
  final int? rgb12vHeaderAmount;

  /// Indicates if there's a header for the case's power button.
  final bool hasPowerButtonHeader;

  /// Indicates if there's a header for the case's reset button.
  final bool hasResetButtonHeader;

  /// Indicates if there's a header for the case's power LED.
  final bool hasPowerLEDHeader;

  /// Indicates if there's a header for the case's HDD activity LED.
  final bool hasHDDLEDHeader;

  /// The number of headers for thermal sensors.
  final int? temperatureSensorHeaderAmount;

  /// The number of internal headers for Thunderbolt add-in cards.
  final int? thunderboltHeaderAmount;

  /// The number of headers for legacy COM ports.
  final int? comPortHeaderAmount;

  /// The type of main power connector from the PSU (e.g., "24-pin ATX").
  final String? mainPowerType;

  /// Indicates if the motherboard supports ECC memory.
  final bool hasECCSupport;

  /// Indicates if the motherboard's chipset supports RAID configurations.
  final bool hasRAIDSupport;

  /// Indicates if the board has a BIOS flashback feature.
  final bool hasFlashback;

  /// Indicates if the board has a clear CMOS button or jumper.
  final bool hasCMOS;

  /// The model of the onboard audio chipset (e.g., "Realtek ALC1220").
  final String audioChipset;

  /// The maximum number of audio channels supported (e.g., 7.1).
  final double maxAudioChannels;

  const MotherboardComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.socketType,
    required this.formFactor,
    required this.chipsetType,
    required this.ramType,
    required this.ramSlotsAmount,
    required this.maxRAMAmount,
    required this.sata6GBsAmount,
    required this.sata3GBsAmount,
    required this.u2PortAmount,
    required this.wirelessNetworkingStandard,
    this.cpuFanHeaderAmount,
    this.caseFanHeaderAmount,
    this.pumpHeaderAmount,
    this.cpuOptionalFanHeaderAmount,
    this.argb5vHeaderAmount,
    this.rgb12vHeaderAmount,
    required this.hasPowerButtonHeader,
    required this.hasResetButtonHeader,
    required this.hasPowerLEDHeader,
    required this.hasHDDLEDHeader,
    this.temperatureSensorHeaderAmount,
    this.thunderboltHeaderAmount,
    this.comPortHeaderAmount,
    this.mainPowerType,
    required this.hasECCSupport,
    required this.hasRAIDSupport,
    required this.hasFlashback,
    required this.hasCMOS,
    required this.audioChipset,
    required this.maxAudioChannels,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.motherboard);
}

/// Represents a Power Supply Unit (PSU).
@immutable
class PowerSupplyComponent extends BaseComponent {
  /// The maximum continuous power output in watts.
  final double powerOutput;

  /// The physical form factor (e.g., "ATX", "SFX").
  final String formFactor;

  /// The efficiency certification (e.g., "80+ Gold", "80+ Platinum").
  final String? efficiencyRating;

  /// The type of cabling (e.g., "Fully Modular", "Semi-Modular", "Non-Modular").
  final String modularityType;

  /// The length of the PSU in millimeters.
  final double length;

  /// Indicates if the PSU can operate without its fan under low loads.
  final bool isFanless;

  const PowerSupplyComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.powerOutput,
    required this.formFactor,
    this.efficiencyRating,
    required this.modularityType,
    required this.length,
    required this.isFanless,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.psu);
}

/// Represents a storage device, such as an SSD or HDD.
@immutable
class StorageComponent extends BaseComponent {
  /// The product series name (e.g., "Samsung 980 Pro", "Seagate Barracuda").
  final String series;

  /// The storage capacity in gigabytes (GB) or terabytes (TB).
  final double capacity;

  /// The type of storage medium (e.g., "SSD", "HDD").
  final String driveType;

  /// The physical form factor (e.g., "2.5-inch", "M.2-2280").
  final String formFactor;

  /// The data interface used (e.g., "SATA", "PCIe 4.0 x4").
  final String interface;

  /// Indicates if the drive uses the NVMe protocol (for SSDs).
  final bool hasNVMe;

  const StorageComponent({
    required super.id,
    required super.name,
    required super.manufacturer,
    required super.databaseEntryAt,
    required super.lastEditedAt,
    required super.imageUrl,
    required this.series,
    required this.capacity,
    required this.driveType,
    required this.formFactor,
    required this.interface,
    required this.hasNVMe,
    super.release,
    super.note,
    super.prices,
    super.variants,
    super.reviews,
    super.parts,
  }) : super(type: ComponentType.storage);
}
