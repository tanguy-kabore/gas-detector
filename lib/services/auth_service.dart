import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUser;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;

  Future<String?> signUp(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getString('users') ?? '{}';
      final Map<String, dynamic> usersMap = json.decode(users);

      if (usersMap.containsKey(email)) {
        return 'Cet email est déjà utilisé';
      }

      // Hash the password in a real app
      usersMap[email] = password;
      await prefs.setString('users', json.encode(usersMap));
      
      _isAuthenticated = true;
      _currentUser = email;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Une erreur est survenue';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = prefs.getString('users') ?? '{}';
      final Map<String, dynamic> usersMap = json.decode(users);

      if (!usersMap.containsKey(email)) {
        return 'Email ou mot de passe incorrect';
      }

      if (usersMap[email] != password) {
        return 'Email ou mot de passe incorrect';
      }

      _isAuthenticated = true;
      _currentUser = email;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Une erreur est survenue';
    }
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('currentUser');
    if (currentUser != null) {
      _isAuthenticated = true;
      _currentUser = currentUser;
      notifyListeners();
    }
  }
}
