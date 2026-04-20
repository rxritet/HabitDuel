import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/leaderboard_entry.dart';
import 'core_providers.dart';

// ─── Состояние ─────────────────────────────────────────────────────────

sealed class LeaderboardState {
  const LeaderboardState();
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  const LeaderboardLoaded(this.entries, {this.total = 0});
  final List<LeaderboardEntry> entries;
  final int total;
}

class LeaderboardError extends LeaderboardState {
  const LeaderboardError(this.message);
  final String message;
}

// ─── Обработчик ────────────────────────────────────────────────────────

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier(this._ref) : super(const LeaderboardInitial());
  final Ref _ref;

  Future<void> load({int limit = 50, int offset = 0}) async {
    state = const LeaderboardLoading();
    try {
      final result = await _ref
          .read(leaderboardRemoteDSProvider)
          .getLeaderboard(limit: limit, offset: offset);
      state = LeaderboardLoaded(result.entries, total: result.total);
    } on Failure catch (e) {
      if (e is NetworkFailure) {
        state = const LeaderboardLoaded([]);
        return;
      }
      state = LeaderboardError(e.message);
    } catch (e) {
      state = LeaderboardError(e.toString());
    }
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});
