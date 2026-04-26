import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/app_update_info.dart';
import '../firebase/habitduel_firestore_store.dart';

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.currentVersionName,
    required this.currentVersionCode,
    this.remote,
    this.updateAvailable = false,
    this.shouldPrompt = false,
  });

  final String currentVersionName;
  final int currentVersionCode;
  final AppUpdateInfo? remote;
  final bool updateAvailable;
  final bool shouldPrompt;
}

class AppUpdateService {
  AppUpdateService(this._store);

  final HabitDuelFirestoreStore _store;

  static const _dismissedVersionCodeKey = 'dismissed_update_version_code';

  Future<AppUpdateCheckResult> checkForUpdate({bool manual = false}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const AppUpdateCheckResult(
        currentVersionName: '',
        currentVersionCode: 0,
      );
    }

    final info = await PackageInfo.fromPlatform();
    final currentVersionCode = int.tryParse(info.buildNumber) ?? 0;
    final remote = await _store.readAndroidAppUpdate();

    if (remote == null || !remote.enabled || !remote.hasDownloadUrl) {
      return AppUpdateCheckResult(
        currentVersionName: info.version,
        currentVersionCode: currentVersionCode,
        remote: remote,
      );
    }

    final updateAvailable = remote.versionCode > currentVersionCode;
    if (!updateAvailable) {
      return AppUpdateCheckResult(
        currentVersionName: info.version,
        currentVersionCode: currentVersionCode,
        remote: remote,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final dismissedVersion = prefs.getInt(_dismissedVersionCodeKey) ?? -1;
    final shouldPrompt = manual ||
        remote.forceUpdate ||
        dismissedVersion != remote.versionCode;

    return AppUpdateCheckResult(
      currentVersionName: info.version,
      currentVersionCode: currentVersionCode,
      remote: remote,
      updateAvailable: true,
      shouldPrompt: shouldPrompt,
    );
  }

  Future<void> dismissVersion(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedVersionCodeKey, versionCode);
  }

  Future<bool> openDownload(AppUpdateInfo update) async {
    final uri = Uri.tryParse(update.apkUrl);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
