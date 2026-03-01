import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/dio_client.dart';
import '../../data/datasources/auth_remote_ds.dart';
import '../../data/datasources/duel_remote_ds.dart';
import '../../data/datasources/leaderboard_remote_ds.dart';
import '../../data/datasources/profile_remote_ds.dart';
import '../../data/repositories/auth_repo_impl.dart';
import '../../data/repositories/duel_repo_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/duel_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/checkins/checkin_usecase.dart';
import '../../domain/usecases/duels/accept_duel_usecase.dart';
import '../../domain/usecases/duels/create_duel_usecase.dart';
import '../../domain/usecases/duels/get_duel_detail_usecase.dart';
import '../../domain/usecases/duels/get_my_duels_usecase.dart';

// ─── Инфраструктурные провайдеры ───────────────────────────────────────

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return createDioClient(storage);
});

// ─── Провайдеры слоя данных ────────────────────────────────────────────

final authRemoteDSProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDSProvider),
    ref.watch(secureStorageProvider),
  );
});

// ─── Провайдеры сценариев использования ────────────────────────────────

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// ─── Провайдеры данных дуэлей ──────────────────────────────────────────

final duelRemoteDSProvider = Provider<DuelRemoteDataSource>((ref) {
  return DuelRemoteDataSource(ref.watch(dioProvider));
});

final duelRepositoryProvider = Provider<DuelRepository>((ref) {
  return DuelRepositoryImpl(ref.watch(duelRemoteDSProvider));
});

// ─── Провайдеры сценариев дуэлей ───────────────────────────────────────

final createDuelUseCaseProvider = Provider<CreateDuelUseCase>((ref) {
  return CreateDuelUseCase(ref.watch(duelRepositoryProvider));
});

final acceptDuelUseCaseProvider = Provider<AcceptDuelUseCase>((ref) {
  return AcceptDuelUseCase(ref.watch(duelRepositoryProvider));
});

final getMyDuelsUseCaseProvider = Provider<GetMyDuelsUseCase>((ref) {
  return GetMyDuelsUseCase(ref.watch(duelRepositoryProvider));
});

final getDuelDetailUseCaseProvider = Provider<GetDuelDetailUseCase>((ref) {
  return GetDuelDetailUseCase(ref.watch(duelRepositoryProvider));
});

final checkInUseCaseProvider = Provider<CheckInUseCase>((ref) {
  return CheckInUseCase(ref.watch(duelRepositoryProvider));
});

// ─── Провайдеры данных таблицы лидеров и профиля ───────────────────────

final leaderboardRemoteDSProvider = Provider<LeaderboardRemoteDataSource>((ref) {
  return LeaderboardRemoteDataSource(ref.watch(dioProvider));
});

final profileRemoteDSProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(dioProvider));
});
