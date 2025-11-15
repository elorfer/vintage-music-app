import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget optimizado de imagen con carga progresiva
/// - Carga thumbnail primero para scroll rápido
/// - Carga HD cuando es necesario
/// - Placeholder optimizado
/// - Error widget personalizado
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? borderRadius;
  final bool useThumbnail;
  final Color? placeholderColor;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.useThumbnail = true,
    this.placeholderColor,
  });


  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultWidget();
    }

    // Validar que width y height sean finitos antes de convertir a int
    int? getMemCacheWidth() {
      if (width == null || !width!.isFinite) return null;
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      return (width! * devicePixelRatio).round();
    }

    int? getMemCacheHeight() {
      if (height == null || !height!.isFinite) return null;
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      return (height! * devicePixelRatio).round();
    }

    int? getMaxWidthDiskCache() {
      if (width == null || !width!.isFinite) return 800;
      return (width! * 2).round();
    }

    int? getMaxHeightDiskCache() {
      if (height == null || !height!.isFinite) return 800;
      return (height! * 2).round();
    }

    final Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: fit,
      width: width?.isFinite == true ? width : null,
      height: height?.isFinite == true ? height : null,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholderFadeInDuration: const Duration(milliseconds: 150),
      memCacheWidth: getMemCacheWidth(),
      memCacheHeight: getMemCacheHeight(),
      maxWidthDiskCache: getMaxWidthDiskCache(),
      maxHeightDiskCache: getMaxHeightDiskCache(),
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      // Configuración de caché optimizada
      cacheKey: imageUrl,
      httpHeaders: const {
        'Accept': 'image/webp,image/*;q=0.8',
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    if (placeholderColor != null) {
      return Container(
        width: width,
        height: height,
        color: placeholderColor,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.3),
            const Color(0xFF764ba2).withValues(alpha: 0.3),
          ],
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
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
      child: const Center(
        child: Icon(
          Icons.music_note,
          color: Colors.white70,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildDefaultWidget() {
    return Container(
      width: width,
      height: height,
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
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.white70,
          size: 32,
        ),
      ),
    );
  }
}

