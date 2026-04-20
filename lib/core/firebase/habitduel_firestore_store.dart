import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/duel.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/leaderboard_entry.dart';

class HabitDuelFirestoreStore {
  HabitDuelFirestoreStore([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _duels =>
      _firestore.collection('duels');

  Future<UserProfile?> readProfile(String userId) async {
    final userDoc = await _users.doc(userId).get();
    if (!userDoc.exists) {
      return null;
    }

    final badgesSnap = await _users.doc(userId).collection('badges').get();
    final badges = badgesSnap.docs.map((doc) {
      final data = doc.data();
      return ProfileBadge(
        badgeType: data['badgeType'] as String? ?? doc.id,
        earnedAt: _readDateTime(data['earnedAt']) ?? DateTime.now().toUtc(),
      );
    }).toList();

    final data = userDoc.data() ?? const <String, dynamic>{};
    return UserProfile(
      id: userId,
      username: data['username'] as String? ?? '',
      email: data['email'] as String?,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      losses: (data['losses'] as num?)?.toInt() ?? 0,
      badges: badges,
    );
  }

  Future<void> upsertProfile(UserProfile profile) async {
    try {
      final batch = _firestore.batch();
      final userRef = _users.doc(profile.id);

      batch.set(
        userRef,
        {
          'id': profile.id,
          'username': profile.username,
          if (profile.email != null) 'email': profile.email,
          'wins': profile.wins,
          'losses': profile.losses,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (final badge in profile.badges) {
        batch.set(
          userRef.collection('badges').doc(badge.badgeType),
          {
            'badgeType': badge.badgeType,
            'earnedAt': Timestamp.fromDate(badge.earnedAt.toUtc()),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (error) {
      debugPrint('Firestore profile mirror failed: $error');
    }
  }

  Future<List<Duel>> readMyDuels(String userId) async {
    final snapshot = await _duels
        .where('participantIds', arrayContains: userId)
        .get();
    final duels = snapshot.docs.map(_duelFromSnapshot).toList();
    duels.sort((a, b) {
      final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreated.compareTo(aCreated);
    });
    return duels;
  }

  Future<Duel?> readDuel(String duelId) async {
    final duelDoc = await _duels.doc(duelId).get();
    if (!duelDoc.exists) {
      return null;
    }

    final participantSnap = await duelDoc.reference.collection('participants').get();
    final checkinSnap = await duelDoc.reference.collection('checkins').get();

    return _duelFromDocument(
      duelDoc,
      participants: participantSnap.docs,
      checkins: checkinSnap.docs,
    );
  }

  Future<({List<LeaderboardEntry> entries, int total})> readLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    final snapshot = await _users.get();
    final docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aWins = (aData['wins'] as num?)?.toInt() ?? 0;
      final bWins = (bData['wins'] as num?)?.toInt() ?? 0;
      if (aWins != bWins) {
        return bWins.compareTo(aWins);
      }
      final aUsername = (aData['username'] as String? ?? '').toLowerCase();
      final bUsername = (bData['username'] as String? ?? '').toLowerCase();
      return aUsername.compareTo(bUsername);
    });

    final total = docs.length;
    final sliced = docs.skip(offset).take(limit).toList(growable: false);
    final entries = <LeaderboardEntry>[];
    var rank = 0;
    int? previousWins;
    for (final doc in sliced) {
      final data = doc.data();
      final wins = (data['wins'] as num?)?.toInt() ?? 0;
      if (previousWins == null || wins != previousWins) {
        rank++;
        previousWins = wins;
      }
      entries.add(
        LeaderboardEntry(
          rank: rank,
          userId: doc.id,
          username: data['username'] as String? ?? '',
          wins: wins,
          losses: (data['losses'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return (entries: entries, total: total);
  }

  Future<void> upsertDuel(Duel duel) async {
    try {
      final duelRef = _duels.doc(duel.id);
      final batch = _firestore.batch();
      final participantIds = duel.participants
          .map((participant) => participant.userId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      batch.set(
        duelRef,
        {
          'id': duel.id,
          'habitName': duel.habitName,
          if (duel.description != null) 'description': duel.description,
          if (duel.creatorId != null) 'creatorId': duel.creatorId,
          if (duel.opponentId != null) 'opponentId': duel.opponentId,
          'status': duel.status,
          'durationDays': duel.durationDays,
          'myStreak': duel.myStreak,
          'opponentStreak': duel.opponentStreak,
          if (duel.startsAt != null) 'startsAt': Timestamp.fromDate(duel.startsAt!.toUtc()),
          if (duel.endsAt != null) 'endsAt': Timestamp.fromDate(duel.endsAt!.toUtc()),
          if (duel.createdAt != null) 'createdAt': Timestamp.fromDate(duel.createdAt!.toUtc()),
          'participantIds': participantIds,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (final participant in duel.participants) {
        batch.set(
          duelRef.collection('participants').doc(participant.userId),
          {
            'userId': participant.userId,
            'username': participant.username,
            'streak': participant.streak,
            'lastCheckin': participant.lastCheckin,
          },
          SetOptions(merge: true),
        );
      }

      for (final checkin in duel.checkins) {
        batch.set(
          duelRef.collection('checkins').doc(checkin.id),
          {
            'id': checkin.id,
            'userId': checkin.userId,
            'username': checkin.username,
            'checkedAt': Timestamp.fromDate(checkin.checkedAt.toUtc()),
            if (checkin.note != null) 'note': checkin.note,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (error) {
      debugPrint('Firestore duel mirror failed: $error');
    }
  }

  Duel _duelFromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot) {
    return _duelFromData(snapshot.id, snapshot.data());
  }

  Duel _duelFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> participants = const [],
    List<QueryDocumentSnapshot<Map<String, dynamic>>> checkins = const [],
  }) {
    final duel = _duelFromData(doc.id, doc.data() ?? const <String, dynamic>{});

    final parsedParticipants = participants
        .map(
          (doc) => DuelParticipant(
            userId: doc.data()['userId'] as String? ?? doc.id,
            username: doc.data()['username'] as String? ?? doc.id,
            streak: (doc.data()['streak'] as num?)?.toInt() ?? 0,
            lastCheckin: doc.data()['lastCheckin'] as String?,
          ),
        )
        .toList(growable: false);

    final parsedCheckins = checkins
        .map(
          (doc) => CheckInEntry(
            id: doc.data()['id'] as String? ?? doc.id,
            userId: doc.data()['userId'] as String? ?? '',
            username: doc.data()['username'] as String? ?? '',
            checkedAt: _readDateTime(doc.data()['checkedAt']) ?? DateTime.now().toUtc(),
            note: doc.data()['note'] as String?,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));

    return Duel(
      id: duel.id,
      habitName: duel.habitName,
      description: duel.description,
      status: duel.status,
      durationDays: duel.durationDays,
      creatorId: duel.creatorId,
      opponentId: duel.opponentId,
      myStreak: duel.myStreak,
      opponentStreak: duel.opponentStreak,
      startsAt: duel.startsAt,
      endsAt: duel.endsAt,
      createdAt: duel.createdAt,
      participants: parsedParticipants.isNotEmpty ? parsedParticipants : duel.participants,
      checkins: parsedCheckins,
    );
  }

  Duel _duelFromData(String duelId, Map<String, dynamic> data) {
    final participantIds = (data['participantIds'] as List<dynamic>? ?? const [])
        .cast<String>();

    return Duel(
      id: duelId,
      habitName: data['habitName'] as String? ?? '',
      description: data['description'] as String?,
      status: data['status'] as String? ?? 'pending',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 0,
      creatorId: data['creatorId'] as String?,
      opponentId: data['opponentId'] as String?,
      myStreak: (data['myStreak'] as num?)?.toInt() ?? 0,
      opponentStreak: (data['opponentStreak'] as num?)?.toInt() ?? 0,
      startsAt: _readDateTime(data['startsAt']),
      endsAt: _readDateTime(data['endsAt']),
      createdAt: _readDateTime(data['createdAt']),
      participants: participantIds
          .map(
            (participantId) => DuelParticipant(
              userId: participantId,
              username: participantId,
            ),
          )
          .toList(growable: false),
      checkins: const [],
    );
  }

  DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  Future<void> mirrorUserFromAuth(User user) async {
    try {
      await _users.doc(user.id).set(
        {
          'id': user.id,
          'username': user.username,
          if (user.email != null) 'email': user.email,
          'wins': user.wins,
          'losses': user.losses,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('Firestore auth mirror failed: $error');
    }
  }

  Future<void> mirrorLeaderboardUsers(Iterable<LeaderboardEntry> entries) async {
    try {
      final batch = _firestore.batch();
      for (final entry in entries) {
        batch.set(
          _users.doc(entry.userId),
          {
            'id': entry.userId,
            'username': entry.username,
            'wins': entry.wins,
            'losses': entry.losses,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (error) {
      debugPrint('Firestore leaderboard mirror failed: $error');
    }
  }

  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    try {
      await _users.doc(userId).collection('devices').doc(token).set(
        {
          'token': token,
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('Firestore device token registration failed: $error');
    }
  }
}
