import 'dart:io';

class DbConfig {
  DbConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.user,
    required this.password,
    required this.schema,
    required this.sslMode,
  });

  final String host;
  final int port;
  final String database;
  final String user;
  final String password;
  final String schema;
  final String sslMode;

  static DbConfig fromEnv() {
    final host = _requireEnv('PGHOST');
    final port = int.parse(_requireEnv('PGPORT'));
    final database = _requireEnv('PGDATABASE');
    final user = _requireEnv('PGUSER');
    final password = _requireEnv('PGPASSWORD');
    final schema = Platform.environment['PGSCHEMA'] ?? 'mentor_matchmap';
    final sslMode = Platform.environment['PGSSLMODE'] ?? 'require';

    return DbConfig(
      host: host,
      port: port,
      database: database,
      user: user,
      password: password,
      schema: schema,
      sslMode: sslMode,
    );
  }

  static String _requireEnv(String key) {
    final value = Platform.environment[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }
    return value;
  }
}
