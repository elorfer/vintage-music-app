import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_activity.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authStateProvider.notifier);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con saludo
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola!',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            authState.user?.firstName ?? 'Usuario',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.white.withValues(alpha:0.8),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () async {
                          await authNotifier.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Tarjeta de perfil del usuario
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: UserProfileCard(user: authState.user!),
                ),

                const SizedBox(height: 24),

                // Acciones rápidas
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: QuickActions(),
                ),

                const SizedBox(height: 24),

                // Actividad reciente
                FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  child: RecentActivity(),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
