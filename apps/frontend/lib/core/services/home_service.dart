import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

class HomeService {
  static final HomeService _instance = HomeService._internal();
  factory HomeService() => _instance;
  HomeService._internal();

  late final Dio _dio;
  late final FlutterSecureStorage _storage;

  /// Inicializar el servicio
  Future<void> initialize() async {
    _dio = Dio();
    _storage = const FlutterSecureStorage();
    _setupInterceptors();
  }

  /// Configurar interceptores
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar headers por defecto
          options.headers.addAll(ApiConfig.defaultHeaders);
          
          // Agregar token de autenticación
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('❌ Error en HomeService: ${error.message}');
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
          if (kDebugMode) {
            debugPrint('HomeService: $object');
          }
        },
      ),
    );
  }

  /// Obtener artistas destacados (usando top artists como fallback)
  Future<List<FeaturedArtist>> getFeaturedArtists({int limit = 6}) async {
    try {
      debugPrint('🎤 HomeService: Obteniendo artistas destacados desde ${ApiConfig.baseUrl}/public/artists/top');
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/artists/top',
        queryParameters: {'limit': limit},
      );
      debugPrint('🎤 HomeService: Respuesta artistas - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['artists'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          debugPrint('⚠️ HomeService: No hay artistas disponibles, devolviendo lista vacía');
          return [];
        }
        
        return validData.asMap().entries.map((entry) {
          try {
            final artist = Artist.fromJson(entry.value as Map<String, dynamic>);
            return FeaturedArtist(
              artist: artist,
              featuredReason: 'Top ${entry.key + 1}',
              rank: entry.key + 1,
            );
          } catch (e) {
            debugPrint('Error al parsear artista: $e');
            return null;
          }
        }).where((item) => item != null).cast<FeaturedArtist>().toList();
      } else {
        debugPrint('❌ HomeService: Error artistas - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      debugPrint('❌ HomeService: DioException en artistas: ${e.message}');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e) {
      debugPrint('❌ HomeService: Error inesperado en artistas: $e');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    }
  }

  /// Obtener canciones destacadas (usando top songs como fallback)
  Future<List<FeaturedSong>> getFeaturedSongs({int limit = 8}) async {
    try {
      debugPrint('🎵 HomeService: Obteniendo canciones destacadas desde ${ApiConfig.baseUrl}/public/songs/top');
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/songs/top',
        queryParameters: {'limit': limit},
      );
      debugPrint('🎵 HomeService: Respuesta canciones - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['songs'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          debugPrint('⚠️ HomeService: No hay canciones disponibles, devolviendo lista vacía');
          return [];
        }
        
        return validData.asMap().entries.map((entry) {
          try {
            final song = Song.fromJson(entry.value as Map<String, dynamic>);
            return FeaturedSong(
              song: song,
              featuredReason: 'Top ${entry.key + 1}',
              rank: entry.key + 1,
            );
          } catch (e) {
            debugPrint('Error al parsear canción: $e');
            return null;
          }
        }).where((item) => item != null).cast<FeaturedSong>().toList();
      } else {
        debugPrint('❌ HomeService: Error canciones - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      debugPrint('❌ HomeService: DioException en canciones: ${e.message}');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e) {
      debugPrint('❌ HomeService: Error inesperado en canciones: $e');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    }
  }


  /// Obtener canciones populares
  Future<List<Song>> getPopularSongs({int limit = 10}) async {
    try {
      debugPrint('🎵 HomeService: Obteniendo canciones populares desde ${ApiConfig.baseUrl}/public/songs/top');
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/songs/top',
        queryParameters: {'limit': limit},
      );
      debugPrint('🎵 HomeService: Respuesta canciones populares - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['songs'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          debugPrint('⚠️ HomeService: No hay canciones populares disponibles, devolviendo lista vacía');
          return [];
        }
        
        return validData.map((json) {
          try {
            return Song.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error al parsear canción popular: $e');
            return null;
          }
        }).where((item) => item != null).cast<Song>().toList();
      } else {
        debugPrint('❌ HomeService: Error canciones populares - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      debugPrint('❌ HomeService: DioException en canciones populares: ${e.message}');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e) {
      debugPrint('❌ HomeService: Error inesperado en canciones populares: $e');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    }
  }

  /// Obtener artistas más escuchados
  Future<List<Artist>> getTopArtists({int limit = 8}) async {
    try {
      debugPrint('🎤 HomeService: Obteniendo artistas top desde ${ApiConfig.baseUrl}/public/artists/top');
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/artists/top',
        queryParameters: {'limit': limit},
      );
      debugPrint('🎤 HomeService: Respuesta artistas top - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['artists'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          debugPrint('⚠️ HomeService: No hay artistas top disponibles, devolviendo lista vacía');
          return [];
        }
        
        return validData.map((json) {
          try {
            return Artist.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error al parsear artista top: $e');
            return null;
          }
        }).where((item) => item != null).cast<Artist>().toList();
      } else {
        debugPrint('❌ HomeService: Error artistas top - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      debugPrint('❌ HomeService: DioException en artistas top: ${e.message}');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e) {
      debugPrint('❌ HomeService: Error inesperado en artistas top: $e');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    }
  }

  /// Obtener playlists destacadas
  Future<List<FeaturedPlaylist>> getFeaturedPlaylists({int limit = 6}) async {
    try {
      final url = '${ApiConfig.baseUrl}/public/playlists/featured';
      debugPrint('📀 HomeService: Obteniendo playlists destacadas desde $url');
      debugPrint('📀 HomeService: URL completa: $url?limit=$limit');
      
      final response = await _dio.get(
        url,
        queryParameters: {'limit': limit},
      );
      
      debugPrint('📀 HomeService: Respuesta playlists destacadas - Status: ${response.statusCode}');
      debugPrint('📀 HomeService: Tipo de respuesta.data: ${response.data.runtimeType}');
      debugPrint('📀 HomeService: Respuesta.data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        debugPrint('📀 HomeService: Número de playlists en respuesta: ${data.length}');
        
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        debugPrint('📀 HomeService: Número de playlists válidas: ${validData.length}');
        
        if (validData.isEmpty) {
          debugPrint('⚠️ HomeService: No hay playlists destacadas disponibles, devolviendo lista vacía');
          return [];
        }
        
        final playlists = <FeaturedPlaylist>[];
        for (var i = 0; i < validData.length; i++) {
          try {
            final item = validData[i] as Map<String, dynamic>;
            debugPrint('📀 HomeService: Parseando playlist $i: ${item['name']}');
            
            // Transformar el user de camelCase a snake_case si existe
            if (item.containsKey('user') && item['user'] != null) {
              final userData = item['user'] as Map<String, dynamic>;
              
              // Obtener valores con fallback para ambos formatos (camelCase y snake_case)
              String? getStringValue(String camelKey, String snakeKey) {
                final camelValue = userData[camelKey];
                final snakeValue = userData[snakeKey];
                if (camelValue != null) return camelValue.toString();
                if (snakeValue != null) return snakeValue.toString();
                return null;
              }
              
              dynamic getValue(String camelKey, String snakeKey, {dynamic defaultValue}) {
                return userData[camelKey] ?? userData[snakeKey] ?? defaultValue;
              }
              
              final transformedUser = <String, dynamic>{
                'id': getValue('id', 'id', defaultValue: '') as String,
                'email': getValue('email', 'email', defaultValue: '') as String,
                'username': getValue('username', 'username', defaultValue: '') as String,
                'first_name': getStringValue('firstName', 'first_name') ?? '',
                'last_name': getStringValue('lastName', 'last_name') ?? '',
                'avatar_url': getValue('avatarUrl', 'avatar_url'),
                'role': getValue('role', 'role', defaultValue: 'user'),
                'subscription_status': getValue('subscriptionStatus', 'subscription_status', defaultValue: 'inactive'),
                'is_verified': getValue('isVerified', 'is_verified', defaultValue: false),
                'is_active': getValue('isActive', 'is_active', defaultValue: true),
                'last_login_at': getValue('lastLoginAt', 'last_login_at'),
                'created_at': getValue('createdAt', 'created_at'),
                'updated_at': getValue('updatedAt', 'updated_at'),
              };
              
              // Solo incluir campos que no sean null (excepto los que ya tienen defaultValue)
              transformedUser.removeWhere((key, value) => value == null && !['avatar_url', 'last_login_at', 'created_at', 'updated_at'].contains(key));
              
              item['user'] = transformedUser;
              debugPrint('📀 HomeService: User transformado para playlist $i: ${transformedUser['first_name']} ${transformedUser['last_name']}');
            }
            
            final playlist = Playlist.fromJson(item);
            final featuredPlaylist = FeaturedPlaylist(
              playlist: playlist,
              featuredReason: 'Destacada',
              rank: i + 1,
            );
            playlists.add(featuredPlaylist);
            debugPrint('✅ HomeService: Playlist parseada exitosamente: ${playlist.name}');
          } catch (e, stackTrace) {
            debugPrint('❌ HomeService: Error al parsear playlist $i: $e');
            debugPrint('❌ HomeService: Stack trace: $stackTrace');
          }
        }
        
        debugPrint('✅ HomeService: Total de playlists destacadas parseadas: ${playlists.length}');
        return playlists;
      } else {
        debugPrint('❌ HomeService: Error playlists destacadas - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      debugPrint('❌ HomeService: DioException en playlists destacadas: ${e.message}');
      debugPrint('❌ HomeService: DioException tipo: ${e.type}');
      debugPrint('❌ HomeService: DioException response: ${e.response?.data}');
      debugPrint('❌ HomeService: DioException request: ${e.requestOptions.uri}');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e, stackTrace) {
      debugPrint('❌ HomeService: Error inesperado en playlists destacadas: $e');
      debugPrint('❌ HomeService: Stack trace: $stackTrace');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    }
  }

}
