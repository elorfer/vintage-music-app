import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/song_model.dart';
import '../../../core/utils/logger.dart';

class FeaturedSongCard extends StatelessWidget {
  final FeaturedSong featuredSong;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

  const FeaturedSongCard({
    super.key,
    required this.featuredSong,
    this.onTap,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final song = featuredSong.song;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Portada de la canción
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.coverArtUrl != null && song.coverArtUrl!.isNotEmpty
                    ? Builder(
                        builder: (context) {
                          if (kDebugMode) {
                            AppLogger.media('FeaturedSongCard: Intentando cargar portada: ${song.coverArtUrl}');
                          }
                          return Image.network(
                            song.coverArtUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                if (kDebugMode) {
                                  AppLogger.success('FeaturedSongCard: Portada cargada exitosamente');
                                }
                                return child;
                              }
                              if (kDebugMode) {
                                AppLogger.loading('FeaturedSongCard: Cargando portada... ${(loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) * 100).toStringAsFixed(0)}%');
                              }
                              return _buildDefaultCover();
                            },
                            errorBuilder: (context, error, stackTrace) {
                              if (kDebugMode) {
                                AppLogger.error('FeaturedSongCard: Error cargando portada: ${song.coverArtUrl}', error, stackTrace);
                              }
                              return _buildDefaultCover();
                            },
                          );
                        },
                      )
                    : Builder(
                        builder: (context) {
                          if (kDebugMode) {
                            AppLogger.warning('FeaturedSongCard: No hay URL de portada para: ${song.title}');
                          }
                          return _buildDefaultCover();
                        },
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Información de la canción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title ?? 'Canción Sin Título',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    _getArtistName(song),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatNumber(song.totalStreams)} • ${song.durationFormatted}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Botón de play
            GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _getArtistName(Song song) {
    if (kDebugMode) {
      AppLogger.artist('_getArtistName para canción: ${song.title}');
      AppLogger.debug('   - song.artist es null: ${song.artist == null}');
      if (song.artist != null) {
        AppLogger.debug('   - artist.id: ${song.artist!.id}');
        AppLogger.debug('   - artist.stageName: ${song.artist!.stageName}');
        AppLogger.debug('   - artist.displayName: ${song.artist!.displayName}');
        AppLogger.debug('   - artist.userId: ${song.artist!.userId}');
      }
    }
    
    // Intentar obtener el nombre del artista de múltiples formas
    if (song.artist != null) {
      // Primero intentar stageName (nombre artístico)
      final stageName = song.artist!.stageName;
      if (stageName != null && stageName.isNotEmpty && stageName.trim().isNotEmpty) {
        if (kDebugMode) {
          AppLogger.success('Usando stageName: $stageName');
        }
        return stageName;
      }
      
      // Si no hay stageName, usar displayName (que tiene fallback interno)
      final displayName = song.artist!.displayName;
      if (displayName.isNotEmpty && displayName != 'Artista Desconocido' && displayName.trim().isNotEmpty) {
        if (kDebugMode) {
          AppLogger.success('Usando displayName: $displayName');
        }
        return displayName;
      }
      
      if (kDebugMode) {
        AppLogger.warning('No se encontró nombre válido en el artista');
      }
    } else {
      if (kDebugMode) {
        AppLogger.warning('song.artist es null');
      }
    }
    
    // Fallback final si no hay artista o no tiene nombre
    if (kDebugMode) {
      AppLogger.error('Retornando fallback: Artista desconocido');
    }
    return 'Artista desconocido';
  }
}
