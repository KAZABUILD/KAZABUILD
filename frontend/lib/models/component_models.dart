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
  final String colorCode;
  final String colorName;
  final DateTime databaseEntryAt;
  final DateTime lastEditedAt;
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
  final String id;
  final String colorCode;
  final bool? isAvailable;
  final double? additionalPrice;

  /// The timestamp when this entry was created in the database.
  final DateTime databaseEntryAt;
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
  final String id;
  final String sourceUrl;
  final String componentId;
  final String vendorName;
  final DateTime fetchedAt;
  final double price;
  final String currency;
  final DateTime databaseEntryAt;
  final DateTime lastEditedAt;
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
  final String id;
  final String sourceUrl;
  final String componentId;
  final String reviewerName;
  final DateTime fetchedAt;
  final DateTime createdAt;
  final double rating;
  final String reviewText;
  final DateTime databaseEntryAt;
  final DateTime lastEditedAt;
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
  final String id;
  final String name;
  final SubComponentType type;
  final DateTime databaseEntryAt;
  final DateTime lastEditedAt;
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
  final String? model;
  final int baseClockSpeed;
  final int boostClockSpeed;
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
  final String size;
  final String keyType;
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
  final String speed;
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
  final String gen;
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
  final String id;

  final String name;

  final String manufacturer;

  final DateTime? release;

  final ComponentType type;

  final DateTime databaseEntryAt;

  final DateTime lastEditedAt;

  final String? note;

  final String imageUrl;

  final List<ComponentPrice> prices;

  final List<ComponentVariant> variants;

  final List<ComponentReview> reviews;

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
  final String formFactor;
  final bool powerSupplyShrouded;
  final double? powerSupplyAmount;
  final bool hasTransparentSidePanel;
  final String? sidePanelType;
  final double maxVideoCardLength;
  final int maxCPUCoolerHeight;
  final int internal35BayAmount;
  final int internal25BayAmount;
  final int external35BayAmount;
  final int external525BayAmount;
  final int expansionSlotAmount;
  final double width;
  final double height;
  final double depth;
  final double volume;
  final double weight;
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
  final double size;
  final int quantity;
  final double minAirflow;
  final double? maxAirflow;
  final double minNoiseLevel;
  final double? maxNoiseLevel;
  final bool pulseWidthModulation;
  final String? ledType;
  final String? connectorType;
  final String controllerType;
  final double staticPressureAmount;
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
  final double? minFanRotationSpeed;
  final double? maxFanRotationSpeed;
  final double? minNoiseLevel;
  final double? maxNoiseLevel;
  final double height;
  final bool isWaterCooled;
  final double? radiatorSize;
  final bool canOperateFanless;
  final double? fanSize;
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
  final String series;
  final String microarchitecture;
  final String coreFamily;
  final String socketType;
  final int coreTotal;
  final int? performanceAmount;
  final int? efficiencyAmount;
  final int threadsAmount;
  final double? basePerformanceSpeed;
  final double? boostPerformanceSpeed;
  final double? baseEfficiencySpeed;
  final double? boostEfficiencySpeed;
  final double? l1, l2, l3, l4;
  final bool includesCooler;
  final String lithography;
  final bool supportsSimultaneousMultithreading;
  final String memoryType;
  final String packagingType;
  final bool supportsECC;
  final double thermalDesignPower;
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
  final String chipset;
  final double videoMemoryAmount;
  final String videoMemoryType;
  final double coreBaseClockSpeed;
  final double coreBoostClockSpeed;
  final int coreCount;
  final double effectiveMemoryClockSpeed;
  final int memoryBusWidth;
  final String frameSync;
  final double length;
  final double thermalDesignPower;
  final int caseExpansionSlotWidth;
  final int totalSlotAmount;
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
  final double speed;
  final String ramType;
  final String formFactor;
  final double capacity;
  final double casLatency;
  final String? timings;
  final int moduleQuantity;
  final double moduleCapacity;
  final String ecc;
  final String registeredType;
  final bool haveHeatSpreader;
  final bool haveRGB;
  final double height;
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
  final double screenSize;
  final int horizontalResolution;
  final int verticalResolution;
  final double maxRefreshRate;
  final String panelType;
  final double responseTime;
  final String viewingAngle;
  final String aspectRatio;
  final double? maxBrightness;
  final String? highDynamicRangeType;
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
  final String socketType;
  final String formFactor;
  final String chipsetType;
  final String ramType;
  final int ramSlotsAmount;
  final int maxRAMAmount;
  final int sata6GBsAmount;
  final int sata3GBsAmount;
  final int u2PortAmount;
  final String wirelessNetworkingStandard;
  final int? cpuFanHeaderAmount;
  final int? caseFanHeaderAmount;
  final int? pumpHeaderAmount;
  final int? cpuOptionalFanHeaderAmount;
  final int? argb5vHeaderAmount;
  final int? rgb12vHeaderAmount;
  final bool hasPowerButtonHeader;
  final bool hasResetButtonHeader;
  final bool hasPowerLEDHeader;
  final bool hasHDDLEDHeader;
  final int? temperatureSensorHeaderAmount;
  final int? thunderboltHeaderAmount;
  final int? comPortHeaderAmount;
  final String? mainPowerType;
  final bool hasECCSupport;
  final bool hasRAIDSupport;
  final bool hasFlashback;
  final bool hasCMOS;
  final String audioChipset;
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
  final double powerOutput;
  final String formFactor;
  final String? efficiencyRating;
  final String modularityType;
  final double length;
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
  final String series;
  final double capacity;
  final String driveType;
  final String formFactor;
  final String interface;
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
