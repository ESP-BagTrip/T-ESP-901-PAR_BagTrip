import 'package:bagtrip/gen/colors.gen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final int memCacheWidth;
  final Widget? errorWidget;
  final Color? colorBlendMode;
  final BlendMode? blendMode;

  const OptimizedImage.tripCover(
    this.imageUrl, {
    super.key,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.colorBlendMode,
    this.blendMode,
  }) : memCacheWidth = 800;

  const OptimizedImage.activityImage(
    this.imageUrl, {
    super.key,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.colorBlendMode,
    this.blendMode,
  }) : memCacheWidth = 400;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      memCacheWidth: memCacheWidth,
      maxWidthDiskCache: memCacheWidth,
      color: colorBlendMode,
      colorBlendMode: blendMode,
      placeholder: (_, _) => Shimmer.fromColors(
        baseColor: ColorName.primaryLight,
        highlightColor: ColorName.surface,
        child: Container(color: ColorName.primaryLight),
      ),
      errorWidget: (_, _, _) =>
          errorWidget ?? const _DefaultGradientPlaceholder(),
    );
  }
}

class _DefaultGradientPlaceholder extends StatelessWidget {
  const _DefaultGradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorName.primary, ColorName.secondary],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.flight_rounded,
        color: ColorName.surface.withValues(alpha: 0.3),
        size: 48,
      ),
    );
  }
}
