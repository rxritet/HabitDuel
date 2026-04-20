import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../firebase/habitduel_firestore_store.dart';

class FcmService {
  FcmService._();

  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _storage = const FlutterSecureStorage();
  final _store = HabitDuelFirestoreStore();

  Future<void> init() async {
    if (kIsWeb) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await syncCurrentUserToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      syncToken(token);
    });
  }

  Future<void> syncCurrentUserToken() async {
    if (kIsWeb) return;
    final userId = await _storage.read(key: kUserIdKey);
    if (userId == null || userId.isEmpty) {
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await syncToken(token, userId: userId);
  }

  Future<void> syncToken(String token, {String? userId}) async {
    if (kIsWeb) return;

    final resolvedUserId = userId ?? await _storage.read(key: kUserIdKey);
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return;
    }

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };

    await _store.registerDeviceToken(
      userId: resolvedUserId,
      token: token,
      platform: platform,
    );
  }
}