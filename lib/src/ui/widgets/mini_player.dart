import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:meraki/src/ui/controllers/player_controller.dart';
import 'package:meraki/src/ui/meraki_theme.dart';
import 'package:meraki/src/ui/widgets/cover_art_image.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    required this.controller,
    required this.onOpenNowPlaying,
    this.desktop = false,
    super.key,
  });

  final PlayerController controller;
  final VoidCallback onOpenNowPlaying;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaItem?>(
      valueListenable: controller.currentItem,
      builder: (context, item, _) {
        if (item == null) return const SizedBox.shrink();
        return ValueListenableBuilder<PlaybackState>(
          valueListenable: controller.playbackState,
          builder: (context, state, _) {
            return ValueListenableBuilder<Duration>(
              valueListenable: controller.position,
              builder: (context, position, _) {
                return _PlayerSurface(
                  item: item,
                  state: state,
                  position: position,
                  controller: controller,
                  onOpenNowPlaying: onOpenNowPlaying,
                  desktop: desktop,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PlayerSurface extends StatelessWidget {
  const _PlayerSurface({
    required this.item,
    required this.state,
    required this.position,
    required this.controller,
    required this.onOpenNowPlaying,
    required this.desktop,
  });

  final MediaItem item;
  final PlaybackState state;
  final Duration position;
  final PlayerController controller;
  final VoidCallback onOpenNowPlaying;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final duration = item.duration;
    final progress = duration == null || duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final content = desktop
        ? _DesktopPlayerContent(
            item: item,
            state: state,
            controller: controller,
            onOpenNowPlaying: onOpenNowPlaying,
          )
        : _MobilePlayerContent(
            item: item,
            state: state,
            controller: controller,
            onOpenNowPlaying: onOpenNowPlaying,
          );

    return Material(
      color: MerakiColors.deepPurple,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LinearProgressIndicator(
              value: progress,
              minHeight: desktop ? 3 : 2,
              color: accent,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

class _DesktopPlayerContent extends StatelessWidget {
  const _DesktopPlayerContent({
    required this.item,
    required this.state,
    required this.controller,
    required this.onOpenNowPlaying,
  });

  final MediaItem item;
  final PlaybackState state;
  final PlayerController controller;
  final VoidCallback onOpenNowPlaying;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 88,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _TrackIdentity(item: item, onTap: onOpenNowPlaying),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _PlayerIconButton(
                  tooltip: 'Aleatório',
                  active: controller.isShuffleEnabled,
                  onPressed: controller.toggleShuffle,
                  icon: PhosphorIconsRegular.shuffle,
                ),
                _PlayerIconButton(
                  tooltip: 'Anterior',
                  onPressed: controller.skipPrevious,
                  icon: PhosphorIconsRegular.skipBack,
                ),
                const SizedBox(width: 8),
                Material(
                  color: accent,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: state.playing ? 'Pausar' : 'Tocar',
                    onPressed: () => unawaited(controller.togglePlayPause()),
                    iconSize: 27,
                    color: MerakiColors.deepPurple,
                    icon: Icon(
                      state.playing
                          ? PhosphorIconsFill.pause
                          : PhosphorIconsFill.play,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _PlayerIconButton(
                  tooltip: 'Próxima',
                  onPressed: controller.skipNext,
                  icon: PhosphorIconsRegular.skipForward,
                ),
                _PlayerIconButton(
                  tooltip: 'Repetir',
                  active: state.repeatMode != AudioServiceRepeatMode.none,
                  onPressed: controller.cycleRepeatMode,
                  icon: state.repeatMode == AudioServiceRepeatMode.one
                      ? PhosphorIconsRegular.repeatOnce
                      : PhosphorIconsRegular.repeat,
                ),
              ],
            ),
            const Spacer(),
            Icon(PhosphorIconsRegular.speakerHigh, color: accent),
          ],
        ),
      ),
    );
  }
}

class _MobilePlayerContent extends StatelessWidget {
  const _MobilePlayerContent({
    required this.item,
    required this.state,
    required this.controller,
    required this.onOpenNowPlaying,
  });

  final MediaItem item;
  final PlaybackState state;
  final PlayerController controller;
  final VoidCallback onOpenNowPlaying;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _TrackIdentity(item: item, onTap: onOpenNowPlaying),
            ),
            IconButton(
              tooltip: state.playing ? 'Pausar' : 'Tocar',
              onPressed: () => unawaited(controller.togglePlayPause()),
              color: Theme.of(context).colorScheme.primary,
              iconSize: 31,
              icon: Icon(
                state.playing
                    ? PhosphorIconsFill.pause
                    : PhosphorIconsFill.play,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackIdentity extends StatelessWidget {
  const _TrackIdentity({required this.item, required this.onTap});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Hero(
            tag: 'cover-art-${item.id}',
            child: CoverArtImage(
              coverArtUrlOrPath: item.artUri?.toString(),
              width: 52,
              height: 52,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  item.artist ?? 'Artista desconhecido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MerakiColors.softText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerIconButton extends StatelessWidget {
  const _PlayerIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.active = false,
  });

  final String tooltip;
  final Future<void> Function() onPressed;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () => unawaited(onPressed()),
      color: active
          ? Theme.of(context).colorScheme.primary
          : MerakiColors.softText,
      icon: Icon(icon),
    );
  }
}
