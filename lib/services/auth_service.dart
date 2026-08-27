import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  // حفظ التوكن
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      // على الويب قد تفشل بعض الطرق، نستخدم بديلاً
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  // استرجاع التوكن
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  // حذف التوكن
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // محاولة تسجيل الدخول التلقائي
  Future<void> tryAutoLogin() async {
    try {
      final token = await getToken();
      _isLoggedIn = token != null && token.isNotEmpty;
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
    }
  }
}
