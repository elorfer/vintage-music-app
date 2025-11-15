import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/home_service.dart';
import '../models/artist_model.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../utils/logger.dart';

/// Provider para el servicio de home
final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService();
});

/// Estado de la pantalla de inicio
class HomeState {
  final List<FeaturedArtist> featuredArtists;
  final List<FeaturedSong> featuredSongs;
  final List<FeaturedPlaylist> featuredPlaylists;
  final List<Song> popularSongs;
  final List<Artist> topArtists;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const HomeState({
    this.featuredArtists = const [],
    this.featuredSongs = const [],
    this.featuredPlaylists = const [],
    this.popularSongs = const [],
    this.topArtists = const [],
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  HomeState copyWith({
    List<FeaturedArtist>? featuredArtists,
    List<FeaturedSong>? featuredSongs,
    List<FeaturedPlaylist>? featuredPlaylists,
    List<Song>? popularSongs,
    List<Artist>? topArtists,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return HomeState(
      featuredArtists: featuredArtists ?? this.featuredArtists,
      featuredSongs: featuredSongs ?? this.featuredSongs,
      featuredPlaylists: featuredPlaylists ?? this.featuredPlaylists,
      popularSongs: popularSongs ?? this.popularSongs,
      topArtists: topArtists ?? this.topArtists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => featuredArtists.isEmpty && featuredSongs.isEmpty && featuredPlaylists.isEmpty;
}

/// Notifier para manejar el estado de la pantalla de inicio
class HomeNotifier extends Notifier<HomeState> {
  late final HomeService _homeService;

  @override
  HomeState build() {
    _homeService = ref.read(homeServiceProvider);
    // Inicializar de forma asíncrona
    Future.microtask(() => _initialize());
    return const HomeState(isLoading: true);
  }

  /// Inicializar el servicio y cargar datos
  Future<void> _initialize() async {
    try {
      await _homeService.initialize();
      await loadHomeData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al inicializar: $e',
        isInitialized: true,
      );
    }
  }

  /// Cargar todos los datos de la pantalla de inicio
  Future<void> loadHomeData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Cargar datos individualmente para manejar errores por separado
      List<FeaturedArtist> featuredArtists = [];
      List<FeaturedSong> featuredSongs = [];
      List<FeaturedPlaylist> featuredPlaylists = [];
      List<Song> popularSongs = [];
      List<Artist> topArtists = [];

      // Cargar artistas destacados
      try {
        featuredArtists = await _homeService.getFeaturedArtists(limit: 6);
        AppLogger.success('HomeProvider: Artistas destacados cargados: ${featuredArtists.length}');
      } catch (e) {
        AppLogger.error('HomeProvider: Error cargando artistas destacados', e);
      }

      // Cargar canciones destacadas (aumentar límite para asegurar que se muestren todas)
      try {
        featuredSongs = await _homeService.getFeaturedSongs(limit: 20);
        AppLogger.success('HomeProvider: Canciones destacadas cargadas: ${featuredSongs.length}');
      } catch (e) {
        AppLogger.error('HomeProvider: Error cargando canciones destacadas', e);
      }

      // Cargar playlists destacadas
      try {
        featuredPlaylists = await _homeService.getFeaturedPlaylists(limit: 6);
        AppLogger.success('HomeProvider: Playlists destacadas cargadas: ${featuredPlaylists.length}');
      } catch (e) {
        AppLogger.error('HomeProvider: Error cargando playlists destacadas', e);
      }

      // Cargar canciones populares (error silencioso si falla)
      // No loguear nada - el endpoint puede no estar disponible (500, etc.)
      popularSongs = await _homeService.getPopularSongs(limit: 10);

      // Cargar artistas top
      try {
        topArtists = await _homeService.getTopArtists(limit: 8);
        AppLogger.success('HomeProvider: Artistas top cargados: ${topArtists.length}');
      } catch (e) {
        AppLogger.error('HomeProvider: Error cargando artistas top', e);
      }

      state = state.copyWith(
        featuredArtists: featuredArtists,
        featuredSongs: featuredSongs,
        featuredPlaylists: featuredPlaylists,
        popularSongs: popularSongs,
        topArtists: topArtists,
        isLoading: false,
        error: null,
        isInitialized: true,
      );

      AppLogger.success('HomeProvider: Datos cargados exitosamente');
    } catch (e) {
      AppLogger.error('HomeProvider: Error general', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar datos: $e',
        isInitialized: true,
      );
    }
  }

  /// Refrescar datos (forzar refresh sin caché)
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Cargar datos individualmente para manejar errores por separado
      List<FeaturedArtist> featuredArtists = [];
      List<FeaturedSong> featuredSongs = [];
      List<FeaturedPlaylist> featuredPlaylists = [];
      List<Song> popularSongs = [];
      List<Artist> topArtists = [];

      // Cargar artistas destacados
      try {
        featuredArtists = await _homeService.getFeaturedArtists(limit: 6);
        AppLogger.success('HomeProvider: Artistas destacados cargados (refresh): ${featuredArtists.length}');
      } catch (e) {
        AppLogger.error('HomeProvider: Error cargando artistas destacados (refresh)', e);
      }

      // Cargar canciones destacadas con forceRefresh para evitar caché
      try {
        featuredSongs = await _homeService.getFeaturedSongs(limit: 20, forceRefresh: true);
        AppLogger.success('HomeProvider: Canciones destacadas cargadas (refresh): ${featuredSongs.length}');
      } catch (e) {
        AppLogger.error('HomeProvider: Error cargando canciones destacadas (refresh)', e);
      }

      // Cargar playlists destacadas
      try {
        featuredPlaylists = await _homeService.getFeaturedPlaylists(limit: 6);
        AppLogger.success('HomeProvider: Playlists destacadas cargadas (refresh): ${featuredPlaylists.length}');
      } catch (e) {
        AppLogger.error('HomeProvider: Error cargando playlists destacadas (refresh)', e);
      }

      // Cargar canciones populares (error silencioso si falla)
      // No loguear nada - el endpoint puede no estar disponible (500, etc.)
      popularSongs = await _homeService.getPopularSongs(limit: 10);

      // Cargar artistas top
      try {
        topArtists = await _homeService.getTopArtists(limit: 8);
        AppLogger.success('HomeProvider: Artistas top cargados (refresh): ${topArtists.length}');
      } catch (e) {
        AppLogger.error('HomeProvider: Error cargando artistas top (refresh)', e);
      }

      state = state.copyWith(
        featuredArtists: featuredArtists,
        featuredSongs: featuredSongs,
        featuredPlaylists: featuredPlaylists,
        popularSongs: popularSongs,
        topArtists: topArtists,
        isLoading: false,
        error: null,
        isInitialized: true,
      );

      AppLogger.success('HomeProvider: Datos refrescados exitosamente');
    } catch (e) {
      AppLogger.error('HomeProvider: Error general en refresh', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Error al refrescar datos: $e',
        isInitialized: true,
      );
    }
  }

