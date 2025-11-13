class AppConfig {
  // Configuración de la aplicación
  static const String appName = 'Vintage Music';
  static const String appVersion = '1.0.0';

  // Configuración de la API
  // Usa localhost para desarrollo web, 10.0.2.2 para emulador Android, o tu IP local para dispositivo físico
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    // Intentar obtener la URL desde variables de entorno
    final rawBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    // Si no hay URL desde environment, usar la URL de producción por defecto
    final urlToUse = rawBaseUrl.isEmpty 
        ? 'http://backend-alb-1038609925.us-east-1.elb.amazonaws.com'
        : rawBaseUrl;

    try {
      final uri = Uri.parse(urlToUse);
      // Siempre agregar api/v1 al final
      final segments = <String>[
        for (final segment in uri.pathSegments)
          if (segment.isNotEmpty) segment,
      ];
      
      segments.addAll(['api', 'v1']);

      final finalUrl = _removeTrailingSlash(
        uri.replace(pathSegments: segments).toString(),
      );
      
      // Debug: imprimir la URL que se está usando
      print('🔗 API Base URL configurada: $finalUrl');
      print('🔗 URL raw desde environment: $rawBaseUrl');
      print('🔗 URL final usada: $urlToUse');
      
      return finalUrl;
    } catch (e) {
      print('⚠️ Error al parsear URL, usando producción por defecto: $e');
      // Usar URL de producción por defecto en lugar de localhost
      return 'http://backend-alb-1038609925.us-east-1.elb.amazonaws.com/api/v1';
    }
  }

  static String _removeTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  // Endpoints de autenticación
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String changePasswordEndpoint = '/auth/change-password';
  static const String profileEndpoint = '/auth/profile';
  
  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Configuración de reintentos
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Configuración de almacenamiento
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';
  
  // Configuración de validación
  static const int minPasswordLength = 8;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  
  // Configuración de UI
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double buttonHeight = 56.0;
}
