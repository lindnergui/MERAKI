import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:meraki/src/ui/controllers/player_controller.dart';
import 'package:meraki/src/ui/widgets/cover_art_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    required this.controller,
    required this.onOpenNowPlaying,
    super.key,
  });

  final PlayerController controller;
  final VoidCallback onOpenNowPlaying;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaItem?>(
      valueListenable: controller.currentItem,
      builder: (context, item, _) {
        if (item == null) return const SizedBox.shrink();
        return ValueListenableBuilder<PlaybackState>(
          valueListenable: controller.playbackState,
          builder: (context, state, _) {
            return Material(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: InkWell(
                onTap: onOpenNowPlaying,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ValueListenableBuilder<Duration>(
                        valueListenable: controller.position,
                        builder: (context, position, _) {
                          final duration = item.duration;
                          final progress =
                              duration == null || duration.inMilliseconds == 0
                              ? 0.0
                              : (position.inMilliseconds /
                                        duration.inMilliseconds)
                                    .clamp(0.0, 1.0);
                          return LinearProgressIndicator(value: progress);
                        },
                      ),
                      SizedBox(
                        height: 68,
                        child: Row(
                          children: <Widget>[
                            const SizedBox(width: 12),
                            CoverArtImage(
                              coverArtUrlOrPath: item.artUri?.toString(),
                              width: 48,
                              height: 48,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
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
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    item.artist ?? 'Artista desconhecido',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: state.playing ? 'Pausar' : 'Tocar',
                              iconSize: 32,
                              onPressed: () =>
                                  unawaited(controller.togglePlayPause()),
                              icon: Icon(
                                state.playing
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
