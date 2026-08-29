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
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    super.key,
  });

  final String? coverArtUrlOrPath;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
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
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    } else if (isFileUri) {
      image = Image.file(
        File.fromUri(uri!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    } else {
      image = Image.file(
        File(value),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }

    return _frame(image);
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
