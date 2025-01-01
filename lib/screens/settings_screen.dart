import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String) onIpSaved;

  const SettingsScreen({Key? key, required this.onIpSaved}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _loadIpAddress();
  }

  Future<void> _loadIpAddress() async {
    final prefs = await _prefs;
    final savedIp = prefs.getString('esp32_ip');
    if (savedIp != null) {
      _ipController.text = savedIp;
    }
  }

  Future<void> _saveIpAddress(String ip) async {
    final prefs = await _prefs;
    await prefs.setString('esp32_ip', ip);
    widget.onIpSaved(ip);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Adresse IP du module ESP32',
                  hintText: 'Ex: 192.168.1.100',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une adresse IP';
                  }
                  // Validation simple d'IP
                  final ipRegExp = RegExp(
                    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
                  );
                  if (!ipRegExp.hasMatch(value)) {
                    return 'Adresse IP invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveIpAddress(_ipController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Sauvegarder'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
