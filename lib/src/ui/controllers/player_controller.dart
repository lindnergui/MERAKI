import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:meraki/src/audio/meraki_audio_handler.dart';
import 'package:meraki/src/rust/models/song.dart';
import 'package:palette_generator_plus/palette_generator_plus.dart';

/// Reactive projection of the handler's MediaItem and PlaybackState streams.
///
/// Position ticks are derived from [PlaybackState.position], not read from the
/// internal just_audio player, keeping the app, notification and MPRIS in sync.
class PlayerController extends ChangeNotifier {
  PlayerController({required MerakiAudioHandler audioHandler})
    : _audioHandler = audioHandler {
    _mediaItemSubscription = _audioHandler.mediaItem.listen((item) {
      currentItem.value = item;
      _updateProjectedPosition();
      unawaited(_extractAccentColor(item));
      notifyListeners();
    });
    _playbackStateSubscription = _audioHandler.playbackState.listen((state) {
      playbackState.value = state;
      _updateProjectedPosition();
      notifyListeners();
    });
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _updateProjectedPosition(),
    );
  }

  final MerakiAudioHandler _audioHandler;
  final ValueNotifier<MediaItem?> currentItem = ValueNotifier<MediaItem?>(null);
  final ValueNotifier<PlaybackState> playbackState =
      ValueNotifier<PlaybackState>(PlaybackState());
  final ValueNotifier<Duration> position = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<Color> accentColor = ValueNotifier<Color>(_defaultAccent);
  late final StreamSubscription<MediaItem?> _mediaItemSubscription;
  late final StreamSubscription<PlaybackState> _playbackStateSubscription;
  late final Timer _positionTimer;
  int _accentRequest = 0;

  static const Color _defaultAccent = Color(0xFFFF4F8B);

  bool get isPlaying => playbackState.value.playing;
  bool get hasActiveItem => currentItem.value != null;
  bool get isShuffleEnabled =>
      playbackState.value.shuffleMode != AudioServiceShuffleMode.none;
  AudioServiceRepeatMode get repeatMode => playbackState.value.repeatMode;

  Future<void> playFromCatalog(Song song, List<Song> queue) {
    final index = queue.indexWhere((entry) => entry.id == song.id);
    return _audioHandler.playQueue(queue, initialIndex: index < 0 ? 0 : index);
  }

  Future<void> togglePlayPause() {
    return isPlaying ? _audioHandler.pause() : _audioHandler.play();
  }

  Future<void> seek(Duration value) => _audioHandler.seek(value);
  Future<void> skipNext() => _audioHandler.skipToNext();
  Future<void> skipPrevious() => _audioHandler.skipToPrevious();

  Future<void> toggleShuffle() {
    return _audioHandler.setShuffleMode(
      isShuffleEnabled
          ? AudioServiceShuffleMode.none
          : AudioServiceShuffleMode.all,
    );
  }

  Future<void> cycleRepeatMode() {
    final next = switch (repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => AudioServiceRepeatMode.one,
      AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
    };
    return _audioHandler.setRepeatMode(next);
  }

  void _updateProjectedPosition() {
    final item = currentItem.value;
    var projected = playbackState.value.position;
    final duration = item?.duration;
    if (duration != null && projected > duration) {
      projected = duration;
    }
    if (position.value != projected) {
      position.value = projected;
    }
  }

  Future<void> _extractAccentColor(MediaItem? item) async {
    final request = ++_accentRequest;
    final provider = _imageProviderFor(item?.artUri);
    if (provider == null) {
      accentColor.value = _defaultAccent;
      return;
    }

    try {
      // Quantization runs in a background isolate on native platforms, so a
      // large album image never blocks Flutter's raster/UI threads.
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        size: const Size(112, 112),
        maximumColorCount: 12,
      );
      final color =
          palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.dominantColor?.color ??
          _defaultAccent;
      if (request == _accentRequest) {
        accentColor.value = color;
      }
    } catch (_) {
      if (request == _accentRequest) {
        accentColor.value = _defaultAccent;
      }
    }
  }

  ImageProvider? _imageProviderFor(Uri? artUri) {
    if (artUri == null) return null;
    if (artUri.scheme == 'http' || artUri.scheme == 'https') {
      return NetworkImage(artUri.toString());
    }
    if (artUri.scheme == 'file') {
      return FileImage(File.fromUri(artUri));
    }
    if (artUri.scheme.isEmpty) {
      return FileImage(File(artUri.toString()));
    }
    return null;
  }

  @override
  void dispose() {
    _positionTimer.cancel();
    _mediaItemSubscription.cancel();
    _playbackStateSubscription.cancel();
    currentItem.dispose();
    playbackState.dispose();
    position.dispose();
    accentColor.dispose();
    super.dispose();
  }
}
