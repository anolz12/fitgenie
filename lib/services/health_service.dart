import 'package:health/health.dart';
import 'package:flutter/foundation.dart';
import 'stats_service.dart';

class HealthSyncResult {
  final bool success;
  final String message;
  final int? steps;
  final int? calories;

  const HealthSyncResult({
    required this.success,
    required this.message,
    this.steps,
    this.calories,
  });
}

class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final Health _health = Health();

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final types = [HealthDataType.STEPS, HealthDataType.ACTIVE_ENERGY_BURNED];
    final permissions = [HealthDataAccess.READ, HealthDataAccess.READ];
    try {
      return await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
    } catch (_) {
      // Health Connect / Google Fit not available or user declined
      return false;
    }
  }

  Future<HealthSyncResult> syncToday() async {
    if (kIsWeb) {
      return const HealthSyncResult(
        success: false,
        message: 'Health sync is not supported on web.',
      );
    }
    final granted = await requestPermissions();
    if (!granted) {
      return const HealthSyncResult(
        success: false,
        message: 'Permission denied or Health Connect unavailable.',
      );
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final types = [HealthDataType.STEPS, HealthDataType.ACTIVE_ENERGY_BURNED];

    List<HealthDataPoint> data = [];
    try {
      data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );
    } catch (_) {
      return const HealthSyncResult(
        success: false,
        message: 'Could not read health data. Check Health Connect/Google Fit.',
      );
    }

    int steps = 0;
    double energy = 0;

    for (final point in data) {
      switch (point.type) {
        case HealthDataType.STEPS:
          steps += (point.value as num).toInt();
          break;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          energy += (point.value as num).toDouble(); // typically in kJ
          break;
        default:
          break;
      }
    }

    // Convert energy from kJ to kcal if needed (health package uses kJ on Android)
    final calories = (energy / 4.184).round();

    await StatsService.instance.setStats(
      steps: steps,
      calories: calories,
      minutes: 0,
    );

    return HealthSyncResult(
      success: true,
      message: 'Synced: $steps steps, $calories kcal',
      steps: steps,
      calories: calories,
    );
  }
}
