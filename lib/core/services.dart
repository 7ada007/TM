import 'core.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'api_data_service.dart';
export 'api_data_service_ext.dart';

class VerificationCodeService {
  static final _random = Random.secure();

  static String generate({int length = 6}) {
    return List.generate(length, (_) => _random.nextInt(10)).join();
  }

  static bool validate(String input, String expected) {
    return input.trim() == expected.trim();
  }
}

class AppSettingsService extends ChangeNotifier {
  static const _notificationsKey = 'settings_notifications';
  static const _themeModeKey = 'settings_theme_mode';

  bool _notificationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;

  bool get notificationsEnabled => _notificationsEnabled;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(_notificationsKey)) {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    }

    final storedMode = prefs.getString(_themeModeKey);
    _themeMode = switch (storedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };

    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}

class AuthService extends ChangeNotifier {
  final ApiDataService _dataService;
  UserModel? _currentUser;

  AuthService(this._dataService) {
    ApiClient.onUnauthorized = () {
      if (_currentUser != null) {
        _currentUser = null;
        notifyListeners();
      }
    };
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;
  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get canAccessAttendance =>
      PermissionUtils.canAccessAttendance(_currentUser);

  bool get canManageAccounts => PermissionUtils.canManageAccounts(_currentUser);

  bool get canManageRoles => PermissionUtils.canManageRoles(_currentUser);

  bool get canUploadLectures => PermissionUtils.canUploadLectures(_currentUser);

  Future<String?> login(String username, String password) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final userJson = response.data['user'];
        await ApiClient.saveToken(token);
        _currentUser = UserModel.fromJson(userJson);
        await ApiClient.saveUserId(_currentUser!.id);

        await _dataService.fetchAllData();
        notifyListeners();
        return null;
      }
      return 'اسم المستخدم أو كلمة المرور غير صحيحة';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return 'اسم المستخدم أو كلمة المرور غير صحيحة';
      }
      return 'فشل الاتصال بالخادم. يرجى المحاولة لاحقاً';
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await ApiClient.clearToken();
    await ApiClient.clearUserId();
    notifyListeners();
  }

  Future<void> tryRestoreSession() async {
    final token = await ApiClient.getToken();
    final userId = await ApiClient.getUserId();
    if (token == null || userId == null) return;

    try {
      final response = await ApiClient.dio.get('/auth/me');
      final user = UserModel.fromJson(response.data);

      _currentUser = user;
      notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        return;
      }

      final cached = _dataService.findUserById(userId);
      if (cached != null) {
        _currentUser = cached;
        notifyListeners();
      }
    }
  }

  void refreshCurrentUser() {
    if (_currentUser != null) {
      _currentUser = _dataService.findUserById(_currentUser!.id);
      notifyListeners();
    }
  }

  String getHomeRoute() {
    if (_currentUser == null) return '/login';
    switch (_currentUser!.role) {
      case UserRole.admin:
        return '/admin-home';
      case UserRole.teacher:
        return '/teacher-home';
      case UserRole.student:
        return '/home';
    }
  }
}
