import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meraki/src/rust/models/song.dart';
import 'package:meraki/src/ui/controllers/library_controller.dart';
import 'package:meraki/src/ui/controllers/player_controller.dart';
import 'package:meraki/src/ui/screens/now_playing_screen.dart';
import 'package:meraki/src/ui/screens/settings_screen.dart';
import 'package:meraki/src/ui/widgets/cover_art_image.dart';
import 'package:meraki/src/ui/widgets/mini_player.dart';
import 'package:meraki/src/ui/widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.libraryController,
    required this.playerController,
    super.key,
  });

  final LibraryController libraryController;
  final PlayerController playerController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LibrarySection _section = LibrarySection.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 760;
        return Scaffold(
          appBar: AppBar(
            title: const Text('MERAKI'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Atualizar catálogo',
                onPressed: widget.libraryController.isBusy
                    ? null
                    : _loadCatalog,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Configurações',
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: Row(
            children: <Widget>[
              if (useRail)
                _SectionRail(section: _section, onChanged: _changeSection),
              if (useRail) const VerticalDivider(width: 1),
              Expanded(
                child: _CatalogBody(section: _section, state: this),
              ),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MiniPlayer(
                controller: widget.playerController,
                onOpenNowPlaying: _openNowPlaying,
              ),
              if (!useRail)
                NavigationBar(
                  selectedIndex: _section.index,
                  onDestinationSelected: (index) {
                    _changeSection(LibrarySection.values[index]);
                  },
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music_rounded),
                      label: 'Todas',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.folder_outlined),
                      selectedIcon: Icon(Icons.folder_rounded),
                      label: 'Locais',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.cloud_outlined),
                      selectedIcon: Icon(Icons.cloud_rounded),
                      label: 'Subsonic',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.album_outlined),
                      selectedIcon: Icon(Icons.album_rounded),
                      label: 'Álbuns',
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadCatalog() async {
    try {
      await widget.libraryController.loadCatalog();
    } catch (_) {
      if (mounted) _showError(widget.libraryController.errorMessage);
    }
  }

  void _changeSection(LibrarySection section) {
    setState(() => _section = section);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            SettingsScreen(libraryController: widget.libraryController),
      ),
    );
  }

  void _openNowPlaying() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            NowPlayingScreen(controller: widget.playerController),
      ),
    );
  }

  Future<void> playSong(Song song, List<Song> queue) async {
    try {
      await widget.playerController.playFromCatalog(song, queue);
    } catch (error) {
      if (mounted) {
        _showError('Não foi possível iniciar a reprodução: $error');
      }
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Não foi possível atualizar o catálogo.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionRail extends StatelessWidget {
  const _SectionRail({required this.section, required this.onChanged});

  final LibrarySection section;
  final ValueChanged<LibrarySection> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: true,
      selectedIndex: section.index,
      onDestinationSelected: (index) => onChanged(LibrarySection.values[index]),
      labelType: NavigationRailLabelType.none,
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music_rounded),
          label: Text('Todas as músicas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder_rounded),
          label: Text('Locais'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.cloud_outlined),
          selectedIcon: Icon(Icons.cloud_rounded),
          label: Text('Subsonic'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.album_outlined),
          selectedIcon: Icon(Icons.album_rounded),
          label: Text('Álbuns'),
        ),
      ],
    );
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody({required this.section, required this.state});

  final LibrarySection section;
  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state.widget.libraryController,
      builder: (context, _) {
        final controller = state.widget.libraryController;
        if (controller.isLoading && controller.songs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final title = switch (section) {
          LibrarySection.all => 'Todas as músicas',
          LibrarySection.local => 'Músicas locais',
          LibrarySection.subsonic => 'Biblioteca Subsonic',
          LibrarySection.albums => 'Álbuns',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (controller.isScanningLocal ||
                      controller.isSyncingSubsonic)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (controller.isScanningLocal || controller.isSyncingSubsonic)
              const LinearProgressIndicator(),
            Expanded(
              child: section == LibrarySection.albums
                  ? _AlbumList(controller: controller, state: state)
                  : _SongList(
                      songs: controller.songsFor(section),
                      state: state,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SongList extends StatelessWidget {
  const _SongList({required this.songs, required this.state});

  final List<Song> songs;
  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const _EmptyLibrary();
    }
    return ListView.builder(
      key: const PageStorageKey<String>('songs'),
      itemCount: songs.length,
      itemExtent: 70,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongTile(song: song, onPlay: () => state.playSong(song, songs));
      },
    );
  }
}

class _AlbumList extends StatelessWidget {
  const _AlbumList({required this.controller, required this.state});

  final LibraryController controller;
  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    final albums = controller.albums.entries.toList(growable: false);
    if (albums.isEmpty) return const _EmptyLibrary();

    return ListView.builder(
      key: const PageStorageKey<String>('albums'),
      itemCount: albums.length,
      itemExtent: 84,
      itemBuilder: (context, index) {
        final entry = albums[index];
        final firstSong = entry.value.first;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: CoverArtImage(
            coverArtUrlOrPath: firstSong.coverArtUrlOrPath,
            width: 64,
            height: 64,
          ),
          title: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${entry.value.length} faixa${entry.value.length == 1 ? '' : 's'}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => _AlbumDetailScreen(
                  album: entry.key,
                  songs: entry.value,
                  state: state,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AlbumDetailScreen extends StatelessWidget {
  const _AlbumDetailScreen({
    required this.album,
    required this.songs,
    required this.state,
  });

  final String album;
  final List<Song> songs;
  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(album)),
      body: ListView.builder(
        itemCount: songs.length,
        itemExtent: 70,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongTile(
            song: song,
            onPlay: () => state.playSong(song, songs),
          );
        },
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.queue_music_rounded, size: 56),
              SizedBox(height: 16),
              Text(
                'Seu catálogo está vazio. Configure o Subsonic ou escolha uma pasta local.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
