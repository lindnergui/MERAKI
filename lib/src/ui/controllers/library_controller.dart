import 'package:flutter/foundation.dart';
import 'package:meraki/src/data/music_repository.dart';
import 'package:meraki/src/rust/models/song.dart';

enum LibrarySection { all, local, subsonic, albums }

/// Owns catalog state and serialises catalog-refresh operations.
///
/// All repository methods return FRB futures, so awaiting them here yields the
/// Flutter event loop instead of blocking rendering or gesture handling.
class LibraryController extends ChangeNotifier {
  LibraryController({required MusicRepository repository})
    : _repository = repository;

  final MusicRepository _repository;
  List<Song> _songs = const <Song>[];
  bool _isLoading = false;
  bool _isScanningLocal = false;
  bool _isSyncingSubsonic = false;
  String? _errorMessage;

  List<Song> get songs => List<Song>.unmodifiable(_songs);
  bool get isLoading => _isLoading;
  bool get isScanningLocal => _isScanningLocal;
  bool get isSyncingSubsonic => _isSyncingSubsonic;
  bool get isBusy => _isLoading || _isScanningLocal || _isSyncingSubsonic;
  String? get errorMessage => _errorMessage;

  List<Song> songsFor(LibrarySection section) {
    return switch (section) {
      LibrarySection.all || LibrarySection.albums => songs,
      LibrarySection.local =>
        _songs
            .where((song) => song.source == SongSource.local)
            .toList(growable: false),
      LibrarySection.subsonic =>
        _songs
            .where((song) => song.source == SongSource.subsonic)
            .toList(growable: false),
    };
  }

  Map<String, List<Song>> get albums {
    final grouped = <String, List<Song>>{};
    for (final song in _songs) {
      final album = song.album?.trim();
      final key = album == null || album.isEmpty ? 'Sem álbum' : album;
      grouped.putIfAbsent(key, () => <Song>[]).add(song);
    }
    return grouped;
  }

  Future<void> loadCatalog() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _songs = await _repository.getAllSongs();
    } catch (error) {
      _errorMessage = _friendlyError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> scanLocalMusic(String directoryPath) async {
    if (_isScanningLocal) return;
    _isScanningLocal = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.scanLocalMusic(directoryPath);
      _songs = await _repository.getAllSongs();
    } catch (error) {
      _errorMessage = _friendlyError(error);
      rethrow;
    } finally {
      _isScanningLocal = false;
      notifyListeners();
    }
  }

  Future<void> syncSubsonic({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    if (_isSyncingSubsonic) return;
    _isSyncingSubsonic = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.fetchSubsonicSongs(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _songs = await _repository.getAllSongs();
    } catch (error) {
      _errorMessage = _friendlyError(error);
      rethrow;
    } finally {
      _isSyncingSubsonic = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Não foi possível concluir a operação.' : message;
  }
}
