import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/gas_reading.dart';

class BluetoothService {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  StreamController<GasReading> _gasReadingsController = StreamController<GasReading>.broadcast();

  Stream<GasReading> get gasReadings => _gasReadingsController.stream;

  Future<bool> connectToDevice(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _connection!.input!.listen((data) {
        String message = ascii.decode(data);
        try {
          double value = double.parse(message);
          _gasReadingsController.add(
            GasReading(
              value: value,
              timestamp: DateTime.now(),
            ),
          );
        } catch (e) {
          print('Error parsing data: $e');
        }
      });
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await _bluetooth.getBondedDevices();
    } catch (e) {
      print('Error getting paired devices: $e');
    }
    return devices;
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;
  }

  void dispose() {
    _gasReadingsController.close();
    disconnect();
  }
}
