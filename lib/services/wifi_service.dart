import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gas_reading.dart';

class WifiService {
  String? _esp32IpAddress;
  Timer? _pollTimer;
  final StreamController<GasReading> _gasReadingsController = StreamController<GasReading>.broadcast();

  Stream<GasReading> get gasReadings => _gasReadingsController.stream;

  void setEsp32IpAddress(String ipAddress) {
    _esp32IpAddress = ipAddress;
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchGasReading();
    });
  }

  Future<void> _fetchGasReading() async {
    if (_esp32IpAddress == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://$_esp32IpAddress/gas'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _gasReadingsController.add(
          GasReading(
            value: data['value'].toDouble(),
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('Error fetching gas reading: $e');
    }
  }

  Future<bool> testConnection() async {
    if (_esp32IpAddress == null) return false;

    try {
      final response = await http.get(
        Uri.parse('http://$_esp32IpAddress/gas'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _gasReadingsController.close();
  }
}
