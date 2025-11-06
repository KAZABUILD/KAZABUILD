/// This file defines the state management for fetching PC components from the backend.
///
/// It uses Riverpod to create providers that handle fetching lists of `BaseComponent`
/// objects, abstracting the API logic away from the UI widgets. It supports
/// server-side filtering and pagination through the `ComponentFilter` class.
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/component_models.dart';

/// A service class to handle API requests related to PC components.
class ComponentService {
  final Dio _dio;

  ComponentService(this._dio);

  /// Fetches a list of components of a specific type from the backend.
  Future<List<BaseComponent>> getComponents(ComponentType componentType) async {
    final url = '$apiBaseUrl/Components/get';

    // Helper to map the frontend enum to backend DTO type name.
    String _mapTypeToBackendDtoName(ComponentType type) {
      const baseNs = 'KAZABUILD.Application.DTOs.Components.Components';
      const asm = 'KAZABUILD.Application';
      switch (type) {
        case ComponentType.cpu:
          return '$baseNs.CPUComponent.GetCPUComponentDto, $asm';
        case ComponentType.gpu:
          return '$baseNs.GPUComponent.GetGPUComponentDto, $asm';
        case ComponentType.motherboard:
          return '$baseNs.MotherboardComponent.GetMotherboardComponentDto, $asm';
        case ComponentType.ram:
          return '$baseNs.MemoryComponent.GetMemoryComponentDto, $asm';
        case ComponentType.storage:
          return '$baseNs.StorageComponent.GetStorageComponentDto, $asm';
        case ComponentType.psu:
          return '$baseNs.PowerSupplyComponent.GetPowerSupplyComponentDto, $asm';
        case ComponentType.cooler:
          return '$baseNs.CoolerComponent.GetCoolerComponentDto, $asm';
        case ComponentType.pcCase:
          return '$baseNs.CaseComponent.GetCaseComponentDto, $asm';
        case ComponentType.caseFan:
          return '$baseNs.CaseFanComponent.GetCaseFanComponentDto, $asm';
        case ComponentType.monitor:
          return '$baseNs.MonitorComponent.GetMonitorComponentDto, $asm';
        default:
          throw Exception('Unsupported component type: $type');
      }
    }

    // Prepare the request body for backend polymorphic deserializer.
    final body = {
      r'$type': _mapTypeToBackendDtoName(componentType),
      'paging': true,
      'page': 1,
      'pageLength': 50,
    };

    try {
      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;

        return data.map((json) {
          final typeString = (json['type'] as String?)?.toUpperCase();
          switch (typeString) {
            case 'CPU':
              return CPUComponent.fromJson(json);
            case 'GPU':
              return GPUComponent.fromJson(json);
            case 'MOTHERBOARD':
              return MotherboardComponent.fromJson(json);
            case 'MEMORY':
            case 'RAM':
              return MemoryComponent.fromJson(json);
            case 'STORAGE':
              return StorageComponent.fromJson(json);
            case 'POWERSUPPLY':
            case 'PSU':
              return PowerSupplyComponent.fromJson(json);
            case 'CASE':
            case 'PCCASE':
              return CaseComponent.fromJson(json);
            case 'COOLER':
              return CoolerComponent.fromJson(json);
            case 'CASEFAN':
              return CaseFanComponent.fromJson(json);
            case 'MONITOR':
              return MonitorComponent.fromJson(json);
            default:
              if (kDebugMode) {
                print('Unsupported component type received: $typeString');
              }
              return null;
          }
        }).whereType<BaseComponent>().toList();
      } else {
        throw Exception('Failed to load components: Status code ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for ComponentService using authenticated Dio.
final componentServiceProvider = Provider<ComponentService>((ref) {
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return ComponentService(dio);
});

/// Provider that fetches components by type (with caching, loading/error support).
final componentsProvider = FutureProvider.family<List<BaseComponent>, ComponentType>((ref, type) {
  final componentService = ref.watch(componentServiceProvider);
  return componentService.getComponents(type);
});
