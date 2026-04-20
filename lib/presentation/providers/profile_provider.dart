import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import 'core_providers.dart';

// ─── Состояние ─────────────────────────────────────────────────────────

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);
  final UserProfile profile;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}

// ─── Обработчик ────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ref) : super(const ProfileInitial());
  final Ref _ref;

  Future<void> load() async {
    state = const ProfileLoading();
    try {
      final profile = await _ref.read(profileRemoteDSProvider).getMyProfile();
      state = ProfileLoaded(profile);
    } on Failure catch (e) {
      if (e is NetworkFailure) {
        final storage = _ref.read(secureStorageProvider);
        final userId = await storage.read(key: kUserIdKey) ?? 'guest';
        final username = await storage.read(key: kUsernameKey) ?? 'Guest';
        state = ProfileLoaded(
          UserProfile(
            id: userId,
            username: username,
            wins: 0,
            losses: 0,
          ),
        );
        return;
      }
      state = ProfileError(e.message);
    } catch (e) {
      state = ProfileError(e.toString());
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});
