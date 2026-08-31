import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meraki/src/rust/models/song.dart';
import 'package:meraki/src/ui/meraki_theme.dart';
import 'package:meraki/src/ui/widgets/cover_art_image.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// A small, self-contained Cover Flow for the home spotlight section.
///
/// The PageView keeps only its visible neighbours alive. Each frame only
/// transforms those cards, instead of rebuilding a large horizontal list.
class CoverFlowSpotlight extends StatefulWidget {
  const CoverFlowSpotlight({
    required this.songs,
    required this.onPlay,
    required this.desktop,
    this.onSelectionChanged,
    super.key,
  });

  final List<Song> songs;
  final ValueChanged<Song> onPlay;
  final bool desktop;
  final ValueChanged<Song?>? onSelectionChanged;

  @override
  State<CoverFlowSpotlight> createState() => _CoverFlowSpotlightState();
}

class _CoverFlowSpotlightState extends State<CoverFlowSpotlight> {
  late final PageController _pageController = PageController(
    initialPage: 0,
    viewportFraction: 0.60,
  )..addListener(_syncPage);
  double _page = 0;
  String? _selectedSongId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishSelection());
  }

  @override
  void didUpdateWidget(covariant CoverFlowSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songs != widget.songs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _page = 0;
        if (_pageController.hasClients) _pageController.jumpToPage(0);
        _publishSelection();
      });
    }
  }

  void _syncPage() {
    final page = _pageController.page;
    if (page != null && mounted) {
      setState(() => _page = page);
      _publishSelection();
    }
  }

  void _publishSelection() {
    if (!mounted) return;
    final index = _page.round();
    final song = index >= 0 && index < widget.songs.length
        ? widget.songs[index]
        : null;
    if (_selectedSongId == song?.id) return;
    _selectedSongId = song?.id;
    widget.onSelectionChanged?.call(song);
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_syncPage)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The selection is randomized by HomeScreen whenever the user re-enters
    // the dashboard. Keep up to twelve items discoverable without inflating
    // the PageView's active widget count.
    final songs = widget.songs.take(12).toList(growable: false);
    final cardCount = math.max(songs.length, 4);

    return SizedBox(
      height: widget.desktop ? 286 : 242,
      child: PageView.builder(
        controller: _pageController,
        clipBehavior: Clip.none,
        padEnds: true,
        allowImplicitScrolling: true,
        itemCount: cardCount,
        itemBuilder: (context, index) {
          final song = index < songs.length ? songs[index] : null;
          final delta = _page - index;
          final distance = delta.abs().clamp(0.0, 1.0);
          final focused = distance < 0.32;

          return Transform.translate(
            offset: Offset(delta * 30, distance * 13),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(delta * 0.20),
              child: Transform.scale(
                alignment: Alignment.center,
                scale: 1 - (distance * 0.23),
                child: _CoverFlowCard(
                  song: song,
                  focused: focused,
                  onSelected: () {
                    if (!focused) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    } else if (song != null) {
                      widget.onPlay(song);
                    }
                  },
                  onPlay: song == null ? null : () => widget.onPlay(song),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoverFlowCard extends StatelessWidget {
  const _CoverFlowCard({
    required this.song,
    required this.focused,
    required this.onSelected,
    required this.onPlay,
  });

  final Song? song;
  final bool focused;
  final VoidCallback onSelected;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final title = song?.title ?? 'Seu próximo som';
    final artist = song?.artist ?? 'Meraki Radio';

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onSelected,
          child: Ink(
            decoration: BoxDecoration(
              color: MerakiColors.panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: focused
                    ? accent.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: focused
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.27),
                        blurRadius: 34,
                        spreadRadius: -12,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (song != null)
                    CoverArtImage(
                      coverArtUrlOrPath: song!.coverArtUrlOrPath,
                      cacheWidth: 800,
                      cacheHeight: 800,
                    ),
                  if (!focused)
                    ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.transparent,
                          MerakiColors.deepPurple.withValues(alpha: 0.96),
                        ],
                        stops: const <double>[0.38, 1],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 14,
                    bottom: 14,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: focused ? 1 : 0,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: MerakiColors.softText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
