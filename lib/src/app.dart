import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meraki/src/audio/meraki_audio_handler.dart';
import 'package:meraki/src/data/music_repository.dart';
import 'package:meraki/src/data/release_update_service.dart';
import 'package:meraki/src/data/user_preferences.dart';
import 'package:meraki/src/ui/controllers/library_controller.dart';
import 'package:meraki/src/ui/controllers/player_controller.dart';
import 'package:meraki/src/ui/meraki_theme.dart';
import 'package:meraki/src/ui/screens/home_screen.dart';
import 'package:meraki/src/ui/screens/welcome_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ReleaseUpdateService _releaseUpdateService = ReleaseUpdateService();
  late final LibraryController _libraryController = LibraryController(
    repository: widget.repository,
    userPreferences: widget.userPreferences,
    audioHandler: widget.audioHandler,
  );
  late final PlayerController _playerController = PlayerController(
    audioHandler: widget.audioHandler,
  );
  late String? _userName = widget.initialUserName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  void _completeWelcome(String userName) {
    setState(() => _userName = userName);
  }

  Future<void> _logout() async {
    await widget.userPreferences.clearUserName();
    if (mounted) setState(() => _userName = null);
  }

  Future<void> _checkForUpdate() async {
    // PackageInfo must be queried after runApp. This callback also ensures a
    // first frame is visible before the network request starts.
    final packageInfo = await PackageInfo.fromPlatform();
    final update = await _releaseUpdateService.findAvailableUpdate(
      currentVersion: packageInfo.version,
    );
    if (!mounted || update == null) return;

    final updateContext = _navigatorKey.currentContext;
    if (updateContext == null || !updateContext.mounted) return;

    unawaited(
      showDialog<void>(
        context: updateContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Atualização disponível'),
          content: Text(
            'A versão ${update.version} do Meraki está disponível. '
            'Deseja abrir a página para atualizar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () async {
                final releaseUrl = update.releaseUrl;
                if (releaseUrl != null) {
                  await launchUrl(
                    releaseUrl,
                    mode: LaunchMode.externalApplication,
                  );
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Atualizar agora'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
