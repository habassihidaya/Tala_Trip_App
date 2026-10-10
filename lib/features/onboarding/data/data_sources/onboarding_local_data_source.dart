import 'package:shared_preferences/shared_preferences.dart';

class OnboardingLocalDataSource {
  final SharedPreferencesAsync _preferences;

  OnboardingLocalDataSource(this._preferences);

  static const _completedKey = 'onboarding_completed';

  Future<bool> isCompleted() async {
    return await _preferences.getBool(_completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    await _preferences.setBool(_completedKey, true);
  }
}
