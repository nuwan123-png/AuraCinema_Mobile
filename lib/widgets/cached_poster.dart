import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedPoster extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int memCacheWidth;
  final BorderRadius? borderRadius;

  const CachedPoster({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth = 400,
    this.borderRadius,
  });

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF181822),
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_creation_outlined,
        color: Colors.white24,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: _buildFallback())
          : _buildFallback();
    }

    final img = CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 160),
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: const Color(0xFF181822),
      ),
      errorWidget: (_, __, ___) => _buildFallback(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}