import 'package:flutter/material.dart';
import 'package:meraki/src/audio/meraki_audio_handler.dart';
import 'package:meraki/src/data/music_repository.dart';
import 'package:meraki/src/data/user_preferences.dart';
import 'package:meraki/src/ui/controllers/library_controller.dart';
import 'package:meraki/src/ui/controllers/player_controller.dart';
import 'package:meraki/src/ui/meraki_theme.dart';
import 'package:meraki/src/ui/screens/home_screen.dart';
import 'package:meraki/src/ui/screens/welcome_screen.dart';

class MerakiApp extends StatefulWidget {
  const MerakiApp({
    required this.repository,
    required this.audioHandler,
    required this.userPreferences,
    required this.initialUserName,
    super.key,
  });

  final MusicRepository repository;
  final MerakiAudioHandler audioHandler;
  final UserPreferences userPreferences;
  final String? initialUserName;

  @override
  State<MerakiApp> createState() => _MerakiAppState();
}

class _MerakiAppState extends State<MerakiApp> {
  late final LibraryController _libraryController = LibraryController(
    repository: widget.repository,
    userPreferences: widget.userPreferences,
    audioHandler: widget.audioHandler,
  );
  late final PlayerController _playerController = PlayerController(
    audioHandler: widget.audioHandler,
  );
  late String? _userName = widget.initialUserName;

  void _completeWelcome(String userName) {
    setState(() => _userName = userName);
  }

  Future<void> _logout() async {
    await widget.userPreferences.clearUserName();
    if (mounted) setState(() => _userName = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meraki',
      debugShowCheckedModeBanner: false,
      theme: buildMerakiTheme(),
      home: _userName == null
          ? WelcomeScreen(
              userPreferences: widget.userPreferences,
              onCompleted: _completeWelcome,
            )
          : HomeScreen(
              userName: _userName!,
              libraryController: _libraryController,
              playerController: _playerController,
              onLogout: _logout,
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
