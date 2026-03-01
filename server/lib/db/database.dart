import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// \u0423\u043f\u0440\u0430\u0432\u043b\u044f\u0435\u0442 \u0435\u0434\u0438\u043d\u0441\u0442\u0432\u0435\u043d\u043d\u044b\u043c \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435\u043c PostgreSQL \u0434\u043b\u044f \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u044f.
///
/// \u0412 MVP \u0438\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0435\u0442\u0441\u044f \u043e\u0434\u043d\u043e \u043e\u0431\u0449\u0435\u0435 \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435, \u043e\u0442\u043a\u0440\u044b\u0432\u0430\u0435\u043c\u043e\u0435 \u043b\u0435\u043d\u0438\u0432\u043e.
class Database {
  Database._();

  static Connection? _connection;

  /// \u0412\u043e\u0437\u0432\u0440\u0430\u0449\u0430\u0435\u0442 \u043e\u0442\u043a\u0440\u044b\u0442\u043e\u0435 \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435, \u0441\u043e\u0437\u0434\u0430\u0432\u0430\u044f \u0435\u0433\u043e \u043f\u0440\u0438 \u043d\u0435\u043e\u0431\u0445\u043e\u0434\u0438\u043c\u043e\u0441\u0442\u0438.
  static Future<Connection> get connection async {
    if (_connection != null) return _connection!;
    return await _open();
  }

  /// \u041e\u0442\u043a\u0440\u044b\u0432\u0430\u0435\u0442 \u043d\u043e\u0432\u043e\u0435 \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435 \u0447\u0435\u0440\u0435\u0437 \u043f\u0435\u0440\u0435\u043c\u0435\u043d\u043d\u044b\u0435 \u0441\u0440\u0435\u0434\u044b.
  static Future<Connection> _open() async {
    final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

    _connection = await Connection.open(
      Endpoint(
        host: env['DB_HOST'] ?? 'localhost',
        port: int.parse(env['DB_PORT'] ?? '5432'),
        database: env['DB_NAME'] ?? 'habitduel',
        username: env['DB_USER'] ?? 'postgres',
        password: env['DB_PASSWORD'] ?? '',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    return _connection!;
  }

  /// \u0417\u0430\u043a\u0440\u044b\u0432\u0430\u0435\u0442 \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435 \u0438 \u0441\u0431\u0440\u0430\u0441\u044b\u0432\u0430\u0435\u0442 singleton.
  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
