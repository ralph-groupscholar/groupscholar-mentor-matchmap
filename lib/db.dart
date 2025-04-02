import 'dart:async';

import 'package:postgres/postgres.dart';

import 'config.dart';
import 'models.dart';

class DbClient {
  DbClient(this.config);

  final DbConfig config;

  Future<Connection> _openConnection() {
    final sslRequired = config.sslMode.toLowerCase() == 'require';
    return Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.user,
        password: config.password,
      ),
      settings: ConnectionSettings(sslMode: sslRequired ? SslMode.require : SslMode.disable),
    );
  }

  Future<T> withConnection<T>(Future<T> Function(Connection connection) work) async {
    final connection = await _openConnection();
    try {
      return await work(connection);
    } finally {
      await connection.close();
    }
  }

  Future<void> ensureSchema(Connection connection) async {
    await connection.execute('CREATE SCHEMA IF NOT EXISTS ${config.schema}');
  }

  Future<void> createTables(Connection connection) async {
    await ensureSchema(connection);

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS ${config.schema}.mentors (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        region TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        tags TEXT[] NOT NULL,
        updated_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    ''');

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS ${config.schema}.scholars (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        region TEXT NOT NULL,
        tags TEXT[] NOT NULL,
        updated_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    ''');

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS ${config.schema}.match_decisions (
        id SERIAL PRIMARY KEY,
        mentor_id INTEGER NOT NULL REFERENCES ${config.schema}.mentors(id) ON DELETE CASCADE,
        scholar_id INTEGER NOT NULL REFERENCES ${config.schema}.scholars(id) ON DELETE CASCADE,
        score NUMERIC(6,2) NOT NULL,
        reasons TEXT[] NOT NULL,
        decided_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    ''');
  }

  Future<void> seed(Connection connection) async {
    await createTables(connection);

    final mentorCount = await connection
        .execute('SELECT COUNT(*) AS count FROM ${config.schema}.mentors');
    final scholarCount = await connection
        .execute('SELECT COUNT(*) AS count FROM ${config.schema}.scholars');

    final mentorTotal = mentorCount.first[0] as int;
    final scholarTotal = scholarCount.first[0] as int;

    if (mentorTotal == 0) {
      final mentors = [
        {
          'name': 'Aisha Coleman',
          'email': 'aisha.coleman@groupscholar.com',
          'region': 'Midwest',
          'capacity': 3,
          'tags': ['stem', 'first-gen', 'internships']
        },
        {
          'name': 'Luis Hernandez',
          'email': 'luis.hernandez@groupscholar.com',
          'region': 'West',
          'capacity': 2,
          'tags': ['business', 'entrepreneurship', 'transfer']
        },
        {
          'name': 'Priya Shah',
          'email': 'priya.shah@groupscholar.com',
          'region': 'South',
          'capacity': 4,
          'tags': ['health', 'mentoring', 'scholarships']
        },
        {
          'name': 'Derek Thompson',
          'email': 'derek.thompson@groupscholar.com',
          'region': 'Northeast',
          'capacity': 1,
          'tags': ['arts', 'portfolio', 'essay']
        },
      ];

      for (final mentor in mentors) {
        await connection.execute(
          Sql.named(
            'INSERT INTO ${config.schema}.mentors (name, email, region, capacity, tags) VALUES (@name, @email, @region, @capacity, @tags)',
          ),
          parameters: {
            'name': mentor['name'],
            'email': mentor['email'],
            'region': mentor['region'],
            'capacity': mentor['capacity'],
            'tags': mentor['tags'],
          },
        );
      }
    }

    if (scholarTotal == 0) {
      final scholars = [
        {
          'name': 'Maya Patel',
          'email': 'maya.patel@student.org',
          'region': 'Midwest',
          'tags': ['stem', 'research', 'internships']
        },
        {
          'name': 'Jordan Lee',
          'email': 'jordan.lee@student.org',
          'region': 'West',
          'tags': ['business', 'startup', 'transfer']
        },
        {
          'name': 'Carmen Ruiz',
          'email': 'carmen.ruiz@student.org',
          'region': 'South',
          'tags': ['health', 'service', 'scholarships']
        },
        {
          'name': 'Noah Green',
          'email': 'noah.green@student.org',
          'region': 'Northeast',
          'tags': ['arts', 'portfolio', 'essay']
        },
        {
          'name': 'Talia Johnson',
          'email': 'talia.johnson@student.org',
          'region': 'South',
          'tags': ['stem', 'first-gen', 'leadership']
        },
      ];

      for (final scholar in scholars) {
        await connection.execute(
          Sql.named(
            'INSERT INTO ${config.schema}.scholars (name, email, region, tags) VALUES (@name, @email, @region, @tags)',
          ),
          parameters: {
            'name': scholar['name'],
            'email': scholar['email'],
            'region': scholar['region'],
            'tags': scholar['tags'],
          },
        );
      }
    }
  }

  Future<List<Mentor>> fetchMentors(Connection connection) async {
    final rows = await connection.execute(
      'SELECT id, name, email, region, capacity, tags FROM ${config.schema}.mentors ORDER BY id',
    );

    return rows
        .map((row) => Mentor(
              id: row[0] as int,
              name: row[1] as String,
              email: row[2] as String,
              region: row[3] as String,
              capacity: row[4] as int,
              tags: (row[5] as List<dynamic>).cast<String>(),
            ))
        .toList();
  }

  Future<List<Scholar>> fetchScholars(Connection connection) async {
    final rows = await connection.execute(
      'SELECT id, name, email, region, tags FROM ${config.schema}.scholars ORDER BY id',
    );

    return rows
        .map((row) => Scholar(
              id: row[0] as int,
              name: row[1] as String,
              email: row[2] as String,
              region: row[3] as String,
              tags: (row[4] as List<dynamic>).cast<String>(),
            ))
        .toList();
  }

  Future<void> recordDecision(
    Connection connection,
    MatchSuggestion suggestion,
  ) async {
    await connection.execute(
      Sql.named(
        'INSERT INTO ${config.schema}.match_decisions (mentor_id, scholar_id, score, reasons) VALUES (@mentor_id, @scholar_id, @score, @reasons)',
      ),
      parameters: {
        'mentor_id': suggestion.mentor.id,
        'scholar_id': suggestion.scholar.id,
        'score': suggestion.score,
        'reasons': suggestion.reasons,
      },
    );
  }
}
