import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'http_cache_service.dart';

class HomeService {
  static final HomeService _instance = HomeService._internal();
  factory HomeService() => _instance;
  HomeService._internal();

  late final Dio _dio;
  late final FlutterSecureStorage _storage;

  /// Inicializar el servicio
  Future<void> initialize() async {
    _dio = Dio(
      BaseOptions(
        // Configurar validateStatus globalmente para aceptar todos los códigos
        // Esto previene excepciones por errores 500 que no son críticos
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    _storage = const FlutterSecureStorage();
    _setupInterceptors();
  }

  /// Configurar interceptores
  void _setupInterceptors() {
    _dio.interceptors.clear(); // Limpiar interceptores existentes
    
    // Agregar caché HTTP si está disponible
    if (HttpCacheService.cacheOptions != null) {
      _dio.interceptors.add(
        DioCacheInterceptor(options: HttpCacheService.cacheOptions!),
      );
    }
    
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
          // No loguear errores - ya se manejan en cada método individualmente
          // Esto evita logs innecesarios que causan lag en el main thread
          handler.next(error);
        },
      ),
    );

    // LogInterceptor deshabilitado para mejor rendimiento
  }

  /// Obtener artistas destacados
  Future<List<FeaturedArtist>> getFeaturedArtists({int limit = 6}) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/featured/artists',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['artists'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          return [];
        }
        
        return validData.asMap().entries.map((entry) {
          try {
            final artist = Artist.fromJson(entry.value as Map<String, dynamic>);
            return FeaturedArtist(
              artist: artist,
              featuredReason: 'Destacado',
              rank: entry.key + 1,
            );
          } catch (e) {
            return null;
          }
        }).where((item) => item != null).cast<FeaturedArtist>().toList();
      } else {
        return [];
      }
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtener canciones destacadas desde el admin
  /// Estas son las canciones que el administrador ha marcado como destacadas
  Future<List<FeaturedSong>> getFeaturedSongs({int limit = 20, bool forceRefresh = false}) async {
    try {
      final url = '${ApiConfig.baseUrl}/public/featured/songs';
      
      // Agregar timestamp para evitar caché si se fuerza el refresh
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      
      if (forceRefresh) {
        queryParams['_t'] = DateTime.now().millisecondsSinceEpoch;
      }
      
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
      );

        if (response.statusCode == 200 && response.data != null) {
          final List<dynamic> data = response.data is List 
              ? response.data 
              : (response.data['songs'] ?? []);
          
          if (data.isEmpty) {
            return [];
          }

        final featuredSongs = <FeaturedSong>[];
        
          for (var i = 0; i < data.length; i++) {
          try {
            final songData = data[i] as Map<String, dynamic>;
            
            // Asegurar que el artista se parsee correctamente
            Song song;
            if (songData.containsKey('artist') && songData['artist'] != null) {
              try {
                final artistData = songData['artist'] as Map<String, dynamic>;
                
                // Normalizar los datos del artista para manejar tanto camelCase como snake_case
                final normalizedArtistData = <String, dynamic>{};
                artistData.forEach((key, value) {
                  if (key == 'stageName') {
                    normalizedArtistData['stage_name'] = value;
                  } else if (key == 'userId') {
                    normalizedArtistData['user_id'] = value;
                  } else if (key == 'verificationStatus') {
                    normalizedArtistData['verification_status'] = value;
                  } else if (key == 'totalStreams') {
                    normalizedArtistData['total_streams'] = value;
                  } else if (key == 'totalFollowers') {
                    normalizedArtistData['total_followers'] = value;
                  } else if (key == 'monthlyListeners') {
                    normalizedArtistData['monthly_listeners'] = value;
                  } else if (key == 'websiteUrl') {
                    normalizedArtistData['website_url'] = value;
                  } else if (key == 'socialLinks') {
                    normalizedArtistData['social_links'] = value;
                  } else if (key == 'createdAt') {
                    normalizedArtistData['created_at'] = value;
                  } else if (key == 'updatedAt') {
                    normalizedArtistData['updated_at'] = value;
                  } else {
                    normalizedArtistData[key] = value;
                  }
                });
                
                final artist = Artist.fromJson(normalizedArtistData);
                final tempSong = Song.fromJson(songData);
                
                final rawCoverUrl = tempSong.coverArtUrl ?? 
                                   songData['cover_art_url'] as String? ?? 
                                   songData['coverArtUrl'] as String? ??
                                   songData['coverImageUrl'] as String? ??
                                   songData['cover_image_url'] as String?;
                
                final normalizedCoverUrl = _normalizeCoverUrl(rawCoverUrl);
                
                song = Song(
                  id: tempSong.id,
                  artistId: tempSong.artistId,
                  albumId: tempSong.albumId,
                  title: tempSong.title,
                  duration: tempSong.duration,
                  fileUrl: tempSong.fileUrl,
                  coverArtUrl: normalizedCoverUrl,
                  lyrics: tempSong.lyrics,
                  genreId: tempSong.genreId,
                  trackNumber: tempSong.trackNumber,
                  status: tempSong.status,
                  isExplicit: tempSong.isExplicit,
                  releaseDate: tempSong.releaseDate,
                  totalStreams: tempSong.totalStreams,
                  totalLikes: tempSong.totalLikes,
                  totalShares: tempSong.totalShares,
                  createdAt: tempSong.createdAt,
                  updatedAt: tempSong.updatedAt,
                  artist: artist,
                );
              } catch (e) {
                final tempSong = Song.fromJson(songData);
                final rawCoverUrl = tempSong.coverArtUrl ?? 
                                   songData['cover_art_url'] as String? ?? 
                                   songData['coverArtUrl'] as String? ??
                                   songData['coverImageUrl'] as String? ??
                                   songData['cover_image_url'] as String?;
                final normalizedCoverUrl = _normalizeCoverUrl(rawCoverUrl);
                song = Song(
                  id: tempSong.id,
                  artistId: tempSong.artistId,
                  albumId: tempSong.albumId,
                  title: tempSong.title,
                  duration: tempSong.duration,
                  fileUrl: tempSong.fileUrl,
                  coverArtUrl: normalizedCoverUrl,
                  lyrics: tempSong.lyrics,
                  genreId: tempSong.genreId,
                  trackNumber: tempSong.trackNumber,
                  status: tempSong.status,
                  isExplicit: tempSong.isExplicit,
                  releaseDate: tempSong.releaseDate,
                  totalStreams: tempSong.totalStreams,
                  totalLikes: tempSong.totalLikes,
                  totalShares: tempSong.totalShares,
                  createdAt: tempSong.createdAt,
                  updatedAt: tempSong.updatedAt,
                  artist: tempSong.artist,
                );
              }
            } else {
              final tempSong = Song.fromJson(songData);
              
              final rawCoverUrl = tempSong.coverArtUrl ?? 
                                 songData['cover_art_url'] as String? ?? 
                                 songData['coverArtUrl'] as String? ??
                                 songData['coverImageUrl'] as String? ??
                                 songData['cover_image_url'] as String?;
              
              final normalizedCoverUrl = _normalizeCoverUrl(rawCoverUrl);
              
              song = Song(
                id: tempSong.id,
                artistId: tempSong.artistId,
                albumId: tempSong.albumId,
                title: tempSong.title,
                duration: tempSong.duration,
                fileUrl: tempSong.fileUrl,
                coverArtUrl: normalizedCoverUrl,
                lyrics: tempSong.lyrics,
                genreId: tempSong.genreId,
                trackNumber: tempSong.trackNumber,
                status: tempSong.status,
                isExplicit: tempSong.isExplicit,
                releaseDate: tempSong.releaseDate,
                totalStreams: tempSong.totalStreams,
                totalLikes: tempSong.totalLikes,
                totalShares: tempSong.totalShares,
                createdAt: tempSong.createdAt,
                updatedAt: tempSong.updatedAt,
                artist: tempSong.artist,
              );
            }
            
            featuredSongs.add(
              FeaturedSong(
                song: song,
                featuredReason: 'Destacada por el administrador',
                rank: i + 1,
              ),
            );
          } catch (e) {
            // Error silencioso al parsear canción individual
          }
        }

        return featuredSongs;
      } else {
        return [];
      }
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }


  /// Obtener canciones populares
  /// Si el endpoint falla, retorna lista vacía silenciosamente (no afecta la UI)
  Future<List<Song>> getPopularSongs({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/songs/top',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['songs'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          return [];
        }
        
        return validData.map((json) {
          try {
            return Song.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            // Error silencioso al parsear canción individual
            return null;
          }
        }).where((item) => item != null).cast<Song>().toList();
      } else {
        // Error silencioso - el endpoint puede no estar disponible (500, etc.)
        return [];
      }
    } on DioException {
      // Error silencioso - no loguear para evitar spam en consola
      // El endpoint puede no estar disponible o tener problemas en el backend
      return [];
    } catch (_) {
      // Error silencioso
      return [];
    }
  }

  /// Obtener artistas más escuchados
  Future<List<Artist>> getTopArtists({int limit = 8}) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/artists/top',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['artists'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          return [];
        }
        
        return validData.map((json) {
          try {
            return Artist.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        }).where((item) => item != null).cast<Artist>().toList();
      } else {
        return [];
      }
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtener playlists destacadas
  Future<List<FeaturedPlaylist>> getFeaturedPlaylists({int limit = 6}) async {
    try {
      final url = '${ApiConfig.baseUrl}/public/featured/playlists';
      final response = await _dio.get(
        url,
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          return [];
        }
        
        final playlists = <FeaturedPlaylist>[];
        for (var i = 0; i < validData.length; i++) {
          try {
            final item = validData[i] as Map<String, dynamic>;
            
            // Normalizar coverArtUrl antes de parsear (convertir localhost a 10.0.2.2)
            final coverArtUrl = item['coverArtUrl'] ?? item['cover_art_url'];
            if (coverArtUrl != null && coverArtUrl is String && coverArtUrl.isNotEmpty) {
              final normalizedCoverUrl = _normalizeCoverUrl(coverArtUrl);
              if (normalizedCoverUrl != null && normalizedCoverUrl.isNotEmpty) {
                item['coverArtUrl'] = normalizedCoverUrl;
                item['cover_art_url'] = normalizedCoverUrl;
              }
            }
            
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
            }
            
            final playlist = Playlist.fromJson(item);
            final featuredPlaylist = FeaturedPlaylist(
              playlist: playlist,
              featuredReason: 'Destacada',
              rank: i + 1,
            );
            playlists.add(featuredPlaylist);
          } catch (e) {
            // Error silencioso al parsear playlist individual
          }
        }
        
        return playlists;
      } else {
        return [];
      }
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Normalizar URL de portada: convertir ruta relativa a absoluta si es necesario
  String? _normalizeCoverUrl(String? coverUrl) {
    if (coverUrl == null || coverUrl.isEmpty) {
      return null;
    }

    // Si ya es una URL completa (http:// o https://), normalizarla para el emulador
    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      if (coverUrl.contains('localhost') || coverUrl.contains('127.0.0.1')) {
        return coverUrl.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
      }
      return coverUrl;
    }

    // Extraer el dominio base de ApiConfig
    final baseUrl = ApiConfig.baseUrl;
    String cleanBaseUrl = baseUrl.replaceAll('/api/v1', '').replaceAll(RegExp(r'/$'), '');
    
    // Asegurar que use 10.0.2.2 en lugar de localhost para emulador
    if (cleanBaseUrl.contains('localhost') || cleanBaseUrl.contains('127.0.0.1')) {
      cleanBaseUrl = cleanBaseUrl.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
    }

    // Si es una ruta relativa que empieza con /uploads, construir URL completa
    if (coverUrl.startsWith('/uploads/')) {
      return '$cleanBaseUrl$coverUrl';
    }

    // Si es una ruta relativa sin /, agregar /uploads/covers/
    if (!coverUrl.startsWith('/')) {
      return '$cleanBaseUrl/uploads/covers/$coverUrl';
    }

    // Si ya tiene / al inicio pero no es /uploads, construir URL completa
    return '$cleanBaseUrl$coverUrl';
  }

}
