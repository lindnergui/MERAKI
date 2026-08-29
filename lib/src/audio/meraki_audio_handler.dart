import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:meraki/src/rust/models/song.dart';

/// Connects just_audio to Android MediaSession/background controls through
/// audio_service. Linux playback uses just_audio_media_kit, initialized in main.
abstract interface class SongPlayer {
  Future<void> playSong(Song song);
}

class MerakiAudioHandler extends BaseAudioHandler
    with SeekHandler
    implements SongPlayer {
  MerakiAudioHandler() {
    _playbackSubscription = _player.playbackEventStream.listen((event) {
      playbackState.add(_toPlaybackState(event));
    });
    _indexSubscription = _player.currentIndexStream.listen(_publishCurrentItem);
  }

  final AudioPlayer _player = AudioPlayer();
  final List<MediaItem> _mediaItems = <MediaItem>[];
  late final StreamSubscription<PlaybackEvent> _playbackSubscription;
  late final StreamSubscription<int?> _indexSubscription;

  @override
  Future<void> playSong(Song song) => playQueue(<Song>[song]);

  /// Replaces the playable queue and starts the selected song. The UI sends a
  /// filtered catalog here so Next/Previous operate within the active section.
  Future<void> playQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) {
      return;
    }

    final safeInitialIndex = initialIndex.clamp(0, songs.length - 1);
    _mediaItems
      ..clear()
      ..addAll(songs.map(_mediaItemForSong));
    queue.add(List<MediaItem>.unmodifiable(_mediaItems));

    await _player.setAudioSources(
      songs.map(_audioSourceForSong).toList(growable: false),
      initialIndex: safeInitialIndex,
    );
    _publishCurrentItem(safeInitialIndex);
    await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    if (enabled) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    return _player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => LoopMode.all,
    });
  }

  @override
  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    await _playbackSubscription.cancel();
    await _indexSubscription.cancel();
    await _player.dispose();
  }

  AudioSource _audioSourceForSong(Song song) {
    return AudioSource.uri(_uriForSong(song), tag: _mediaItemForSong(song));
  }

  MediaItem _mediaItemForSong(Song song) {
    final uri = _uriForSong(song);
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.durationSeconds == null
          ? null
          : Duration(seconds: song.durationSeconds!),
      artUri: _artUri(song.coverArtUrlOrPath, song.source),
      extras: <String, Object?>{
        'playbackUri': uri.toString(),
        'source': song.source.name,
      },
    );
  }

  Uri _uriForSong(Song song) {
    return song.source == SongSource.local
        ? Uri.file(song.streamUrlOrFilePath)
        : Uri.parse(song.streamUrlOrFilePath);
  }

  void _publishCurrentItem(int? index) {
    if (index == null || index < 0 || index >= _mediaItems.length) {
      return;
    }
    mediaItem.add(_mediaItems[index]);
  }

  Uri? _artUri(String? value, SongSource source) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (source == SongSource.local) {
      return File(value).absolute.uri;
    }
    return Uri.tryParse(value);
  }

  PlaybackState _toPlaybackState(PlaybackEvent event) {
    final controls = <MediaControl>[
      if (_player.hasPrevious) MediaControl.skipToPrevious,
      if (_player.playing) MediaControl.pause else MediaControl.play,
      if (_player.hasNext) MediaControl.skipToNext,
      MediaControl.stop,
    ];

    return PlaybackState(
      controls: controls,
      systemActions: const <MediaAction>{MediaAction.seek},
      androidCompactActionIndices: List<int>.generate(
        math.min(3, controls.length),
        (index) => index,
      ),
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      repeatMode: switch (_player.loopMode) {
        LoopMode.off => AudioServiceRepeatMode.none,
        LoopMode.one => AudioServiceRepeatMode.one,
        LoopMode.all => AudioServiceRepeatMode.all,
      },
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
  }
}
