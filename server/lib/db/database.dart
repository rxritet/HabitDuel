import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// Manages a single PostgreSQL [Connection] for the application.
///
/// In production you'd use a connection pool; `postgres` v3 provides
/// pooling through [Pool]. For the MVP we keep a single connection
/// that is shared across handlers and lazily opened.
class Database {
  Database._();

  static Connection? _connection;

  /// Returns an open database connection, creating one if needed.
  static Future<Connection> get connection async {
    if (_connection != null) return _connection!;
    return await _open();
  }

  /// Opens a new connection using environment variables.
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

  /// Closes the connection and resets the singleton.
  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
