import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

import 'package:habitduel_server/db/database.dart';

Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
  final exportDir = Directory(env['EXPORT_DIR'] ?? '../exports/firebase');
  if (!exportDir.existsSync()) {
    exportDir.createSync(recursive: true);
  }

  print('Exporting PostgreSQL data to ${exportDir.absolute.path} ...');

  final conn = await Database.connection;
  final manifest = <String, dynamic>{
    'exported_at': DateTime.now().toUtc().toIso8601String(),
    'source': {
      'db_host': env['DB_HOST'] ?? 'localhost',
      'db_port': env['DB_PORT'] ?? '5432',
      'db_name': env['DB_NAME'] ?? 'habitduel',
    },
    'files': <String, dynamic>{},
  };

  Future<void> dumpTable(String tableName, String query) async {
    final result = await conn.execute(Sql.named(query));
    final rows = result
        .map((row) => _normalize(row.toColumnMap()))
        .toList(growable: false);
    final file = File('${exportDir.path}/$tableName.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(rows));
    (manifest['files'] as Map<String, dynamic>)[tableName] = {
      'count': rows.length,
      'path': file.path,
    };
    print('  $tableName: ${rows.length} row(s)');
  }

  try {
    await dumpTable('users', 'SELECT * FROM users ORDER BY created_at ASC');
    await dumpTable('duels', 'SELECT * FROM duels ORDER BY created_at ASC');
    await dumpTable(
      'duel_participants',
      'SELECT * FROM duel_participants ORDER BY duel_id ASC, user_id ASC',
    );
    await dumpTable('checkins', 'SELECT * FROM checkins ORDER BY checked_at ASC');
    await dumpTable('badges', 'SELECT * FROM badges ORDER BY earned_at ASC');

    final manifestFile = File('${exportDir.path}/manifest.json');
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    print('Done. Manifest written to ${manifestFile.path}');
  } catch (e, st) {
    print('Export failed: $e');
    print(st);
    exitCode = 1;
  }
}

Object? _normalize(Object? value) {
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is Map) {
    return value.map((key, nestedValue) => MapEntry(key, _normalize(nestedValue)));
  }
  if (value is Iterable) {
    return value.map(_normalize).toList(growable: false);
  }
  return value;
}
