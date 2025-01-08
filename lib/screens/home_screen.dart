import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gas_service.dart';
import '../services/notification_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isAlertActive = false;
  int _criticalLevel = 500;

  @override
  void initState() {
    super.initState();
    final gasService = Provider.of<GasService>(context, listen: false);
    _criticalLevel = gasService.criticalLevel;
    gasService.startMonitoring();
  }

  @override
  void dispose() {
    final gasService = Provider.of<GasService>(context, listen: false);
    gasService.stopMonitoring();
    super.dispose();
  }

  Future<void> _handleGasLevelChange(double gasLevel) async {
    if (gasLevel >= _criticalLevel && !_isAlertActive) {
      _isAlertActive = true;
      await _notificationService.showGasAlert(
        'CO2',
        gasLevel,
        _criticalLevel,
      );
    } else if (gasLevel < _criticalLevel) {
      _isAlertActive = false;
    }
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
                    onIpSaved: (ip) {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<GasService>(
        builder: (context, gasService, child) {
          // Utiliser addPostFrameCallback pour éviter setState pendant le build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleGasLevelChange(gasService.gasLevel);
          });
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Niveau de CO2',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Text(
                  '${gasService.gasLevel.toStringAsFixed(1)} ppm',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: gasService.gasLevel >= _criticalLevel
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Niveau critique: $_criticalLevel ppm',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