  /// Cargar solo artistas destacados
  Future<void> loadFeaturedArtists() async {
    try {
      final artists = await _homeService.getFeaturedArtists(limit: 6);
      state = state.copyWith(featuredArtists: artists);
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar artistas: $e');
    }
  }

  /// Cargar solo canciones destacadas
  Future<void> loadFeaturedSongs({bool forceRefresh = false}) async {
    try {
      final songs = await _homeService.getFeaturedSongs(limit: 20, forceRefresh: forceRefresh);
      state = state.copyWith(featuredSongs: songs);
      AppLogger.success('HomeProvider: Canciones destacadas actualizadas: ${songs.length}');
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar canciones: $e');
    }
  }

  /// Cargar solo playlists destacadas
  Future<void> loadFeaturedPlaylists() async {
    try {
      final playlists = await _homeService.getFeaturedPlaylists(limit: 6);
      state = state.copyWith(featuredPlaylists: playlists);
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar playlists: $e');
    }
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider para el estado de home
final homeStateProvider = NotifierProvider<HomeNotifier, HomeState>(() {
  return HomeNotifier();
});

/// Providers específicos para cada sección
final featuredArtistsProvider = Provider<List<FeaturedArtist>>((ref) {
  final homeState = ref.watch(homeStateProvider);
  return homeState.featuredArtists;
});

final featuredSongsProvider = Provider<List<FeaturedSong>>((ref) {
  final homeState = ref.watch(homeStateProvider);
  return homeState.featuredSongs;
});

final featuredPlaylistsProvider = Provider<List<FeaturedPlaylist>>((ref) {
  final homeState = ref.watch(homeStateProvider);
  return homeState.featuredPlaylists;
});

final popularSongsProvider = Provider<List<Song>>((ref) {
  final homeState = ref.watch(homeStateProvider);
  return homeState.popularSongs;
});

final topArtistsProvider = Provider<List<Artist>>((ref) {
  final homeState = ref.watch(homeStateProvider);
  return homeState.topArtists;
});

final isLoadingProvider = Provider<bool>((ref) {
  final homeState = ref.watch(homeStateProvider);
  return homeState.isLoading;
});

final homeErrorProvider = Provider<String?>((ref) {
  final homeState = ref.watch(homeStateProvider);
  return homeState.error;
});

