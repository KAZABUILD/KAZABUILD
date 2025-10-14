import 'package:flutter/foundation.dart';
import 'dart:math';

// enums

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

enum SubComponentType {
  coolerSocket,
  integratedGraphics,
  m2Slot,
  onboardEthernet,
  pcieSlot,
  port,
}

enum PortType { usb, hdmi, displayPort }

// domain models

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

@immutable
class ComponentVariant {
  final String id;
  final String colorCode;
  final bool? isAvailable;
  final double? additionalPrice;
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

  double? get lowestPrice {
    if (prices.isEmpty) return null;
    return prices.map((p) => p.price).reduce(min);
  }

  double? get averageRating {
    if (reviews.isEmpty) return null;
    final totalRating = reviews.map((r) => r.rating).reduce((a, b) => a + b);
    final avg = totalRating / reviews.length;
    return avg / 20.0;
  }
}

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

  CPUComponent({
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

final List<CPUComponent> mockCPUs = [
  CPUComponent(
    id: 'cpu-001',
    name: 'Intel Core i7-13700K',
    manufacturer: 'Intel',
    imageUrl: 'https://placehold.co/100x100/FFFFFF/000000?text=i7',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    series: 'Core i7',
    microarchitecture: 'Raptor Lake',
    coreFamily: 'Raptor Lake',
    socketType: 'LGA1700',
    coreTotal: 16,
    threadsAmount: 24,
    basePerformanceSpeed: 3.4,
    boostPerformanceSpeed: 5.4,
    includesCooler: false,
    lithography: 'Intel 7',
    supportsSimultaneousMultithreading: true,
    memoryType: 'DDR5',
    packagingType: 'Box',
    supportsECC: false,
    thermalDesignPower: 125,
    graphics: 'UHD 770',
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'cpu-001',
        vendorName: 'Vendor A',
        fetchedAt: DateTime.now(),
        price: 409.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
    reviews: [
      ComponentReview(
        id: 'r1',
        sourceUrl: '',
        componentId: 'cpu-001',
        reviewerName: 'Guru',
        fetchedAt: DateTime.now(),
        createdAt: DateTime.now(),
        rating: 88,
        reviewText: '',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
  CPUComponent(
    id: 'cpu-002',
    name: 'AMD Ryzen 7 7700X',
    manufacturer: 'AMD',
    imageUrl: 'https://placehold.co/100x100/FF0000/FFFFFF?text=R7',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    series: 'Ryzen 7',
    microarchitecture: 'Zen 4',
    coreFamily: 'Raphael',
    socketType: 'AM5',
    coreTotal: 8,
    threadsAmount: 16,
    basePerformanceSpeed: 4.5,
    boostPerformanceSpeed: 5.4,
    includesCooler: false,
    lithography: '5nm',
    supportsSimultaneousMultithreading: true,
    memoryType: 'DDR5',
    packagingType: 'Box',
    supportsECC: true,
    thermalDesignPower: 105,
    graphics: 'Radeon',
    prices: [
      ComponentPrice(
        id: 'p2',
        sourceUrl: '',
        componentId: 'cpu-002',
        vendorName: 'Vendor B',
        fetchedAt: DateTime.now(),
        price: 349.00,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
    reviews: [
      ComponentReview(
        id: 'r2',
        sourceUrl: '',
        componentId: 'cpu-002',
        reviewerName: 'Pro',
        fetchedAt: DateTime.now(),
        createdAt: DateTime.now(),
        rating: 92,
        reviewText: '',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
  CPUComponent(
    id: 'cpu-003',
    name: 'Intel Core i5-13600K',
    manufacturer: 'Intel',
    imageUrl: 'https://placehold.co/100x100/FFFFFF/000000?text=i5',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    series: 'Core i5',
    microarchitecture: 'Raptor Lake',
    coreFamily: 'Raptor Lake',
    socketType: 'LGA1700',
    coreTotal: 14,
    threadsAmount: 20,
    basePerformanceSpeed: 3.5,
    boostPerformanceSpeed: 5.1,
    includesCooler: false,
    lithography: 'Intel 7',
    supportsSimultaneousMultithreading: true,
    memoryType: 'DDR5',
    packagingType: 'Box',
    supportsECC: false,
    thermalDesignPower: 125,
    graphics: 'UHD 770',
    prices: [
      ComponentPrice(
        id: 'p3',
        sourceUrl: '',
        componentId: 'cpu-003',
        vendorName: 'Vendor C',
        fetchedAt: DateTime.now(),
        price: 289.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
    reviews: [
      ComponentReview(
        id: 'r3',
        sourceUrl: '',
        componentId: 'cpu-003',
        reviewerName: 'Expert',
        fetchedAt: DateTime.now(),
        createdAt: DateTime.now(),
        rating: 95,
        reviewText: '',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
];

final List<CaseComponent> mockCases = [
  CaseComponent(
    id: 'case-001',
    name: 'Corsair 4000D Airflow',
    manufacturer: 'Corsair',
    imageUrl: 'https://placehold.co/100x100/000000/FFFFFF?text=Case',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    formFactor: 'ATX Mid Tower',
    powerSupplyShrouded: true,
    hasTransparentSidePanel: true,
    sidePanelType: 'Tempered Glass',
    maxVideoCardLength: 360,
    maxCPUCoolerHeight: 170,
    internal35BayAmount: 2,
    internal25BayAmount: 2,
    external35BayAmount: 0,
    external525BayAmount: 0,
    expansionSlotAmount: 7,
    width: 230,
    height: 453,
    depth: 466,
    volume: 48.5,
    weight: 7.8,
    supportsRearConnectingMotherboard: false,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'case-001',
        vendorName: 'Vendor A',
        fetchedAt: DateTime.now(),
        price: 94.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
];

final List<MotherboardComponent> mockMotherboards = [
  MotherboardComponent(
    id: 'mb-001',
    name: 'ASUS ROG Strix B650-A',
    manufacturer: 'ASUS',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    imageUrl: 'https://placehold.co/100x100/EAEAEA/000000?text=MB',
    socketType: 'AM5',
    formFactor: 'ATX',
    chipsetType: 'B650',
    ramType: 'DDR5',
    ramSlotsAmount: 4,
    maxRAMAmount: 128,
    sata6GBsAmount: 4,
    sata3GBsAmount: 0,
    u2PortAmount: 0,
    wirelessNetworkingStandard: 'WiFi 6E',
    hasPowerButtonHeader: true,
    hasResetButtonHeader: true,
    hasPowerLEDHeader: true,
    hasHDDLEDHeader: true,
    hasECCSupport: false,
    hasRAIDSupport: true,
    hasFlashback: true,
    hasCMOS: true,
    audioChipset: 'Realtek ALC4080',
    maxAudioChannels: 7.1,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'mb-001',
        vendorName: 'Vendor A',
        fetchedAt: DateTime.now(),
        price: 279.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
  MotherboardComponent(
    id: 'mb-002',
    name: 'Gigabyte Z790 AORUS ELITE',
    manufacturer: 'Gigabyte',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    imageUrl: 'https://placehold.co/100x100/CCCCCC/000000?text=MB',
    socketType: 'LGA1700',
    formFactor: 'ATX',
    chipsetType: 'Z790',
    ramType: 'DDR5',
    ramSlotsAmount: 4,
    maxRAMAmount: 128,
    sata6GBsAmount: 6,
    sata3GBsAmount: 0,
    u2PortAmount: 0,
    wirelessNetworkingStandard: 'WiFi 6E',
    hasPowerButtonHeader: true,
    hasResetButtonHeader: true,
    hasPowerLEDHeader: true,
    hasHDDLEDHeader: true,
    hasECCSupport: false,
    hasRAIDSupport: true,
    hasFlashback: true,
    hasCMOS: true,
    audioChipset: 'Realtek ALC1220-VB',
    maxAudioChannels: 7.1,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'mb-002',
        vendorName: 'Vendor B',
        fetchedAt: DateTime.now(),
        price: 259.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
];

final List<MemoryComponent> mockRAMs = [
  MemoryComponent(
    id: 'ram-001',
    name: 'Corsair Vengeance RGB 32GB',
    manufacturer: 'Corsair',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    imageUrl: 'https://placehold.co/100x100/000000/FFFFFF?text=RAM',
    speed: 6000,
    ramType: 'DDR5',
    formFactor: 'DIMM',
    capacity: 32000,
    casLatency: 36,
    moduleQuantity: 2,
    moduleCapacity: 16000,
    ecc: 'Non-ECC',
    registeredType: 'Unbuffered',
    haveHeatSpreader: true,
    haveRGB: true,
    height: 44,
    voltage: 1.35,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'ram-001',
        vendorName: 'Vendor B',
        fetchedAt: DateTime.now(),
        price: 104.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
  MemoryComponent(
    id: 'ram-002',
    name: 'G.Skill Ripjaws S5 32GB',
    manufacturer: 'G.Skill',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    imageUrl: 'https://placehold.co/100x100/FF0000/FFFFFF?text=RAM',
    speed: 5600,
    ramType: 'DDR5',
    formFactor: 'DIMM',
    capacity: 32000,
    casLatency: 28,
    moduleQuantity: 2,
    moduleCapacity: 16000,
    ecc: 'Non-ECC',
    registeredType: 'Unbuffered',
    haveHeatSpreader: true,
    haveRGB: false,
    height: 33,
    voltage: 1.20,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'ram-002',
        vendorName: 'Vendor C',
        fetchedAt: DateTime.now(),
        price: 94.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
];

final List<PowerSupplyComponent> mockPSUs = [
  PowerSupplyComponent(
    id: 'psu-001',
    name: 'Corsair RM850x',
    manufacturer: 'Corsair',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    imageUrl: 'https://placehold.co/100x100/FFFF00/000000?text=PSU',
    powerOutput: 850,
    formFactor: 'ATX',
    efficiencyRating: '80+ Gold',
    modularityType: 'Full',
    length: 160,
    isFanless: false,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'psu-001',
        vendorName: 'Vendor C',
        fetchedAt: DateTime.now(),
        price: 134.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
  PowerSupplyComponent(
    id: 'psu-002',
    name: 'SeaSonic FOCUS Plus Gold 750W',
    manufacturer: 'SeaSonic',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    imageUrl: 'https://placehold.co/100x100/000000/FFFFFF?text=PSU',
    powerOutput: 750,
    formFactor: 'ATX',
    efficiencyRating: '80+ Gold',
    modularityType: 'Full',
    length: 140,
    isFanless: false,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'psu-002',
        vendorName: 'Vendor A',
        fetchedAt: DateTime.now(),
        price: 109.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
];

final List<StorageComponent> mockStorages = [
  StorageComponent(
    id: 'sto-001',
    name: 'Samsung 980 Pro 1TB',
    manufacturer: 'Samsung',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    imageUrl: 'https://placehold.co/100x100/0000FF/FFFFFF?text=SSD',
    series: '980 Pro',
    capacity: 1000,
    driveType: 'SSD',
    formFactor: 'M.2-2280',
    interface: 'PCIe 4.0 x4',
    hasNVMe: true,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'sto-001',
        vendorName: 'Vendor A',
        fetchedAt: DateTime.now(),
        price: 89.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
  StorageComponent(
    id: 'sto-002',
    name: 'Crucial P3 2TB',
    manufacturer: 'Crucial',
    databaseEntryAt: DateTime.now(),
    lastEditedAt: DateTime.now(),
    imageUrl: 'https://placehold.co/100x100/00FFFF/000000?text=SSD',
    series: 'P3',
    capacity: 2000,
    driveType: 'SSD',
    formFactor: 'M.2-2280',
    interface: 'PCIe 3.0 x4',
    hasNVMe: true,
    prices: [
      ComponentPrice(
        id: 'p1',
        sourceUrl: '',
        componentId: 'sto-002',
        vendorName: 'Vendor B',
        fetchedAt: DateTime.now(),
        price: 74.99,
        currency: 'USD',
        databaseEntryAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
      ),
    ],
  ),
];
