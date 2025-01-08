import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gas_service.dart';
import '../services/history_service.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Démarrer la surveillance au lancement
    Future.microtask(() {
      context.read<GasService>().startMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/inpt_logo.png', height: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'INPT Gas Detector',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Consumer2<GasService, HistoryService>(
        builder: (context, gasService, historyService, child) {
          final isConnected = gasService.isConnected;
          final currentLevel = gasService.gasLevel;
          final criticalLevel = gasService.criticalLevel;
          final readings = historyService.readings;

          return RefreshIndicator(
            onRefresh: () => gasService.fetchGasLevel(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard(isConnected, currentLevel, criticalLevel),
                const SizedBox(height: 16),
                _buildChartCard(readings),
                const SizedBox(height: 16),
                _buildLastReadingsCard(readings),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(bool isConnected, double currentLevel, int criticalLevel) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isConnected) {
      statusColor = Colors.grey;
      statusText = 'DÉCONNECTÉ';
      statusIcon = Icons.cloud_off;
    } else if (currentLevel >= criticalLevel) {
      statusColor = Colors.red;
      statusText = 'NIVEAU CRITIQUE';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'NORMAL';
      statusIcon = Icons.check_circle;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'État du Capteur',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildGasLevelIndicator(currentLevel, criticalLevel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasLevelIndicator(double currentLevel, int criticalLevel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentLevel >= criticalLevel ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            currentLevel.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: currentLevel >= criticalLevel ? Colors.red : Colors.green,
            ),
          ),
          Text(
            'PPM',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<GasReading> readings) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des Lectures',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: readings.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), double.parse(entry.value.ppm.toStringAsFixed(1)));
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadingsCard(List<GasReading> readings) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dernières Lectures',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...readings.reversed.take(5).map((reading) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reading.timestamp.hour.toString().padLeft(2, '0')}:${reading.timestamp.minute.toString().padLeft(2, '0')}:${reading.timestamp.second.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                    Text(
                      '${reading.ppm.toStringAsFixed(1)} PPM',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
