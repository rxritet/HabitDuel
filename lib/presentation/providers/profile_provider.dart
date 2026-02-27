import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import 'core_providers.dart';

// ─── State ──────────────────────────────────────────────────────────────

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

// ─── Notifier ───────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ref) : super(const ProfileInitial());
  final Ref _ref;

  Future<void> load() async {
    state = const ProfileLoading();
    try {
      final profile = await _ref.read(profileRemoteDSProvider).getMyProfile();
      state = ProfileLoaded(profile);
    } on Failure catch (e) {
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
