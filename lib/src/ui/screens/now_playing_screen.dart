import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:meraki/src/ui/controllers/player_controller.dart';
import 'package:meraki/src/ui/widgets/cover_art_image.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({required this.controller, super.key});

  final PlayerController controller;

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  double? _dragPositionMilliseconds;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaItem?>(
      valueListenable: widget.controller.currentItem,
      builder: (context, item, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tocando agora')),
          body: item == null
              ? const _EmptyNowPlaying()
              : ValueListenableBuilder<PlaybackState>(
                  valueListenable: widget.controller.playbackState,
                  builder: (context, state, _) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: widget.controller.position,
                      builder: (context, position, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 760;
                            final artwork = _Artwork(
                              item: item,
                              isWide: isWide,
                            );
                            final controls = _Controls(
                              controller: widget.controller,
                              item: item,
                              state: state,
                              position: position,
                              dragPositionMilliseconds:
                                  _dragPositionMilliseconds,
                              onDragChanged: (value) {
                                setState(
                                  () => _dragPositionMilliseconds = value,
                                );
                              },
                              onDragEnded: (value) {
                                setState(
                                  () => _dragPositionMilliseconds = null,
                                );
                                unawaited(
                                  widget.controller.seek(
                                    Duration(milliseconds: value.round()),
                                  ),
                                );
                              },
                            );

                            return SafeArea(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1100,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: isWide
                                        ? Row(
                                            children: <Widget>[
                                              Expanded(child: artwork),
                                              const SizedBox(width: 48),
                                              Expanded(child: controls),
                                            ],
                                          )
                                        : SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                artwork,
                                                const SizedBox(height: 32),
                                                controls,
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.item, required this.isWide});

  final MediaItem item;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 470 : 520),
        child: AspectRatio(
          aspectRatio: 1,
          child: Hero(
            tag: 'cover-art-${item.id}',
            child: CoverArtImage(
              coverArtUrlOrPath: item.artUri?.toString(),
              borderRadius: const BorderRadius.all(Radius.circular(28)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.item,
    required this.state,
    required this.position,
    required this.dragPositionMilliseconds,
    required this.onDragChanged,
    required this.onDragEnded,
  });

  final PlayerController controller;
  final MediaItem item;
  final PlaybackState state;
  final Duration position;
  final double? dragPositionMilliseconds;
  final ValueChanged<double> onDragChanged;
  final ValueChanged<double> onDragEnded;

  @override
  Widget build(BuildContext context) {
    final duration = item.duration ?? Duration.zero;
    final maximum = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final displayedPosition =
        dragPositionMilliseconds ??
        position.inMilliseconds.toDouble().clamp(0.0, maximum);
    final source = item.extras?['source'] as String?;
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          item.artist ?? 'Artista desconhecido',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (item.album != null && item.album!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(item.album!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            avatar: Icon(
              source == 'subsonic'
                  ? Icons.cloud_queue_rounded
                  : Icons.folder_rounded,
              size: 18,
            ),
            label: Text(source == 'subsonic' ? 'Subsonic' : 'Local'),
          ),
        ),
        const SizedBox(height: 24),
        Slider(
          value: displayedPosition,
          max: maximum,
          onChanged: duration == Duration.zero ? null : onDragChanged,
          onChangeEnd: duration == Duration.zero ? null : onDragEnded,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _formatDuration(
                  Duration(milliseconds: displayedPosition.round()),
                ),
              ),
              Text(_formatDuration(duration)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              tooltip: 'Aleatório',
              onPressed: () => unawaited(controller.toggleShuffle()),
              color: controller.isShuffleEnabled ? colors.primary : null,
              icon: const Icon(Icons.shuffle_rounded),
            ),
            IconButton(
              tooltip: 'Anterior',
              iconSize: 38,
              onPressed: () => unawaited(controller.skipPrevious()),
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            FilledButton(
              onPressed: () => unawaited(controller.togglePlayPause()),
              style: FilledButton.styleFrom(shape: const CircleBorder()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  state.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 42,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Próxima',
              iconSize: 38,
              onPressed: () => unawaited(controller.skipNext()),
              icon: const Icon(Icons.skip_next_rounded),
            ),
            IconButton(
              tooltip: 'Repetir',
              onPressed: () => unawaited(controller.cycleRepeatMode()),
              color: state.repeatMode == AudioServiceRepeatMode.none
                  ? null
                  : colors.primary,
              icon: Icon(
                state.repeatMode == AudioServiceRepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours == 0) return '$minutes:$seconds';
    return '${duration.inHours}:$minutes:$seconds';
  }
}

class _EmptyNowPlaying extends StatelessWidget {
  const _EmptyNowPlaying();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Escolha uma música na biblioteca para começar a tocar.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
