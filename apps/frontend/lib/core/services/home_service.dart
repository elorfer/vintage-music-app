import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';
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
          AppLogger.error('Error en HomeService: ${error.message}');
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
            AppLogger.debug('HomeService: $object');
          }
        },
      ),
    );
  }

  /// Obtener artistas destacados
  Future<List<FeaturedArtist>> getFeaturedArtists({int limit = 6}) async {
    try {
      AppLogger.artist('HomeService: Obteniendo artistas destacados desde ${ApiConfig.baseUrl}/public/featured/artists');
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/featured/artists',
        queryParameters: {'limit': limit},
      );
      AppLogger.network('HomeService: Respuesta artistas destacados - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['artists'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          AppLogger.warning('HomeService: No hay artistas disponibles, devolviendo lista vacía');
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
            AppLogger.error('Error al parsear artista destacado', e);
            return null;
          }
        }).where((item) => item != null).cast<FeaturedArtist>().toList();
      } else {
        AppLogger.error('HomeService: Error artistas - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      AppLogger.error('HomeService: DioException en artistas: ${e.message}');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e) {
      AppLogger.error('HomeService: Error inesperado en artistas', e);
      return []; // Devolver lista vacía en lugar de lanzar excepción
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
        AppLogger.refresh('HomeService: Forzando refresh de canciones destacadas (sin caché)');
      }
      
      AppLogger.network('HomeService: Obteniendo canciones destacadas desde: $url?limit=$limit${forceRefresh ? '&_t=${queryParams['_t']}' : ''}');
      
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
      );

        if (response.statusCode == 200 && response.data != null) {
          // El endpoint devuelve directamente un array de canciones
          final List<dynamic> data = response.data is List 
              ? response.data 
              : (response.data['songs'] ?? []);
          
          if (data.isEmpty) {
            AppLogger.warning('HomeService: No hay canciones destacadas disponibles');
            return [];
          }

          AppLogger.success('HomeService: ${data.length} canciones destacadas recibidas');
          
          // Log de la primera canción para debug (solo en modo debug)
          if (kDebugMode && data.isNotEmpty) {
            final firstSong = data[0] as Map<String, dynamic>;
            AppLogger.debug('HomeService: Primera canción (muestra):');
            AppLogger.debug('   - Keys: ${firstSong.keys.toList()}');
            AppLogger.debug('   - coverArtUrl (camelCase): ${firstSong['coverArtUrl']}');
            AppLogger.debug('   - cover_art_url (snake_case): ${firstSong['cover_art_url']}');
            AppLogger.debug('   - coverImageUrl: ${firstSong['coverImageUrl']}');
            AppLogger.debug('   - cover_image_url: ${firstSong['cover_image_url']}');
            // Mostrar todos los valores relacionados con "cover"
            final coverKeys = firstSong.keys.where((key) => key.toString().toLowerCase().contains('cover')).toList();
            AppLogger.debug('   - Todas las keys con "cover": $coverKeys');
            for (final key in coverKeys) {
              AppLogger.debug('      - $key: ${firstSong[key]}');
            }
          }

        final featuredSongs = <FeaturedSong>[];
        
          for (var i = 0; i < data.length; i++) {
          try {
            final songData = data[i] as Map<String, dynamic>;
            
            if (kDebugMode) {
              AppLogger.song('Parseando canción destacada ${i + 1}:');
              AppLogger.debug('   - Título: ${songData['title']}');
              AppLogger.debug('   - coverArtUrl (raw): ${songData['coverArtUrl']}');
              AppLogger.debug('   - cover_art_url (raw): ${songData['cover_art_url']}');
              AppLogger.debug('   - coverImageUrl (raw): ${songData['coverImageUrl']}');
              AppLogger.debug('   - Keys disponibles: ${songData.keys.toList()}');
            }
            
            // Asegurar que el artista se parsee correctamente
            Song song;
            if (songData.containsKey('artist') && songData['artist'] != null) {
              try {
                // Parsear artista primero
                final artistData = songData['artist'] as Map<String, dynamic>;
                
                if (kDebugMode) {
                  AppLogger.artist('Datos del artista recibidos:');
                  AppLogger.debug('      - Keys: ${artistData.keys.toList()}');
                  AppLogger.debug('      - stage_name: ${artistData['stage_name']}');
                  AppLogger.debug('      - stageName: ${artistData['stageName']}');
                  AppLogger.debug('      - user: ${artistData['user']}');
                  AppLogger.debug('      - Raw data: $artistData');
                }
                
                // Normalizar los datos del artista para manejar tanto camelCase como snake_case
                final normalizedArtistData = <String, dynamic>{};
                artistData.forEach((key, value) {
                  // Convertir camelCase a snake_case si es necesario
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
                    // Mantener el key original si no necesita conversión
                    normalizedArtistData[key] = value;
                  }
                });
                
                if (kDebugMode) {
                  AppLogger.artist('Datos del artista normalizados:');
                  AppLogger.debug('      - stage_name: ${normalizedArtistData['stage_name']}');
                  AppLogger.debug('      - Normalized data: $normalizedArtistData');
                }
                
                final artist = Artist.fromJson(normalizedArtistData);
                
                if (kDebugMode) {
                  AppLogger.success('Artista parseado:');
                  AppLogger.debug('      - ID: ${artist.id}');
                  AppLogger.debug('      - stageName: ${artist.stageName}');
                  AppLogger.debug('      - displayName: ${artist.displayName}');
                }
                
                // Parsear canción y luego crear una nueva con el artista
                final tempSong = Song.fromJson(songData);
                
                // Obtener URL de portada de múltiples posibles campos (el backend puede devolver en diferentes formatos)
                final rawCoverUrl = tempSong.coverArtUrl ?? 
                                   songData['cover_art_url'] as String? ?? 
                                   songData['coverArtUrl'] as String? ??
                                   songData['coverImageUrl'] as String? ??
                                   songData['cover_image_url'] as String?;
                
                if (kDebugMode) {
                  AppLogger.debug('Después de Song.fromJson:');
                  AppLogger.debug('      - tempSong.coverArtUrl: ${tempSong.coverArtUrl}');
                  AppLogger.debug('      - songData[cover_art_url]: ${songData['cover_art_url']}');
                  AppLogger.debug('      - songData[coverArtUrl]: ${songData['coverArtUrl']}');
                  AppLogger.debug('      - rawCoverUrl final: $rawCoverUrl');
                }
                
                // Normalizar URL de portada (convertir ruta relativa a absoluta si es necesario)
                final normalizedCoverUrl = _normalizeCoverUrl(rawCoverUrl);
                
                if (kDebugMode) {
                  AppLogger.media('Portada raw: $rawCoverUrl');
                  AppLogger.media('Portada normalizada: $normalizedCoverUrl');
                }
                
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
              } catch (e, stackTrace) {
                // Si falla el parseo del artista, usar la canción sin artista
                AppLogger.error('HomeService: Error parseando artista', e, stackTrace);
                final tempSong = Song.fromJson(songData);
                // Obtener URL de portada de múltiples posibles campos
                final rawCoverUrl = tempSong.coverArtUrl ?? 
                                   songData['cover_art_url'] as String? ?? 
                                   songData['coverArtUrl'] as String? ??
                                   songData['coverImageUrl'] as String? ??
                                   songData['cover_image_url'] as String?;
                final normalizedCoverUrl = _normalizeCoverUrl(rawCoverUrl);
                
                if (kDebugMode) {
                  AppLogger.debug('Error parseando artista - Portada:');
                  AppLogger.debug('      - rawCoverUrl: $rawCoverUrl');
                  AppLogger.debug('      - normalizedCoverUrl: $normalizedCoverUrl');
                }
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
              // No hay artista en los datos
              final tempSong = Song.fromJson(songData);
              
              // Obtener URL de portada de múltiples posibles campos
              final rawCoverUrl = tempSong.coverArtUrl ?? 
                                 songData['cover_art_url'] as String? ?? 
                                 songData['coverArtUrl'] as String? ??
                                 songData['coverImageUrl'] as String? ??
                                 songData['cover_image_url'] as String?;
              
              if (kDebugMode) {
                AppLogger.debug('Después de Song.fromJson (sin artista):');
                AppLogger.debug('      - tempSong.coverArtUrl: ${tempSong.coverArtUrl}');
                AppLogger.debug('      - songData[cover_art_url]: ${songData['cover_art_url']}');
                AppLogger.debug('      - songData[coverArtUrl]: ${songData['coverArtUrl']}');
                AppLogger.debug('      - rawCoverUrl final: $rawCoverUrl');
              }
              
              // Normalizar URL de portada
              final normalizedCoverUrl = _normalizeCoverUrl(rawCoverUrl);
              
              if (kDebugMode) {
                AppLogger.media('Portada raw: $rawCoverUrl');
                AppLogger.media('Portada normalizada: $normalizedCoverUrl');
              }
              
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
            
            if (kDebugMode) {
              final artistName = song.artist?.stageName ?? 
                                song.artist?.displayName ?? 
                                'Sin artista';
              AppLogger.success('Canción ${i + 1}: ${song.title ?? "Sin título"} - Artista: $artistName');
            }
          } catch (e, stackTrace) {
            AppLogger.error('HomeService: Error parseando canción destacada ${i + 1}', e, stackTrace);
          }
        }

        AppLogger.success('HomeService: ${featuredSongs.length} canciones destacadas parseadas exitosamente');
        return featuredSongs;
      } else {
        AppLogger.error('HomeService: Error en respuesta - Status: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      AppLogger.error('HomeService: Error de red al obtener canciones destacadas: ${e.message}');
      if (kDebugMode && e.response != null) {
        AppLogger.debug('   Status: ${e.response?.statusCode}');
        AppLogger.debug('   Data: ${e.response?.data}');
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('HomeService: Error inesperado', e, stackTrace);
      return [];
    }
  }


  /// Obtener canciones populares
  Future<List<Song>> getPopularSongs({int limit = 10}) async {
    try {
      AppLogger.song('HomeService: Obteniendo canciones populares desde ${ApiConfig.baseUrl}/public/songs/top');
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/songs/top',
        queryParameters: {'limit': limit},
      );
      AppLogger.network('HomeService: Respuesta canciones populares - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['songs'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          AppLogger.warning('HomeService: No hay canciones populares disponibles, devolviendo lista vacía');
          return [];
        }
        
        return validData.map((json) {
          try {
            return Song.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            AppLogger.error('Error al parsear canción popular', e);
            return null;
          }
        }).where((item) => item != null).cast<Song>().toList();
      } else {
        AppLogger.error('HomeService: Error canciones populares - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      AppLogger.error('HomeService: DioException en canciones populares: ${e.message}');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e) {
      AppLogger.error('HomeService: Error inesperado en canciones populares', e);
      return []; // Devolver lista vacía en lugar de lanzar excepción
    }
  }

  /// Obtener artistas más escuchados
  Future<List<Artist>> getTopArtists({int limit = 8}) async {
    try {
      AppLogger.artist('HomeService: Obteniendo artistas top desde ${ApiConfig.baseUrl}/public/artists/top');
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/public/artists/top',
        queryParameters: {'limit': limit},
      );
      AppLogger.network('HomeService: Respuesta artistas top - Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['artists'] ?? []);
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        
        if (validData.isEmpty) {
          AppLogger.warning('HomeService: No hay artistas top disponibles, devolviendo lista vacía');
          return [];
        }
        
        return validData.map((json) {
          try {
            return Artist.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            AppLogger.error('Error al parsear artista top', e);
            return null;
          }
        }).where((item) => item != null).cast<Artist>().toList();
      } else {
        AppLogger.error('HomeService: Error artistas top - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      AppLogger.error('HomeService: DioException en artistas top: ${e.message}');
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e) {
      AppLogger.error('HomeService: Error inesperado en artistas top', e);
      return []; // Devolver lista vacía en lugar de lanzar excepción
    }
  }

  /// Obtener playlists destacadas
  Future<List<FeaturedPlaylist>> getFeaturedPlaylists({int limit = 6}) async {
    try {
      final url = '${ApiConfig.baseUrl}/public/featured/playlists';
      AppLogger.playlist('HomeService: Obteniendo playlists destacadas desde $url');
      AppLogger.network('HomeService: URL completa: $url?limit=$limit');
      
      final response = await _dio.get(
        url,
        queryParameters: {'limit': limit},
      );
      
      AppLogger.network('HomeService: Respuesta playlists destacadas - Status: ${response.statusCode}');
      if (kDebugMode) {
        AppLogger.debug('HomeService: Tipo de respuesta.data: ${response.data.runtimeType}');
        AppLogger.debug('HomeService: Respuesta.data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        if (kDebugMode) {
          AppLogger.data('HomeService: Número de playlists en respuesta: ${data.length}');
        }
        
        final validData = data.where((item) => item != null && item is Map<String, dynamic>).toList();
        if (kDebugMode) {
          AppLogger.data('HomeService: Número de playlists válidas: ${validData.length}');
        }
        
        if (validData.isEmpty) {
          AppLogger.warning('HomeService: No hay playlists destacadas disponibles, devolviendo lista vacía');
          return [];
        }
        
        final playlists = <FeaturedPlaylist>[];
        for (var i = 0; i < validData.length; i++) {
          try {
            final item = validData[i] as Map<String, dynamic>;
            if (kDebugMode) {
              AppLogger.playlist('HomeService: Parseando playlist $i: ${item['name']}');
            }
            
            // Normalizar coverArtUrl antes de parsear (convertir localhost a 10.0.2.2)
            final coverArtUrl = item['coverArtUrl'] ?? item['cover_art_url'];
            if (coverArtUrl != null && coverArtUrl is String && coverArtUrl.isNotEmpty) {
              if (kDebugMode) {
                AppLogger.debug('HomeService: Portada raw de playlist $i: $coverArtUrl');
              }
              final normalizedCoverUrl = _normalizeCoverUrl(coverArtUrl);
              if (normalizedCoverUrl != null && normalizedCoverUrl.isNotEmpty) {
                item['coverArtUrl'] = normalizedCoverUrl;
                item['cover_art_url'] = normalizedCoverUrl; // También normalizar snake_case por si acaso
                if (kDebugMode) {
                  AppLogger.debug('HomeService: Portada normalizada de playlist $i: $normalizedCoverUrl');
                }
              } else if (kDebugMode) {
                AppLogger.warning('HomeService: Portada normalizada es null o vacía para playlist $i');
              }
            } else if (kDebugMode) {
              AppLogger.debug('HomeService: Playlist $i no tiene coverArtUrl');
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
              if (kDebugMode) {
                AppLogger.debug('HomeService: User transformado para playlist $i: ${transformedUser['first_name']} ${transformedUser['last_name']}');
              }
            }
            
            final playlist = Playlist.fromJson(item);
            final featuredPlaylist = FeaturedPlaylist(
              playlist: playlist,
              featuredReason: 'Destacada',
              rank: i + 1,
            );
            playlists.add(featuredPlaylist);
            AppLogger.success('HomeService: Playlist parseada exitosamente: ${playlist.name}');
          } catch (e, stackTrace) {
            AppLogger.error('HomeService: Error al parsear playlist $i', e, stackTrace);
          }
        }
        
        AppLogger.success('HomeService: Total de playlists destacadas parseadas: ${playlists.length}');
        return playlists;
      } else {
        AppLogger.error('HomeService: Error playlists destacadas - Status: ${response.statusCode}, Data: ${response.data}');
        return []; // Devolver lista vacía en lugar de lanzar excepción
      }
    } on DioException catch (e) {
      AppLogger.error('HomeService: DioException en playlists destacadas: ${e.message}');
      if (kDebugMode) {
        AppLogger.debug('HomeService: DioException tipo: ${e.type}');
        AppLogger.debug('HomeService: DioException response: ${e.response?.data}');
        AppLogger.debug('HomeService: DioException request: ${e.requestOptions.uri}');
      }
      return []; // Devolver lista vacía en lugar de lanzar excepción
    } catch (e, stackTrace) {
      AppLogger.error('HomeService: Error inesperado en playlists destacadas', e, stackTrace);
      return []; // Devolver lista vacía en lugar de lanzar excepción
    }
  }

  /// Normalizar URL de portada: convertir ruta relativa a absoluta si es necesario
  String? _normalizeCoverUrl(String? coverUrl) {
    if (coverUrl == null || coverUrl.isEmpty) {
      if (kDebugMode) {
        AppLogger.warning('_normalizeCoverUrl: URL es null o vacía');
      }
      return null;
    }

    if (kDebugMode) {
      AppLogger.debug('_normalizeCoverUrl: Normalizando "$coverUrl"');
    }

    // Si ya es una URL completa (http:// o https://), normalizarla para el emulador
    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      // Reemplazar localhost con 10.0.2.2 para emulador Android
      String normalizedUrl = coverUrl;
      if (coverUrl.contains('localhost') || coverUrl.contains('127.0.0.1')) {
        normalizedUrl = coverUrl.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
        if (kDebugMode) {
          AppLogger.debug('URL con localhost convertida a 10.0.2.2: $normalizedUrl');
        }
      }
      if (kDebugMode) {
        AppLogger.success('URL ya es completa: $normalizedUrl');
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
        AppLogger.debug('Base URL convertida de localhost a 10.0.2.2: $cleanBaseUrl');
      }
    }
    
    if (kDebugMode) {
      AppLogger.debug('Base URL limpia: $cleanBaseUrl');
    }

    // Si es una ruta relativa que empieza con /uploads, construir URL completa
    if (coverUrl.startsWith('/uploads/')) {
      final finalUrl = '$cleanBaseUrl$coverUrl';
      if (kDebugMode) {
        AppLogger.success('URL normalizada (con /uploads): $finalUrl');
      }
      return finalUrl;
    }

    // Si es una ruta relativa sin /, agregar /uploads/covers/
    if (!coverUrl.startsWith('/')) {
      final finalUrl = '$cleanBaseUrl/uploads/covers/$coverUrl';
      if (kDebugMode) {
        AppLogger.success('URL normalizada (sin /): $finalUrl');
      }
      return finalUrl;
    }

    // Si ya tiene / al inicio pero no es /uploads, construir URL completa
    final finalUrl = '$cleanBaseUrl$coverUrl';
    if (kDebugMode) {
      AppLogger.success('URL normalizada (otro caso): $finalUrl');
    }
    return finalUrl;
  }

}
