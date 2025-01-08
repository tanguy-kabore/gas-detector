import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _username;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final users = json.decode(usersJson) as Map<String, dynamic>;

    if (!users.containsKey(username)) {
      return false;
    }

    if (users[username] != password) {
      return false;
    }

    _isAuthenticated = true;
    _username = username;
    
    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('username', username);
    
    notifyListeners();
    return true;
  }

  Future<bool> signup(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '{}';
    final users = json.decode(usersJson) as Map<String, dynamic>;

    if (users.containsKey(username)) {
      return false; // L'utilisateur existe déjà
    }

    users[username] = password;
    await prefs.setString('users', json.encode(users));

    _isAuthenticated = true;
    _username = username;
    
    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('username', username);
    
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _username = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAuthenticated');
    await prefs.remove('username');
    
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _username = prefs.getString('username');
    notifyListeners();
  }
}
