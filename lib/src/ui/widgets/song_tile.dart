import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meraki/src/rust/models/song.dart';
import 'package:meraki/src/ui/widgets/cover_art_image.dart';

enum _SongMenuAction { play }

class SongTile extends StatelessWidget {
  const SongTile({required this.song, required this.onPlay, super.key});

  final Song song;
  final Future<void> Function() onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CoverArtImage(
        coverArtUrlOrPath: song.coverArtUrlOrPath,
        width: 52,
        height: 52,
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(_subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _formatDuration(song.durationSeconds),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_SongMenuAction>(
            tooltip: 'Opções da música',
            onSelected: (action) {
              if (action == _SongMenuAction.play) {
                unawaited(onPlay());
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<_SongMenuAction>>[
              PopupMenuItem<_SongMenuAction>(
                value: _SongMenuAction.play,
                child: ListTile(
                  leading: Icon(Icons.play_arrow_rounded),
                  title: Text('Tocar agora'),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => unawaited(onPlay()),
      titleTextStyle: Theme.of(context).textTheme.titleMedium,
      iconColor: colors.primary,
    );
  }

  String get _subtitle {
    final artist = song.artist?.trim();
    final album = song.album?.trim();
    final parts = <String>[
      if (artist != null && artist.isNotEmpty) artist,
      if (album != null && album.isNotEmpty) album,
    ];
    return parts.isEmpty ? 'Artista desconhecido' : parts.join(' • ');
  }

  static String _formatDuration(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds <= 0) return '--:--';
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours == 0) return '$minutes:$seconds';
    return '${duration.inHours}:$minutes:$seconds';
  }
}
