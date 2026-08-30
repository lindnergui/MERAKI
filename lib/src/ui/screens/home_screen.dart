import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meraki/src/rust/models/song.dart';
import 'package:meraki/src/ui/controllers/library_controller.dart';
import 'package:meraki/src/ui/controllers/player_controller.dart';
import 'package:meraki/src/ui/meraki_theme.dart';
import 'package:meraki/src/ui/screens/now_playing_screen.dart';
import 'package:meraki/src/ui/screens/settings_screen.dart';
import 'package:meraki/src/ui/widgets/cover_art_image.dart';
import 'package:meraki/src/ui/widgets/cover_flow_spotlight.dart';
import 'package:meraki/src/ui/widgets/glass_panel.dart';
import 'package:meraki/src/ui/widgets/mini_player.dart';
import 'package:meraki/src/ui/widgets/song_tile.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

enum _HomeDestination { home, allSongs, downloads, albums, artists }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.userName,
    required this.libraryController,
    required this.playerController,
    required this.onLogout,
    super.key,
  });

  final String userName;
  final LibraryController libraryController;
  final PlayerController playerController;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _HomeDestination _destination = _HomeDestination.home;
  String _searchQuery = '';
  bool _mobileNowPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 860;
        if (isDesktop) {
          return _DesktopShell(state: this);
        }
        return _MobileShell(state: this);
      },
    );
  }

  List<Song> get filteredSongs {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.libraryController.songs;
    return widget.libraryController.songs
        .where((song) {
          return <String?>[song.title, song.artist, song.album]
              .whereType<String>()
              .any((part) => part.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  Future<void> _loadCatalog() async {
    try {
      await widget.libraryController.loadCatalog();
    } catch (_) {
      if (mounted) _showError(widget.libraryController.errorMessage);
    }
  }

  void setDestination(_HomeDestination destination) {
    setState(() {
      _destination = destination;
      _mobileNowPlaying = false;
    });
  }

  void setMobileNowPlaying(bool value) {
    setState(() => _mobileNowPlaying = value);
  }

  void setSearchQuery(String value) => setState(() => _searchQuery = value);

  void openNowPlaying() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            NowPlayingScreen(controller: widget.playerController),
      ),
    );
  }

  void openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            SettingsScreen(libraryController: widget.libraryController),
      ),
    );
  }

  Future<void> logout() async {
    try {
      await widget.onLogout();
    } catch (_) {
      if (mounted) _showError('Não foi possível sair. Tente novamente.');
    }
  }

  Future<void> playSong(Song song, List<Song> queue) async {
    try {
      await widget.playerController.playFromCatalog(song, queue);
    } catch (error) {
      if (mounted) _showError('Não foi possível iniciar a reprodução: $error');
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

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: MerakiColors.deepPurple),
        child: SafeArea(
          child: Row(
            children: <Widget>[
              _MerakiSidebar(state: state),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _TopBar(state: state),
                    Expanded(child: _DesktopContent(state: state)),
                    MiniPlayer(
                      controller: state.widget.playerController,
                      onOpenNowPlaying: state.openNowPlaying,
                      desktop: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MerakiColors.deepPurple,
        title: const _MerakiWordmark(compact: true),
        actions: <Widget>[
          IconButton(
            tooltip: 'Configurações',
            onPressed: state.openSettings,
            icon: Icon(PhosphorIconsRegular.gear),
          ),
        ],
      ),
      body: state._mobileNowPlaying
          ? NowPlayingScreen(
              controller: state.widget.playerController,
              embedded: true,
            )
          : _MobileBrowse(state: state),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!state._mobileNowPlaying)
            MiniPlayer(
              controller: state.widget.playerController,
              onOpenNowPlaying: () {
                state.setMobileNowPlaying(true);
              },
            ),
          NavigationBar(
            selectedIndex: state._mobileNowPlaying ? 1 : 0,
            onDestinationSelected: (index) {
              state.setMobileNowPlaying(index == 1);
            },
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: Icon(PhosphorIconsRegular.musicNotes),
                selectedIcon: Icon(PhosphorIconsFill.musicNotes),
                label: 'Browse',
              ),
              NavigationDestination(
                icon: Icon(PhosphorIconsRegular.playCircle),
                selectedIcon: Icon(PhosphorIconsFill.playCircle),
                label: 'Now Playing',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MerakiSidebar extends StatelessWidget {
  const _MerakiSidebar({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        child: GlassPanel(
          enableBlur: false,
          padding: const EdgeInsets.all(14),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 28),
                child: _MerakiWordmark(),
              ),
              _SidebarDestination(
                label: 'Home',
                icon: PhosphorIconsRegular.house,
                selected: state._destination == _HomeDestination.home,
                onTap: () => state.setDestination(_HomeDestination.home),
              ),
              _SidebarDestination(
                label: 'Todas as Músicas',
                icon: PhosphorIconsRegular.musicNotes,
                selected: state._destination == _HomeDestination.allSongs,
                onTap: () => state.setDestination(_HomeDestination.allSongs),
              ),
              _SidebarDestination(
                label: 'Músicas baixadas',
                icon: PhosphorIconsRegular.downloadSimple,
                selected: state._destination == _HomeDestination.downloads,
                onTap: () => state.setDestination(_HomeDestination.downloads),
              ),
              _SidebarDestination(
                label: 'Álbuns',
                icon: PhosphorIconsRegular.disc,
                selected: state._destination == _HomeDestination.albums,
                onTap: () => state.setDestination(_HomeDestination.albums),
              ),
              _SidebarDestination(
                label: 'Artistas',
                icon: PhosphorIconsRegular.usersThree,
                selected: state._destination == _HomeDestination.artists,
                onTap: () => state.setDestination(_HomeDestination.artists),
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 12),
              _ProfileCard(userName: state.widget.userName),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: state.logout,
                icon: Icon(PhosphorIconsRegular.signOut, size: 18),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: selected ? accent : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : MerakiColors.softText,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TextField(
                onChanged: state.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por música, álbum ou artista',
                  prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            tooltip: 'Favoritos',
            onPressed: () {},
            icon: Icon(PhosphorIconsRegular.heart),
          ),
          IconButton(
            tooltip: 'Configurações',
            onPressed: state.openSettings,
            icon: Icon(PhosphorIconsRegular.gear),
          ),
          const SizedBox(width: 10),
          _ProfileHeader(userName: state.widget.userName),
        ],
      ),
    );
  }
}

class _DesktopContent extends StatelessWidget {
  const _DesktopContent({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state.widget.libraryController,
      builder: (context, _) {
        if (state.widget.libraryController.isLoading &&
            state.widget.libraryController.songs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return _ContentForDestination(state: state, desktop: true);
      },
    );
  }
}

class _MobileBrowse extends StatelessWidget {
  const _MobileBrowse({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state.widget.libraryController,
      builder: (context, _) {
        if (state.widget.libraryController.isLoading &&
            state.widget.libraryController.songs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return _ContentForDestination(state: state, desktop: false);
      },
    );
  }
}

class _ContentForDestination extends StatelessWidget {
  const _ContentForDestination({required this.state, required this.desktop});

  final _HomeScreenState state;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return switch (state._destination) {
      _HomeDestination.home => _HomeDashboard(state: state, desktop: desktop),
      _HomeDestination.allSongs => _SongsPage(
        title: 'Todas as músicas',
        songs: state.filteredSongs,
        state: state,
      ),
      _HomeDestination.downloads => _SongsPage(
        title: 'Músicas baixadas',
        songs: state.filteredSongs
            .where((song) => song.source == SongSource.local)
            .toList(growable: false),
        state: state,
        emptyTitle: 'Nenhuma música baixada ainda',
      ),
      _HomeDestination.albums => _AlbumsPage(state: state),
      _HomeDestination.artists => _ArtistsPage(state: state),
    };
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({required this.state, required this.desktop});

  final _HomeScreenState state;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final songs = state.filteredSongs;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            desktop ? 34 : 20,
            12,
            desktop ? 34 : 20,
            28,
          ),
          sliver: SliverMainAxisGroup(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _DashboardGreeting(
                  desktop: desktop,
                  userName: state.widget.userName,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Meraki Spotlight',
                  subtitle: 'Uma seleção que combina com o seu momento',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: CoverFlowSpotlight(
                  songs: songs,
                  onPlay: (song) => state.playSong(song, songs),
                  desktop: desktop,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Popular songs',
                  actionLabel: 'Ver todas',
                  onAction: () =>
                      state.setDestination(_HomeDestination.allSongs),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              _PopularGrid(songs: songs, state: state, desktop: desktop),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardGreeting extends StatelessWidget {
  const _DashboardGreeting({required this.desktop, required this.userName});

  final bool desktop;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                desktop ? 'Olá, $userName' : 'Browse Music',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desktop
                    ? 'Seu som, com a sua identidade.'
                    : 'Descubra o que combina com seu dia.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: MerakiColors.softText),
              ),
            ],
          ),
        ),
        if (!desktop)
          IconButton(
            tooltip: 'Atualizar biblioteca',
            onPressed: () {},
            icon: Icon(PhosphorIconsRegular.arrowClockwise),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    this.subtitle,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(color: MerakiColors.softText),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _SpotlightCarousel extends StatefulWidget {
  const _SpotlightCarousel({
    required this.songs,
    required this.onPlay,
    required this.desktop,
  });

  final List<Song> songs;
  final ValueChanged<Song> onPlay;
  final bool desktop;

  @override
  State<_SpotlightCarousel> createState() => _SpotlightCarouselState();
}

class _SpotlightCarouselState extends State<_SpotlightCarousel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.songs.take(7).toList(growable: false);
    final cardWidth = widget.desktop ? 330.0 : 270.0;
    return SizedBox(
      height: widget.desktop ? 260 : 230,
      child: Stack(
        children: <Widget>[
          ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(right: 56),
            itemCount: math.max(cards.length, 4),
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final song = index < cards.length ? cards[index] : null;
              return SizedBox(
                width: cardWidth,
                child: _SpotlightCard(
                  song: song,
                  index: index,
                  onPlay: song == null ? null : () => widget.onPlay(song),
                  desktop: widget.desktop,
                ),
              );
            },
          ),
          if (widget.desktop)
            Positioned(
              right: 0,
              top: 98,
              child: _CarouselArrow(
                icon: PhosphorIconsRegular.caretRight,
                onTap: () => _scrollBy(260),
              ),
            ),
          if (widget.desktop)
            Positioned(
              left: 0,
              top: 98,
              child: _CarouselArrow(
                icon: PhosphorIconsRegular.caretLeft,
                onTap: () => _scrollBy(-260),
              ),
            ),
        ],
      ),
    );
  }

  void _scrollBy(double delta) {
    final target = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({
    required this.song,
    required this.index,
    required this.onPlay,
    required this.desktop,
  });

  final Song? song;
  final int index;
  final VoidCallback? onPlay;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final title = song?.title ?? 'Seu próximo som';
    final artist = song?.artist ?? 'Meraki Radio';
    return Transform.rotate(
      angle: desktop ? (index.isEven ? -0.018 : 0.018) : 0,
      child: RepaintBoundary(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPlay,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: <Color>[
                  accent.withValues(alpha: 0.70),
                  const Color(0xFF2A1E47),
                  const Color(0xFF0E0A1B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 28,
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (song != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Opacity(
                      opacity: 0.72,
                      child: CoverArtImage(
                        coverArtUrlOrPath: song!.coverArtUrlOrPath,
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.transparent,
                        const Color(0xFF120E21).withValues(alpha: 0.94),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              artist,
                              style: const TextStyle(
                                color: MerakiColors.softText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onPlay,
                          color: MerakiColors.deepPurple,
                          icon: Icon(PhosphorIconsFill.play),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: MerakiColors.deepPurple),
      ),
    );
  }
}

class _CategoryChips extends StatefulWidget {
  const _CategoryChips();

  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  static const _categories = <String>[
    'All',
    'Relax',
    'Sad',
    'Party',
    'Romance',
    'Energetic',
    'Jazz',
    'Alternative',
  ];
  var _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: _selected == category,
            onSelected: (_) => setState(() => _selected = category),
          );
        },
      ),
    );
  }
}

