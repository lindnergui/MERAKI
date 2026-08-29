import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meraki/src/ui/meraki_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.enableBlur = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: MerakiColors.panel,
        borderRadius: borderRadius,
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 28,
            spreadRadius: -10,
          ),
        ],
      ),
      child: child,
    );

    if (!enableBlur) return surface;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: surface,
      ),
    );
  }
}
