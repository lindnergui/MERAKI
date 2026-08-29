import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:meraki/src/app.dart';
import 'package:meraki/src/audio/meraki_audio_handler.dart';
import 'package:meraki/src/data/music_repository.dart';
import 'package:meraki/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // just_audio uses media_kit on Linux. This must happen before the handler
  // creates its AudioPlayer; Android continues to use just_audio natively.
  JustAudioMediaKit.ensureInitialized();

  await RustLib.init();

  final repository = MusicRepository.instance;
  await repository.initialize();

  final audioHandler = await AudioService.init<MerakiAudioHandler>(
    builder: MerakiAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.meraki.player.audio',
      androidNotificationChannelName: 'Reprodução do Meraki',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(MerakiApp(repository: repository, audioHandler: audioHandler));
}