class _PopularGrid extends StatefulWidget {
  const _PopularGrid({
    required this.songs,
    required this.state,
    required this.desktop,
  });

  final List<Song> songs;
  final _HomeScreenState state;
  final bool desktop;

  @override
  State<_PopularGrid> createState() => _PopularGridState();
}

class _PopularGridState extends State<_PopularGrid> {
  List<Song> _items = const <Song>[];
  String _catalogSignature = '';

  @override
  void initState() {
    super.initState();
    _refreshSelection();
  }

  @override
  void didUpdateWidget(covariant _PopularGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshSelection();
  }

  void _refreshSelection() {
    final signature = widget.songs.map((song) => song.id).join('|');
    if (signature == _catalogSignature) return;

    final selection = List<Song>.of(widget.songs)
      ..shuffle(math.Random(signature.hashCode));
    _catalogSignature = signature;
    _items = selection.take(widget.desktop ? 12 : 8).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyCatalogHint());
    }
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.desktop ? 6 : 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: widget.desktop ? 0.78 : 0.82,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) => _PopularSongCard(
        song: _items[index],
        onTap: () => widget.state.playSong(_items[index], widget.songs),
      ),
    );
  }
}

class _PopularSongCard extends StatefulWidget {
  const _PopularSongCard({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  State<_PopularSongCard> createState() => _PopularSongCardState();
}

class _PopularSongCardState extends State<_PopularSongCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.045 : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? accent.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: _hovered
                ? <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.42),
                      blurRadius: 24,
                      spreadRadius: -6,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Material(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CoverArtImage(
                              coverArtUrlOrPath: widget.song.coverArtUrlOrPath,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _hovered ? 1 : 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    PhosphorIconsFill.play,
                                    size: 17,
                                    color: MerakiColors.deepPurple,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.song.artist ?? 'Artista desconhecido',
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
            ),
          ),
        ),
      ),
    );
  }
}

