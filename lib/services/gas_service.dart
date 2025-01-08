import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class GasService extends ChangeNotifier {
  double _gasLevel = 0.0;
  String _ipAddress = '';
  int _criticalLevel = 500;
  Timer? _timer;
  final NotificationService _notificationService;

  GasService(this._notificationService) {
    loadSettings();
  }

  double get gasLevel => _gasLevel;
  String get ipAddress => _ipAddress;
  int get criticalLevel => _criticalLevel;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ipAddress = prefs.getString('esp32_ip') ?? '';
      _criticalLevel = prefs.getInt('critical_level') ?? 500;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
    }
  }

  Future<void> setIpAddress(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('esp32_ip', ip);
      _ipAddress = ip;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de l\'IP: $e');
    }
  }

  Future<void> setCriticalLevel(int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('critical_level', level);
      _criticalLevel = level;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du niveau critique: $e');
    }
  }

  Future<void> fetchGasLevel() async {
    if (_ipAddress.isEmpty) return;

    try {
      final response = await http.get(Uri.parse('http://$_ipAddress/gas'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _gasLevel = double.parse(data['level'].toString());
        
        if (_gasLevel >= _criticalLevel) {
          await _notificationService.showGasAlert(
            'CO2',
            _gasLevel,
            _criticalLevel,
          );
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
    }
  }

  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchGasLevel();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
