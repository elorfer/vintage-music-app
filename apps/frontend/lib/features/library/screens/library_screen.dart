import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Mi Biblioteca',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Library sections
                Expanded(
                  child: ListView(
                    children: [
                      _buildLibrarySection(
                        icon: Icons.favorite,
                        title: 'Canciones Favoritas',
                        subtitle: '0 canciones',
                        onTap: () {},
                      ),
                      _buildLibrarySection(
                        icon: Icons.playlist_play,
                        title: 'Mis Playlists',
                        subtitle: '0 playlists',
                        onTap: () {},
                      ),
                      _buildLibrarySection(
                        icon: Icons.download,
                        title: 'Descargadas',
                        subtitle: '0 canciones',
                        onTap: () {},
                      ),
                      _buildLibrarySection(
                        icon: Icons.history,
                        title: 'Recientemente Reproducidas',
                        subtitle: '0 canciones',
                        onTap: () {},
                      ),
                      _buildLibrarySection(
                        icon: Icons.album,
                        title: 'Álbumes Guardados',
                        subtitle: '0 álbumes',
                        onTap: () {},
                      ),
                      _buildLibrarySection(
                        icon: Icons.person,
                        title: 'Artistas Seguidos',
                        subtitle: '0 artistas',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibrarySection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        onTap: onTap,
      ),
    );
  }
}



