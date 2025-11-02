import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import '../config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final Dio _dio;
  late final FlutterSecureStorage _secureStorage;

  // Claves para el almacenamiento seguro
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _refreshTokenKey = 'refresh_token';

  // Estado de autenticación
  User? _currentUser;
  String? _accessToken;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _currentUser != null && _accessToken != null;
  bool get isInitialized => _isInitialized;

  /// Inicializar el servicio de autenticación
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _dio = Dio();
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      // Configurar interceptores
      _setupInterceptors();

      // Cargar datos de autenticación guardados
      try {
        await _loadStoredAuthData();
      } catch (e) {
        debugPrint('Error cargando datos guardados: $e');
        // Continuar sin datos guardados
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error inicializando AuthService: $e');
      _isInitialized = true; // Marcar como inicializado de todos modos
    }
  }

  /// Configurar interceptores de Dio
  void _setupInterceptors() {
    // Interceptor de autenticación
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar token de autorización si existe
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Manejar errores de autenticación
          if (error.response?.statusCode == 401) {
            await _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    );

    // Interceptor de logging (solo en debug)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (object) {
          // Solo loggear en modo debug
          if (const bool.fromEnvironment('dart.vm.product') == false) {
            // Usar debugPrint en lugar de print
            debugPrint('Dio: $object');
          }
        },
      ),
    );
  }

  /// Cargar datos de autenticación guardados
  Future<void> _loadStoredAuthData() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final userData = await _secureStorage.read(key: _userKey);

      if (token != null && userData != null) {
        _accessToken = token;
        _currentUser = User.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      // Si hay error al cargar datos, limpiar todo
      await _clearAuthData();
    }
  }

  /// Verificar conectividad
  Future<bool> _checkConnectivity() async {
    try {
      // Crear una instancia temporal de Dio con timeouts cortos
      final tempDio = Dio();
      tempDio.options.connectTimeout = const Duration(seconds: 5);
      tempDio.options.receiveTimeout = const Duration(seconds: 5);
      
      // Intentar hacer una petición simple al backend para verificar conectividad
      final response = await tempDio.get('${ApiConfig.baseUrl}/health');
      return response.statusCode == 200;
    } catch (e) {
      // Si no hay endpoint de health, intentar con el endpoint de login
      try {
        final tempDio = Dio();
        tempDio.options.connectTimeout = const Duration(seconds: 5);
        tempDio.options.receiveTimeout = const Duration(seconds: 5);
        
        await tempDio.get('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
        return true; // Si responde (aunque sea con error), hay conectividad
      } catch (e) {
        return false;
      }
    }
  }

  /// Login de usuario
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (!await _checkConnectivity()) {
      throw AuthException('Sin conexión a internet');
    }

    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
        data: LoginRequest(
          email: email,
          password: password,
        ).toJson(),
        options: Options(
          headers: ApiConfig.defaultHeaders,
        ),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        await _saveAuthData(authResponse);
        return authResponse;
      } else {
        throw AuthException('Error en el servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('Error inesperado: $e');
    }
  }

  /// Registro de usuario
  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    UserRole? role,
    String? stageName,
  }) async {
    if (!await _checkConnectivity()) {
      throw AuthException('Sin conexión a internet');
    }

    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}';
      debugPrint('🚀 Intentando registrar en: $url');
      
      final response = await _dio.post(
        url,
        data: RegisterRequest(
          email: email,
          username: username,
          password: password,
          firstName: firstName,
          lastName: lastName,
          role: role,
          stageName: stageName,
        ).toJson(),
        options: Options(
          headers: ApiConfig.defaultHeaders,
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('🔍 Respuesta del backend: ${response.data}');
        try {
          // Debug: Verificar estructura antes de parsear
          final data = response.data as Map<String, dynamic>;
          debugPrint('🔍 Estructura de datos:');
          debugPrint('  - access_token: ${data['access_token'] != null ? "presente" : "ausente"}');
          debugPrint('  - user: ${data['user'] != null ? "presente" : "ausente"}');
          
          if (data['user'] != null) {
            final userData = data['user'] as Map<String, dynamic>;
            debugPrint('  - user.id: ${userData['id']}');
            debugPrint('  - user.email: ${userData['email']}');
            debugPrint('  - user.username: ${userData['username']}');
            debugPrint('  - user.first_name: ${userData['first_name']}');
            debugPrint('  - user.last_name: ${userData['last_name']}');
            debugPrint('  - user.role: ${userData['role']}');
            debugPrint('  - user.subscription_status: ${userData['subscription_status']}');
          }
          
          // Validar que los campos requeridos del user no sean null
          if (data['user'] != null) {
            final userData = data['user'] as Map<String, dynamic>;
            // Asegurar que los campos requeridos no sean null
            if (userData['first_name'] == null && userData['firstName'] == null) {
              debugPrint('❌ Error: first_name/firstName es null');
              throw AuthException('El campo first_name es requerido pero está ausente');
            }
            if (userData['last_name'] == null && userData['lastName'] == null) {
              debugPrint('❌ Error: last_name/lastName es null');
              throw AuthException('El campo last_name es requerido pero está ausente');
            }
            
            // Normalizar a snake_case si viene en camelCase
            if (userData.containsKey('firstName') && !userData.containsKey('first_name')) {
              userData['first_name'] = userData['firstName'];
              userData.remove('firstName');
            }
            if (userData.containsKey('lastName') && !userData.containsKey('last_name')) {
              userData['last_name'] = userData['lastName'];
              userData.remove('lastName');
            }
            if (userData.containsKey('avatarUrl') && !userData.containsKey('avatar_url')) {
              userData['avatar_url'] = userData['avatarUrl'];
              userData.remove('avatarUrl');
            }
            if (userData.containsKey('subscriptionStatus') && !userData.containsKey('subscription_status')) {
              userData['subscription_status'] = userData['subscriptionStatus'];
              userData.remove('subscriptionStatus');
            }
            if (userData.containsKey('isVerified') && !userData.containsKey('is_verified')) {
              userData['is_verified'] = userData['isVerified'];
              userData.remove('isVerified');
            }
            if (userData.containsKey('isActive') && !userData.containsKey('is_active')) {
              userData['is_active'] = userData['isActive'];
              userData.remove('isActive');
            }
            if (userData.containsKey('lastLoginAt') && !userData.containsKey('last_login_at')) {
              userData['last_login_at'] = userData['lastLoginAt'];
              userData.remove('lastLoginAt');
            }
            if (userData.containsKey('createdAt') && !userData.containsKey('created_at')) {
              userData['created_at'] = userData['createdAt'];
              userData.remove('createdAt');
            }
            if (userData.containsKey('updatedAt') && !userData.containsKey('updated_at')) {
              userData['updated_at'] = userData['updatedAt'];
              userData.remove('updatedAt');
            }
          }
          
          final authResponse = AuthResponse.fromJson(data);
          await _saveAuthData(authResponse);
          return authResponse;
        } catch (parseError, stackTrace) {
          debugPrint('❌ Error parseando JSON: $parseError');
          debugPrint('❌ Stack trace: $stackTrace');
          debugPrint('❌ Datos recibidos: ${response.data}');
          throw AuthException('Error parseando respuesta del servidor: $parseError');
        }
      } else {
        throw AuthException('Error en el servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('Error inesperado: $e');
    }
  }

  /// Cambiar contraseña
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) {
      throw AuthException('Usuario no autenticado');
    }

    if (!await _checkConnectivity()) {
      throw AuthException('Sin conexión a internet');
    }

    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.changePasswordEndpoint}',
        data: ChangePasswordRequest(
          oldPassword: oldPassword,
          newPassword: newPassword,
        ).toJson(),
        options: Options(
          headers: ApiConfig.defaultHeaders,
        ),
      );

      if (response.statusCode != 200) {
        throw AuthException('Error al cambiar contraseña: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('Error inesperado: $e');
    }
  }

  /// Refrescar token
  Future<void> refreshToken() async {
    if (!await _checkConnectivity()) {
      throw AuthException('Sin conexión a internet');
    }

    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.refreshTokenEndpoint}',
        options: Options(
          headers: ApiConfig.defaultHeaders,
        ),
      );

      if (response.statusCode == 200) {
        final refreshResponse = RefreshTokenResponse.fromJson(response.data);
        _accessToken = refreshResponse.accessToken;
        await _secureStorage.write(key: _tokenKey, value: _accessToken);
      } else {
        throw AuthException('Error al refrescar token: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('Error inesperado: $e');
    }
  }

  /// Obtener perfil del usuario
  Future<User> getProfile() async {
    if (!isAuthenticated) {
      throw AuthException('Usuario no autenticado');
    }

    if (!await _checkConnectivity()) {
      throw AuthException('Sin conexión a internet');
    }

    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}',
        options: Options(
          headers: ApiConfig.defaultHeaders,
        ),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        _currentUser = user;
        await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
        return user;
      } else {
        throw AuthException('Error al obtener perfil: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('Error inesperado: $e');
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _clearAuthData();
  }

  /// Guardar datos de autenticación
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    _accessToken = authResponse.accessToken;
    _currentUser = authResponse.user;

    await _secureStorage.write(key: _tokenKey, value: _accessToken);
    await _secureStorage.write(key: _userKey, value: jsonEncode(_currentUser!.toJson()));
  }

  /// Limpiar datos de autenticación
  Future<void> _clearAuthData() async {
    _accessToken = null;
    _currentUser = null;

    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  /// Manejar error no autorizado
  Future<void> _handleUnauthorized() async {
    await _clearAuthData();
    // Aquí podrías emitir un evento o notificar a la UI
  }

  /// Manejar errores de Dio
  AuthException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AuthException('Tiempo de espera agotado. Verifica tu conexión.');
      
      case DioExceptionType.connectionError:
        // Verificar si es un problema de DNS o conectividad
        if (e.message?.contains('Failed host lookup') == true) {
          return AuthException('No se puede conectar al servidor. Verifica tu internet y que el backend esté ejecutándose.');
        } else if (e.message?.contains('Connection refused') == true) {
          return AuthException('El servidor no está disponible. Verifica que el backend esté ejecutándose en el puerto 3000.');
        } else {
          return AuthException('Error de conexión. Verifica tu internet.');
        }
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        
        if (statusCode == 401) {
          return AuthException('Credenciales inválidas');
        } else if (statusCode == 409) {
          final message = data?['message'] ?? 'Conflicto en los datos';
          return AuthException(message);
        } else if (statusCode == 400) {
          final message = data?['message'] ?? 'Datos inválidos';
          return AuthException(message);
        } else if (statusCode == 500) {
          return AuthException('Error interno del servidor');
        } else {
          return AuthException('Error del servidor: $statusCode');
        }
      
      case DioExceptionType.cancel:
        return AuthException('Operación cancelada');
      
      case DioExceptionType.unknown:
      default:
        // Verificar si es un problema de conectividad específico
        if (e.message?.contains('Failed host lookup') == true) {
          return AuthException('No se puede conectar al servidor. Verifica tu internet y que el backend esté ejecutándose.');
        } else if (e.message?.contains('Connection refused') == true) {
          return AuthException('El servidor no está disponible. Verifica que el backend esté ejecutándose en el puerto 3000.');
        } else {
          return AuthException('Error desconocido: ${e.message}');
        }
    }
  }
}

/// Excepción personalizada para errores de autenticación
class AuthException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const AuthException(this.message, {this.code, this.details});

  @override
  String toString() => 'AuthException: $message';
}