class _SongsPage extends StatelessWidget {
  const _SongsPage({
    required this.title,
    required this.songs,
    required this.state,
    this.emptyTitle,
  });

  final String title;
  final List<Song> songs;
  final _HomeScreenState state;
  final String? emptyTitle;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return _EmptyCatalogHint(title: emptyTitle);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      itemCount: songs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          );
        }
        final song = songs[index - 1];
        return SongTile(song: song, onPlay: () => state.playSong(song, songs));
      },
    );
  }
}

class _AlbumsPage extends StatelessWidget {
  const _AlbumsPage({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    final albums = state.widget.libraryController.albums.entries.toList();
    if (albums.isEmpty) return const _EmptyCatalogHint();
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.86,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final entry = albums[index];
        final first = entry.value.first;
        return _PopularSongCard(
          song: first,
          onTap: () => state.playSong(first, entry.value),
        );
      },
    );
  }
}

class _ArtistsPage extends StatelessWidget {
  const _ArtistsPage({required this.state});

  final _HomeScreenState state;

  @override
  Widget build(BuildContext context) {
    final artists = <String, List<Song>>{};
    for (final song in state.filteredSongs) {
      final artist = song.artist?.trim();
      final key = artist == null || artist.isEmpty
          ? 'Artista desconhecido'
          : artist;
      artists.putIfAbsent(key, () => <Song>[]).add(song);
    }
    final entries = artists.entries.toList();
    if (entries.isEmpty) return const _EmptyCatalogHint();
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: entries.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Artistas',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          );
        }
        final entry = entries[index - 1];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(PhosphorIconsRegular.userCircle),
          ),
          title: Text(entry.key),
          subtitle: Text(
            '${entry.value.length} faixa${entry.value.length == 1 ? '' : 's'}',
          ),
          trailing: Icon(PhosphorIconsRegular.caretRight),
          onTap: () => state.playSong(entry.value.first, entry.value),
        );
      },
    );
  }
}

class _EmptyCatalogHint extends StatelessWidget {
  const _EmptyCatalogHint({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassPanel(
          enableBlur: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                PhosphorIconsRegular.musicNotes,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title ?? 'Sua biblioteca ainda está vazia',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Conecte seu Subsonic ou selecione uma pasta de músicas para começar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MerakiColors.softText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerakiWordmark extends StatelessWidget {
  const _MerakiWordmark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              PhosphorIconsFill.musicNotes,
              color: MerakiColors.deepPurple,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'MERAKI',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xFF4A375C),
          child: Icon(Icons.person_rounded, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Text(userName, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const CircleAvatar(
          backgroundColor: Color(0xFF4A375C),
          child: Icon(Icons.person_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
