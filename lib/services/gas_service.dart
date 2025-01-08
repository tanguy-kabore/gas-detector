import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'history_service.dart';

class GasService extends ChangeNotifier {
  double _gasLevel = 0.0;
  String _ipAddress = '';
  int _criticalLevel = 250;
  Timer? _timer;
  final NotificationService _notificationService;
  final HistoryService _historyService;
  bool _isConnected = false;

  // Paramètres de calibration du MQ2
  static const double RL = 10.0;
  static const double R0 = 10.0;
  static const double VOLT_RESOLUTION = 3.3;
  static const double ADC_RESOLUTION = 4095.0;
  static const double VOLT_RESOLUTION_5V = 5.0;

  GasService(this._notificationService, this._historyService) {
    loadSettings();
  }

  double get gasLevel => _gasLevel;
  String get ipAddress => _ipAddress;
  int get criticalLevel => _criticalLevel;
  bool get isConnected => _isConnected;

  Future<void> loadSettings() async {
    try {
      debugPrint('Chargement des paramètres...');
      final prefs = await SharedPreferences.getInstance();
      _ipAddress = prefs.getString('esp32_ip') ?? '';
      _criticalLevel = prefs.getInt('critical_level') ?? 250;
      debugPrint('Paramètres chargés - IP: $_ipAddress, Niveau critique: $_criticalLevel PPM');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
    }
  }

  Future<void> setIpAddress(String ip) async {
    try {
      debugPrint('Définition de la nouvelle IP: $ip');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('esp32_ip', ip);
      _ipAddress = ip;
      notifyListeners();
      await testConnection();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de l\'IP: $e');
    }
  }

  Future<void> setCriticalLevel(int level) async {
    try {
      debugPrint('Définition du nouveau niveau critique: $level PPM');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('critical_level', level);
      _criticalLevel = level;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du niveau critique: $e');
    }
  }

  double _calculatePPM(double rawValue) {
    // Formule de conversion (à ajuster selon les spécifications du capteur)
    final ppm = (rawValue / 10.42) - 0.42;
    return double.parse(ppm.toStringAsFixed(1));
  }

  Future<bool> testConnection() async {
    if (_ipAddress.isEmpty) {
      debugPrint('Test de connexion impossible: IP non définie');
      _isConnected = false;
      notifyListeners();
      return false;
    }

    try {
      debugPrint('Test de connexion à http://$_ipAddress/gas...');
      final response = await http.get(
        Uri.parse('http://$_ipAddress/gas'),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('La requête a pris trop de temps');
        },
      );

      _isConnected = response.statusCode == 200;
      debugPrint('Test de connexion ${_isConnected ? 'réussi' : 'échoué'} (${response.statusCode})');
      
      if (_isConnected) {
        debugPrint('Réponse du serveur: ${response.body}');
        final data = json.decode(response.body);
        if (data['value'] != null) {
          double rawValue = double.parse(data['value'].toString());
          double ppm = _calculatePPM(rawValue);
          debugPrint('Valeur brute: $rawValue, PPM calculé: $ppm');
        }
      }
      
      notifyListeners();
      return _isConnected;
    } catch (e) {
      debugPrint('Erreur lors du test de connexion: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchGasLevel() async {
    if (_ipAddress.isEmpty) {
      debugPrint('Récupération impossible: IP non définie');
      return;
    }

    try {
      debugPrint('Récupération du niveau de gaz depuis http://$_ipAddress/gas...');
      final response = await http.get(
        Uri.parse('http://$_ipAddress/gas'),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('La requête a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Réponse reçue: ${response.body}');
        final data = json.decode(response.body);
        
        if (data['value'] != null) {
          double rawValue = double.parse(data['value'].toString());
          _gasLevel = _calculatePPM(rawValue);
          debugPrint('Valeur brute: $rawValue, PPM calculé: $_gasLevel');
          
          // Ajouter la lecture à l'historique
          _historyService.addReading(_gasLevel);
          
          if (_gasLevel >= _criticalLevel) {
            debugPrint('Niveau critique atteint! ($_gasLevel >= $_criticalLevel PPM) Envoi de notification...');
            await _notificationService.showGasAlert(
              'GPL/Butane',
              _gasLevel,
              _criticalLevel,
            );
          }
          
          _isConnected = true;
          notifyListeners();
        } else {
          debugPrint('Erreur: La réponse ne contient pas de valeur de gaz');
          _isConnected = false;
          notifyListeners();
        }
      } else {
        debugPrint('Erreur HTTP: ${response.statusCode}');
        _isConnected = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des données: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void startMonitoring() {
    debugPrint('Démarrage de la surveillance...');
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchGasLevel();
    });
  }

  void stopMonitoring() {
    debugPrint('Arrêt de la surveillance');
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
