import 'dart:io';

import 'package:flutter/material.dart';

/// Loads Subsonic artwork over HTTP(S) and local artwork directly from disk.
///
/// The placeholder is deliberately part of the component so every screen gets
/// the same resilient fallback when tags do not contain cover art.
class CoverArtImage extends StatelessWidget {
  const CoverArtImage({
    required this.coverArtUrlOrPath,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    super.key,
  });

  final String? coverArtUrlOrPath;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    // Flutter caches ImageProviders in memory. Decoding an explicit thumbnail
    // size prevents a very large remote album cover from consuming the cache
    // while a user scrolls through a large catalog.
    final resolvedCacheWidth = cacheWidth ?? _cacheDimension(context, width);
    final resolvedCacheHeight = cacheHeight ?? _cacheDimension(context, height);
    final value = coverArtUrlOrPath?.trim();
    if (value == null || value.isEmpty) {
      return _frame(_placeholder(context));
    }

    final uri = Uri.tryParse(value);
    final isRemote =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final isFileUri = uri?.scheme == 'file';

    final Widget image;
    if (isRemote) {
      image = Image.network(
        value,
        fit: BoxFit.cover,
        cacheWidth: resolvedCacheWidth,
        cacheHeight: resolvedCacheHeight,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    } else if (isFileUri) {
      image = Image.file(
        File.fromUri(uri!),
        fit: BoxFit.cover,
        cacheWidth: resolvedCacheWidth,
        cacheHeight: resolvedCacheHeight,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    } else {
      image = Image.file(
        File(value),
        fit: BoxFit.cover,
        cacheWidth: resolvedCacheWidth,
        cacheHeight: resolvedCacheHeight,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }

    return _frame(image);
  }

  int? _cacheDimension(BuildContext context, double? logicalSize) {
    if (logicalSize == null || logicalSize <= 0) return null;
    final pixels = logicalSize * MediaQuery.devicePixelRatioOf(context);
    return pixels.round().clamp(1, 2048).toInt();
  }

  Widget _frame(Widget image) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(borderRadius: borderRadius, child: image),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.primary.withValues(alpha: 0.85),
            colors.secondaryContainer,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 36),
      ),
    );
  }
}
