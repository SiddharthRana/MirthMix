import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../content/content.dart';

/// Overridden in main() (and tests) with the instance loaded at startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// Overridden in main() (and tests) with the content loaded and checked at startup.
final contentProvider = Provider<ContentLibrary>((ref) => throw UnimplementedError());

/// Whether premium content is unlocked. Always false until billing lands in Phase 4, where it
/// will come from server-verified entitlements, never from a client-side flag.
final premiumProvider = Provider<bool>((ref) => false);

/// Keeps the screen on during play. Behind an interface so tests don't need the platform plugin.
abstract interface class ScreenAwake {
  Future<void> enable();
  Future<void> disable();
}

class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();
  @override
  Future<void> enable() => WakelockPlus.enable();
  @override
  Future<void> disable() => WakelockPlus.disable();
}

final screenAwakeProvider = Provider<ScreenAwake>((ref) => const WakelockScreenAwake());
