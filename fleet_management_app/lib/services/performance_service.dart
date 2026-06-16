import 'package:flutter/foundation.dart';
import 'dart:async';

/// Performance monitoring and optimization service
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, Stopwatch> _timers = {};
  final List<PerformanceMetric> _metrics = [];
  bool _disposed = false;
  static const int maxMetricsHistory = 100;

  /// Start tracking a performance metric
  void startMetric(String name) {
    if (_disposed) return;
    _timers[name] = Stopwatch()..start();
  }

  /// End tracking and record metric
  double? endMetric(String name) {
    if (_disposed || !_timers.containsKey(name)) return null;
    final stopwatch = _timers.remove(name);
    stopwatch?.stop();
    final duration = stopwatch?.elapsedMilliseconds.toDouble() ?? 0;

    final metric = PerformanceMetric(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
    );

    _metrics.add(metric);

    // Keep only recent metrics
    if (_metrics.length > maxMetricsHistory) {
      _metrics.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('Performance: $name took ${duration.toStringAsFixed(2)}ms');
    }

    return duration;
  }

  /// Record a custom metric
  void recordMetric(String name, double duration) {
    if (_disposed) return;

    final metric = PerformanceMetric(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
    );

    _metrics.add(metric);

    if (_metrics.length > maxMetricsHistory) {
      _metrics.removeAt(0);
    }
  }

  /// Get average duration for a metric
  double? getAverageDuration(String name) {
    final relevantMetrics = _metrics.where((m) => m.name == name).toList();
    if (relevantMetrics.isEmpty) return null;

    final sum = relevantMetrics.fold<double>(
      0,
      (prev, metric) => prev + metric.duration,
    );
    return sum / relevantMetrics.length;
  }

  /// Get slowest metric
  PerformanceMetric? getSlowestMetric(String name) {
    final relevantMetrics = _metrics.where((m) => m.name == name).toList();
    if (relevantMetrics.isEmpty) return null;

    relevantMetrics.sort((a, b) => b.duration.compareTo(a.duration));
    return relevantMetrics.first;
  }

  /// Get all metrics
  List<PerformanceMetric> getAllMetrics() => List.unmodifiable(_metrics);

  /// Get metrics for specific operation
  List<PerformanceMetric> getMetricsFor(String name) {
    return _metrics.where((m) => m.name == name).toList();
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _timers.clear();
  }

  /// Print performance report
  void printReport() {
    if (_disposed || _metrics.isEmpty) {
      debugPrint('No performance metrics recorded');
      return;
    }

    debugPrint('\n=== PERFORMANCE REPORT ===');

    // Group by name
    final grouped = <String, List<PerformanceMetric>>{};
    for (final metric in _metrics) {
      grouped.putIfAbsent(metric.name, () => []).add(metric);
    }

    // Print stats for each operation
    for (final entry in grouped.entries) {
      final name = entry.key;
      final metrics = entry.value;
      final durations = metrics.map((m) => m.duration).toList();
      durations.sort();

      final avg = durations.reduce((a, b) => a + b) / durations.length;
      final min = durations.first;
      final max = durations.last;
      final median = durations[durations.length ~/ 2];

      debugPrint('\n$name (${metrics.length} calls):');
      debugPrint('  Average: ${avg.toStringAsFixed(2)}ms');
      debugPrint('  Min: ${min.toStringAsFixed(2)}ms');
      debugPrint('  Max: ${max.toStringAsFixed(2)}ms');
      debugPrint('  Median: ${median.toStringAsFixed(2)}ms');
    }

    debugPrint('\n=== END REPORT ===\n');
  }

  /// Dispose service
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timers.clear();
    _metrics.clear();
    debugPrint('Performance service disposed');
  }

  bool get isDisposed => _disposed;
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final double duration; // in milliseconds
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
  });

  @override
  String toString() => '$name: ${duration.toStringAsFixed(2)}ms at $timestamp';
}

/// Extension for easy performance tracking
extension PerformanceTracking on Future {
  /// Track async operation performance
  Future<T> withPerformanceTracking<T>(String name) async {
    final service = PerformanceService();
    service.startMetric(name);
    try {
      final result = await this as Future<T>;
      service.endMetric(name);
      return result;
    } catch (e) {
      service.endMetric(name);
      rethrow;
    }
  }
}
