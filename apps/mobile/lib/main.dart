import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'content/content.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Fredoka', 'Nunito'], ofl);
  });

  final prefs = await SharedPreferences.getInstance();
  final ContentLibrary content;
  try {
    content = await ContentLibrary.load(rootBundle);
  } on Object catch (e) {
    debugPrint('Content failed to load: $e');
    runApp(const ContentErrorApp());
    return;
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs), contentProvider.overrideWithValue(content)],
      child: const MirthMixApp(),
    ),
  );
}
