import 'package:flutter/material.dart';
import 'package:meraki/src/audio/meraki_audio_handler.dart';
import 'package:meraki/src/data/music_repository.dart';
import 'package:meraki/src/ui/controllers/library_controller.dart';
import 'package:meraki/src/ui/controllers/player_controller.dart';
import 'package:meraki/src/ui/meraki_theme.dart';
import 'package:meraki/src/ui/screens/home_screen.dart';

class MerakiApp extends StatefulWidget {
  const MerakiApp({
    required this.repository,
    required this.audioHandler,
    super.key,
  });

  final MusicRepository repository;
  final MerakiAudioHandler audioHandler;

  @override
  State<MerakiApp> createState() => _MerakiAppState();
}

class _MerakiAppState extends State<MerakiApp> {
  late final LibraryController _libraryController = LibraryController(
    repository: widget.repository,
  );
  late final PlayerController _playerController = PlayerController(
    audioHandler: widget.audioHandler,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meraki',
      debugShowCheckedModeBanner: false,
      theme: buildMerakiTheme(),
      home: HomeScreen(
        libraryController: _libraryController,
        playerController: _playerController,
      ),
    );
  }

  @override
  void dispose() {
    _libraryController.dispose();
    _playerController.dispose();
    super.dispose();
  }
}
