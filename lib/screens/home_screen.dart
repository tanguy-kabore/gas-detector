import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/gas_reading.dart';
import '../services/wifi_service.dart';
import 'settings_screen.dart';
import '../services/notification_service.dart'; // Ajout de l'importation du service de notification

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WifiService _wifiService = WifiService();
  final List<GasReading> _readings = [];
  bool _isConnected = false;
  final NotificationService _notificationService = NotificationService(); // Ajout de l'instance du service de notification
  double _currentGasLevel = 0;
  bool _isAlertActive = false;

  @override
  void initState() {
    super.initState();
    _wifiService.gasReadings.listen((reading) {
      setState(() {
        _readings.add(reading);
        if (_readings.length > 50) {
          _readings.removeAt(0);
        }
        _isConnected = true;
        _checkGasLevel(reading.value); // Appel de la méthode pour vérifier le niveau de gaz
      });
    });
  }

  void _updateIpAddress(String ip) {
    _wifiService.setEsp32IpAddress(ip);
  }

  void _checkGasLevel(double gasLevel) {
    setState(() {
      _currentGasLevel = gasLevel;
      
      // Vérifier si le niveau de gaz dépasse 200 ppm
      if (gasLevel >= 200 && !_isAlertActive) {
        _isAlertActive = true;
        _notificationService.showGasAlert(gasLevel);
      } else if (gasLevel < 200) {
        _isAlertActive = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détecteur de Gaz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onIpSaved: _updateIpAddress,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatus(),
          _buildCurrentReading(),
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: _isConnected ? Colors.green : Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.error,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Connecté' : 'Déconnecté',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentReading() {
    final latestReading = _readings.isNotEmpty ? _readings.last.value : 0.0;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Niveau de gaz actuel',
            style: TextStyle(fontSize: 20),
          ),
          Text(
            '${latestReading.toStringAsFixed(2)} ppm',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _readings.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.value,
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _wifiService.dispose();
    super.dispose();
  }
}
