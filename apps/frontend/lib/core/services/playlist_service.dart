import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';
import '../config/api_config.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  Dio? _dio;
  FlutterSecureStorage? _storage;
  bool _initialized = false;

  /// Inicializar el servicio
  Future<void> initialize() async {
    if (_initialized && _dio != null) {
      return; // Ya está inicializado
    }
    
    _dio = Dio();
    _storage = const FlutterSecureStorage();
    _setupInterceptors();
    _initialized = true;
  }

  /// Configurar interceptores
  void _setupInterceptors() {
    if (_dio == null) return;
    
    _dio!.interceptors.clear(); // Limpiar interceptores existentes
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar headers por defecto
          options.headers.addAll(ApiConfig.defaultHeaders);
          
          // Agregar token de autenticación
          final token = await _storage?.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          handler.next(options);
        },
        onError: (error, handler) {
          AppLogger.error('Error en PlaylistService: ${error.message}');
          handler.next(error);
        },
      ),
    );

    // Interceptor de logging (solo en debug)
    _dio!.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (object) {
          if (kDebugMode) {
            AppLogger.debug('PlaylistService: $object');
          }
        },
      ),
    );
  }

  /// Obtener todas las playlists
  Future<List<Playlist>> getPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (_dio == null) {
        AppLogger.error('PlaylistService: Dio no está inicializado');
        return [];
      }
      
      AppLogger.playlist('PlaylistService: Obteniendo playlists desde ${ApiConfig.baseUrl}/public/playlists');
      final response = await _dio!.get(
        '${ApiConfig.baseUrl}/public/playlists',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      AppLogger.network('PlaylistService: Respuesta playlists - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is Map<String, dynamic>
            ? (response.data['playlists'] ?? [])
            : (response.data is List ? response.data : []);
        
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          AppLogger.warning('PlaylistService: No hay playlists disponibles');
          return [];
        }
        
        return validData.map((json) {
          try {
            return Playlist.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            AppLogger.error('Error al parsear playlist', e);
            return null;
          }
        }).where((item) => item != null).cast<Playlist>().toList();
      } else {
        AppLogger.error('PlaylistService: Error playlists - Status: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      AppLogger.error('PlaylistService: DioException en playlists: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.error('PlaylistService: Error inesperado en playlists', e);
      return [];
    }
  }

  /// Obtener playlist por ID con sus canciones
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      // Validar que el ID no esté vacío
      if (id.isEmpty || id.trim().isEmpty) {
        AppLogger.error('PlaylistService: ID de playlist vacío o inválido');
        return null;
      }
      
      if (_dio == null) {
        AppLogger.error('PlaylistService: Dio no está inicializado');
        return null;
      }
      
      final url = '${ApiConfig.baseUrl}/public/playlists/${id.trim()}';
      final response = await _dio!.get(url);
      AppLogger.network('PlaylistService: Respuesta playlist - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        try {
          final jsonData = response.data as Map<String, dynamic>;
          
          // Normalizar datos (el backend ya devuelve camelCase, solo normalizar URLs y canciones)
          final normalizedData = _normalizePlaylistData(jsonData);
          
          // Parsear playlist (el modelo ahora soporta playlistSongs)
          Playlist playlist;
          try {
            playlist = Playlist.fromJson(normalizedData);
          } catch (e, stackTrace) {
            AppLogger.error('PlaylistService: Error parseando Playlist desde JSON', e, stackTrace);
            if (kDebugMode) {
              AppLogger.debug('   - Datos normalizados que fallaron: ${normalizedData.keys.toList()}');
              AppLogger.debug('   - playlistSongs count en datos: ${normalizedData['playlistSongs'] != null && normalizedData['playlistSongs'] is List ? (normalizedData['playlistSongs'] as List).length : 0}');
            }
            return null;
          }
          
          if (kDebugMode && playlist.songs.isEmpty && (playlist.playlistSongs?.isNotEmpty ?? false)) {
            AppLogger.warning('PlaylistService: Playlist "${playlist.name}" tiene ${playlist.playlistSongs!.length} playlistSongs pero 0 canciones extraídas');
          }
          
          return playlist;
        } catch (e, stackTrace) {
          AppLogger.error('PlaylistService: Error parseando playlist', e, stackTrace);
          if (kDebugMode) {
            AppLogger.debug('   - Error type: ${e.runtimeType}');
            AppLogger.debug('   - Error message: ${e.toString()}');
            if (e is TypeError) {
              AppLogger.debug('   - TypeError: ${e.toString()}');
            }
            if (e is FormatException) {
              AppLogger.debug('   - FormatException: ${e.toString()}');
            }
          }
          return null;
        }
      } else {
        AppLogger.error('PlaylistService: Error playlist - Status: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      AppLogger.error('PlaylistService: DioException en playlist: ${e.message}');
      if (e.response?.statusCode == 404) {
        AppLogger.warning('PlaylistService: Playlist no encontrada (404) - ID: $id');
        AppLogger.debug('   - URL: ${e.requestOptions.uri}');
        AppLogger.debug('   - ID recibido: "$id" (longitud: ${id.length})');
        AppLogger.debug('   - ID es vacío: ${id.isEmpty}');
      }
      if (kDebugMode && e.response != null) {
        AppLogger.debug('   - Status: ${e.response?.statusCode}');
        AppLogger.debug('   - Data: ${e.response?.data}');
        AppLogger.debug('   - URL: ${e.requestOptions.uri}');
        AppLogger.debug('   - Request Options: ${e.requestOptions.uri}');
        AppLogger.debug('   - Response Data: ${e.response?.data}');
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('PlaylistService: Error inesperado en playlist', e, stackTrace);
      if (kDebugMode) {
        AppLogger.debug('   - ID: $id');
        AppLogger.debug('   - Error type: ${e.runtimeType}');
      }
      return null;
    }
  }

  /// Obtener canciones de una playlist
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    try {
      // Obtener la playlist completa que incluye las canciones
      final playlist = await getPlaylistById(playlistId);
      
      if (playlist == null) {
        AppLogger.warning('PlaylistService: Playlist no encontrada para obtener canciones');
        return [];
      }

      // Usar el getter songs del modelo Playlist que extrae las canciones de playlistSongs
      final songs = playlist.songs;
      AppLogger.song('PlaylistService: ${songs.length} canciones obtenidas de playlist $playlistId');
      
      return songs;
    } catch (e) {
      AppLogger.error('PlaylistService: Error obteniendo canciones de playlist', e);
      return [];
    }
  }

  /// Obtener playlists destacadas
  Future<List<Playlist>> getFeaturedPlaylists({int limit = 10}) async {
    try {
      if (_dio == null) {
        AppLogger.error('PlaylistService: Dio no está inicializado');
        return [];
      }
      
      AppLogger.playlist('PlaylistService: Obteniendo playlists destacadas desde ${ApiConfig.baseUrl}/public/playlists/featured');
      final response = await _dio!.get(
        '${ApiConfig.baseUrl}/public/playlists/featured',
        queryParameters: {'limit': limit},
      );
      AppLogger.network('PlaylistService: Respuesta playlists destacadas - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          AppLogger.warning('PlaylistService: No hay playlists destacadas disponibles');
          return [];
        }
        
        return validData.map((json) {
          try {
            return Playlist.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            AppLogger.error('Error al parsear playlist destacada', e);
            return null;
          }
        }).where((item) => item != null).cast<Playlist>().toList();
      } else {
        AppLogger.error('PlaylistService: Error playlists destacadas - Status: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      AppLogger.error('PlaylistService: DioException en playlists destacadas: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.error('PlaylistService: Error inesperado en playlists destacadas', e);
      return [];
    }
  }

  /// Normalizar datos de playlist (el backend ya devuelve camelCase, solo normalizar URLs y canciones)
  Map<String, dynamic> _normalizePlaylistData(Map<String, dynamic> data) {
    // El backend ya devuelve en camelCase, así que trabajamos directamente con los datos
    final normalized = Map<String, dynamic>.from(data);
    
    // Normalizar coverArtUrl y convertir localhost a 10.0.2.2
    final coverUrl = normalized['coverArtUrl'] ?? data['cover_art_url'];
    if (coverUrl != null && coverUrl is String && coverUrl.isNotEmpty) {
      normalized['coverArtUrl'] = _normalizeCoverUrl(coverUrl);
    }
    
    // Normalizar playlistSongs si existen (el backend ya devuelve en camelCase)
    final playlistSongsData = normalized['playlistSongs'] ?? data['playlist_songs'];
    if (playlistSongsData != null && playlistSongsData is List) {
      normalized['playlistSongs'] = playlistSongsData
          .where((item) => item is Map<String, dynamic> && item['song'] != null)
          .map((item) {
            final itemMap = item as Map<String, dynamic>;
            final normalizedItem = Map<String, dynamic>.from(itemMap);
            
            // Normalizar la canción dentro del playlistSong
            if (normalizedItem['song'] is Map<String, dynamic>) {
              try {
                normalizedItem['song'] = _normalizeSongData(normalizedItem['song'] as Map<String, dynamic>);
              } catch (e) {
                // Si falla la normalización de la canción, omitir este playlistSong
                return null;
              }
            }
            
            return normalizedItem;
          })
          .where((item) => item != null)
          .toList();
    }
    
    // Normalizar user si existe
    if (normalized['user'] is Map<String, dynamic>) {
      try {
        normalized['user'] = _normalizeUserData(normalized['user'] as Map<String, dynamic>);
      } catch (e) {
        // Si falla, mantener el user original o eliminarlo
        normalized.remove('user');
      }
    }
    
    return normalized;
  }

  /// Normalizar datos de canción
  /// Convierte camelCase a snake_case porque el modelo Song usa fieldRename: FieldRename.snake
  Map<String, dynamic> _normalizeSongData(Map<String, dynamic> data) {
    // El modelo Song espera snake_case, así que convertimos de camelCase a snake_case
    String toSnakeCase(String key) {
      // Manejar el primer carácter si es mayúscula
      String result = key.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
        final index = match.start;
        // Si no es el primer carácter, agregar guion bajo antes
        return index > 0 ? '_${match.group(0)!.toLowerCase()}' : match.group(0)!.toLowerCase();
      });
      return result;
    }
    
    final normalized = <String, dynamic>{};
    
    // Mapear todos los campos, convirtiendo camelCase a snake_case
    data.forEach((key, value) {
      String snakeKey;
      
      // Si ya está en snake_case, usarlo tal cual
      if (key.contains('_')) {
        snakeKey = key;
      } else {
        // Convertir camelCase a snake_case
        snakeKey = toSnakeCase(key);
      }
      
      // Normalizar artista si existe
      if (snakeKey == 'artist' && value is Map<String, dynamic>) {
        normalized[snakeKey] = _normalizeArtistData(value);
      } else {
        normalized[snakeKey] = value;
      }
    });
    
    // Mapear campos específicos de camelCase a snake_case si es necesario
    final fieldMapping = {
      'artistId': 'artist_id',
      'albumId': 'album_id',
      'fileUrl': 'file_url',
      'coverArtUrl': 'cover_art_url',
      'coverImageUrl': 'cover_art_url', // También aceptar coverImageUrl
      'genreId': 'genre_id',
      'trackNumber': 'track_number',
      'isExplicit': 'is_explicit',
      'releaseDate': 'release_date',
      'totalStreams': 'total_streams',
      'totalLikes': 'total_likes',
      'totalShares': 'total_shares',
      'createdAt': 'created_at',
      'updatedAt': 'updated_at',
    };
    
    // Si hay campos en camelCase que no se mapearon, mapearlos
    fieldMapping.forEach((camelKey, snakeKey) {
      if (data.containsKey(camelKey) && !normalized.containsKey(snakeKey)) {
        normalized[snakeKey] = data[camelKey];
      }
    });
    
    // Normalizar URL de portada - convertir localhost a 10.0.2.2 para emulador Android
    final coverArtUrl = normalized['cover_art_url'] ?? data['coverArtUrl'] ?? data['cover_art_url'] ?? data['coverImageUrl'];
    if (coverArtUrl != null && coverArtUrl is String) {
      normalized['cover_art_url'] = _normalizeCoverUrl(coverArtUrl);
    }
    
    // Asegurar campos requeridos
    if (!normalized.containsKey('title') || normalized['title'] == null) {
      normalized['title'] = data['title'] ?? 'Sin título';
    }
    if (!normalized.containsKey('duration') || normalized['duration'] == null) {
      normalized['duration'] = (data['duration'] ?? 0) as int;
    }
    if (!normalized.containsKey('file_url') || normalized['file_url'] == null) {
      normalized['file_url'] = data['file_url'] ?? data['fileUrl'] ?? '';
    }
    if (!normalized.containsKey('id') || normalized['id'] == null) {
      normalized['id'] = data['id'] ?? '';
    }
    if (!normalized.containsKey('status') || normalized['status'] == null) {
      normalized['status'] = data['status'] ?? 'published';
    }
    
    return normalized;
  }

  /// Normalizar datos de artista
  /// Convierte camelCase a snake_case porque el modelo Artist usa fieldRename: FieldRename.snake
  Map<String, dynamic> _normalizeArtistData(Map<String, dynamic> data) {
    // El modelo Artist espera snake_case
    String toSnakeCase(String key) {
      // Manejar el primer carácter si es mayúscula
      String result = key.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
        final index = match.start;
        // Si no es el primer carácter, agregar guion bajo antes
        return index > 0 ? '_${match.group(0)!.toLowerCase()}' : match.group(0)!.toLowerCase();
      });
      return result;
    }
    
    final normalized = <String, dynamic>{};
    
    // Mapear todos los campos, convirtiendo camelCase a snake_case
    data.forEach((key, value) {
      String snakeKey;
      
      // Si ya está en snake_case, usarlo tal cual
      if (key.contains('_')) {
        snakeKey = key;
      } else {
        // Convertir camelCase a snake_case
        snakeKey = toSnakeCase(key);
      }
      
      // Normalizar user si existe (aunque probablemente no venga en artist)
      if (snakeKey == 'user' && value is Map<String, dynamic>) {
        normalized[snakeKey] = _normalizeUserData(value);
      } else {
        normalized[snakeKey] = value;
      }
    });
    
    // Mapear campos específicos de camelCase a snake_case
    final fieldMapping = {
      'userId': 'user_id',
      'stageName': 'stage_name',
      'websiteUrl': 'website_url',
      'socialLinks': 'social_links',
      'verificationStatus': 'verification_status',
      'totalStreams': 'total_streams',
      'totalFollowers': 'total_followers',
      'monthlyListeners': 'monthly_listeners',
      'createdAt': 'created_at',
      'updatedAt': 'updated_at',
    };
    
    // Si hay campos en camelCase que no se mapearon, mapearlos
    fieldMapping.forEach((camelKey, snakeKey) {
      if (data.containsKey(camelKey) && !normalized.containsKey(snakeKey)) {
        normalized[snakeKey] = data[camelKey];
      }
    });
    
    // Asegurar campos requeridos
    if (!normalized.containsKey('id') || normalized['id'] == null) {
      normalized['id'] = data['id'] ?? '';
    }
    if (!normalized.containsKey('stage_name') || normalized['stage_name'] == null) {
      normalized['stage_name'] = data['stage_name'] ?? data['stageName'] ?? '';
    }
    if (!normalized.containsKey('total_streams') || normalized['total_streams'] == null) {
      normalized['total_streams'] = data['total_streams'] ?? data['totalStreams'] ?? 0;
    }
    
    return normalized;
  }

  /// Normalizar datos de usuario
  /// Convierte camelCase a snake_case y asegura campos requeridos
  Map<String, dynamic> _normalizeUserData(Map<String, dynamic> data) {
    // El modelo User espera snake_case (fieldRename: FieldRename.snake)
    String toSnakeCase(String key) {
      // Manejar el primer carácter si es mayúscula
      String result = key.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
        final index = match.start;
        // Si no es el primer carácter, agregar guion bajo antes
        return index > 0 ? '_${match.group(0)!.toLowerCase()}' : match.group(0)!.toLowerCase();
      });
      return result;
    }
    
    final normalized = <String, dynamic>{};
    
    // Mapear todos los campos, convirtiendo camelCase a snake_case
    data.forEach((key, value) {
      String snakeKey;
      
      // Si ya está en snake_case, usarlo tal cual
      if (key.contains('_')) {
        snakeKey = key;
      } else {
        // Convertir camelCase a snake_case
        snakeKey = toSnakeCase(key);
      }
      
      normalized[snakeKey] = value;
    });
    
    // Mapear campos específicos de camelCase a snake_case
    final fieldMapping = {
      'firstName': 'first_name',
      'lastName': 'last_name',
      'avatarUrl': 'avatar_url',
      'subscriptionStatus': 'subscription_status',
      'isVerified': 'is_verified',
      'isActive': 'is_active',
      'lastLoginAt': 'last_login_at',
      'createdAt': 'created_at',
      'updatedAt': 'updated_at',
    };
    
    // Si hay campos en camelCase que no se mapearon, mapearlos
    fieldMapping.forEach((camelKey, snakeKey) {
      if (data.containsKey(camelKey) && !normalized.containsKey(snakeKey)) {
        normalized[snakeKey] = data[camelKey];
      }
    });
    
    // Asegurar campos requeridos con valores por defecto
    // role: UserRole (requerido) - valores: 'user', 'artist', 'admin'
    if (!normalized.containsKey('role') || normalized['role'] == null) {
      normalized['role'] = 'user'; // Valor por defecto
    } else {
      // Normalizar el valor del role (puede venir en camelCase o snake_case)
      final roleValue = normalized['role'].toString().toLowerCase();
      if (roleValue == 'user' || roleValue == 'artist' || roleValue == 'admin') {
        normalized['role'] = roleValue;
      } else {
        // Si el valor no es válido, usar 'user' por defecto
        normalized['role'] = 'user';
      }
    }
    
    // subscriptionStatus: SubscriptionStatus (requerido) - valores: 'FREE', 'PREMIUM', 'VIP', 'inactive'
    if (!normalized.containsKey('subscription_status') || normalized['subscription_status'] == null) {
      normalized['subscription_status'] = 'FREE'; // Valor por defecto
    } else {
      // Normalizar el valor del subscriptionStatus
      final subStatusValue = normalized['subscription_status'].toString().toUpperCase();
      if (subStatusValue == 'FREE' || subStatusValue == 'PREMIUM' || subStatusValue == 'VIP' || subStatusValue == 'INACTIVE') {
        normalized['subscription_status'] = subStatusValue == 'INACTIVE' ? 'inactive' : subStatusValue;
      } else {
        // Si el valor no es válido, usar 'FREE' por defecto
        normalized['subscription_status'] = 'FREE';
      }
    }
    
    // Asegurar campos básicos requeridos
    if (!normalized.containsKey('id') || normalized['id'] == null) {
      normalized['id'] = data['id'] ?? '';
    }
    if (!normalized.containsKey('email') || normalized['email'] == null) {
      normalized['email'] = data['email'] ?? '';
    }
    if (!normalized.containsKey('username') || normalized['username'] == null) {
      normalized['username'] = data['username'] ?? '';
    }
    
    return normalized;
  }

  /// Normalizar URL de portada: convertir ruta relativa a absoluta y localhost a 10.0.2.2
  String? _normalizeCoverUrl(String? coverUrl) {
    if (coverUrl == null || coverUrl.isEmpty) {
      if (kDebugMode) {
        AppLogger.warning('PlaylistService: _normalizeCoverUrl - URL es null o vacía');
      }
      return null;
    }

    if (kDebugMode) {
      AppLogger.debug('PlaylistService: _normalizeCoverUrl - Normalizando "$coverUrl"');
    }

    // Si ya es una URL completa (http:// o https://), normalizarla para el emulador
    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      // Reemplazar localhost con 10.0.2.2 para emulador Android
      String normalizedUrl = coverUrl;
      if (coverUrl.contains('localhost') || coverUrl.contains('127.0.0.1')) {
        normalizedUrl = coverUrl.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
        if (kDebugMode) {
          AppLogger.debug('PlaylistService: URL con localhost convertida a 10.0.2.2: $normalizedUrl');
        }
      }
      if (kDebugMode) {
        AppLogger.success('PlaylistService: URL ya es completa: $normalizedUrl');
      }
      return normalizedUrl;
    }

    // Extraer el dominio base de ApiConfig
    final baseUrl = ApiConfig.baseUrl;
    // Remover /api/v1 si está presente
    String cleanBaseUrl = baseUrl.replaceAll('/api/v1', '').replaceAll(RegExp(r'/$'), '');
    
    // Asegurar que use 10.0.2.2 en lugar de localhost para emulador
    if (cleanBaseUrl.contains('localhost') || cleanBaseUrl.contains('127.0.0.1')) {
      cleanBaseUrl = cleanBaseUrl.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
      if (kDebugMode) {
        AppLogger.debug('PlaylistService: Base URL convertida de localhost a 10.0.2.2: $cleanBaseUrl');
      }
    }
    
    if (kDebugMode) {
      AppLogger.debug('PlaylistService: Base URL limpia: $cleanBaseUrl');
    }

    // Si es una ruta relativa que empieza con /uploads, construir URL completa
    if (coverUrl.startsWith('/uploads/')) {
      final finalUrl = '$cleanBaseUrl$coverUrl';
      if (kDebugMode) {
        AppLogger.success('PlaylistService: URL normalizada (con /uploads): $finalUrl');
      }
      return finalUrl;
    }

    // Si es una ruta relativa sin /, agregar /uploads/covers/
    if (!coverUrl.startsWith('/')) {
      final finalUrl = '$cleanBaseUrl/uploads/covers/$coverUrl';
      if (kDebugMode) {
        AppLogger.success('PlaylistService: URL normalizada (sin /): $finalUrl');
      }
      return finalUrl;
    }

    // Si ya tiene / al inicio pero no es /uploads, construir URL completa
    final finalUrl = '$cleanBaseUrl$coverUrl';
    if (kDebugMode) {
      AppLogger.success('PlaylistService: URL normalizada (otro caso): $finalUrl');
    }
    return finalUrl;
  }

}

