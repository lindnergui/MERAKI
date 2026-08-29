import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meraki/src/rust/api/music.dart' as rust_music;
import 'package:meraki/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(RustLib.init);

  testWidgets('initializes SQLite through the Rust bridge', (tester) async {
    final directory = await Directory.systemTemp.createTemp('meraki_ffi_test_');
    addTearDown(() => directory.delete(recursive: true));

    await rust_music.initDb(databasePath: '${directory.path}/catalog.sqlite3');

    expect(await rust_music.getAllSongs(), isEmpty);
  });
}
