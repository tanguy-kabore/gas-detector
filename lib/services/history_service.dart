import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class GasReading {
  final double ppm;
  final DateTime timestamp;

  GasReading({required this.ppm, required this.timestamp});
}

class HistoryService extends ChangeNotifier {
  static const int maxReadings = 50; // Garder les 50 dernières lectures
  final List<GasReading> _readings = [];

  List<GasReading> get readings => List.unmodifiable(_readings);

  void addReading(double ppm) {
    _readings.add(GasReading(
      ppm: ppm,
      timestamp: DateTime.now(),
    ));

    if (_readings.length > maxReadings) {
      _readings.removeAt(0);
    }

    notifyListeners();
  }

  void clear() {
    _readings.clear();
    notifyListeners();
  }
}
