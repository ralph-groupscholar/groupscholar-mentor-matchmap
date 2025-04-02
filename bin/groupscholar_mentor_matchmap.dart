import 'dart:io';

import 'package:args/args.dart';
import 'package:groupscholar_mentor_matchmap/config.dart';
import 'package:groupscholar_mentor_matchmap/db.dart';
import 'package:groupscholar_mentor_matchmap/matcher.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('seed')
    ..addCommand('suggest')
    ..addCommand('record')
    ..addFlag('help', abbr: 'h', negatable: false);

  final argResults = parser.parse(arguments);

  if (argResults['help'] == true || argResults.command == null) {
    _printUsage(parser);
    exit(0);
  }

  final config = DbConfig.fromEnv();
  final db = DbClient(config);

  switch (argResults.command?.name) {
    case 'seed':
      await db.withConnection((connection) async {
        await db.seed(connection);
      });
      stdout.writeln('Seeded mentor matchmap data.');
      break;
    case 'suggest':
      await db.withConnection((connection) async {
        await db.createTables(connection);
        final mentors = await db.fetchMentors(connection);
        final scholars = await db.fetchScholars(connection);
        final engine = MatchEngine();
        final suggestions = engine.suggest(mentors: mentors, scholars: scholars);

        if (suggestions.isEmpty) {
          stdout.writeln('No suggestions available.');
          return;
        }

        for (final suggestion in suggestions) {
          stdout.writeln(
            '${suggestion.scholar.name} -> ${suggestion.mentor.name} | score ${suggestion.score.toStringAsFixed(1)}',
          );
          for (final reason in suggestion.reasons) {
            stdout.writeln('  - $reason');
          }
        }
      });
      break;
    case 'record':
      await db.withConnection((connection) async {
        await db.createTables(connection);
        final mentors = await db.fetchMentors(connection);
        final scholars = await db.fetchScholars(connection);
        final engine = MatchEngine();
        final suggestions = engine.suggest(mentors: mentors, scholars: scholars);

        if (suggestions.isEmpty) {
          stdout.writeln('No suggestions to record.');
          return;
        }

        for (final suggestion in suggestions) {
          await db.recordDecision(connection, suggestion);
        }

        stdout.writeln('Recorded ${suggestions.length} match decisions.');
      });
      break;
    default:
      _printUsage(parser);
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Group Scholar Mentor Matchmap');
  stdout.writeln('');
  stdout.writeln('Usage: dart run bin/groupscholar_mentor_matchmap.dart <command>');
  stdout.writeln('');
  stdout.writeln('Commands:');
  stdout.writeln('  seed     Create tables and seed mentors/scholars.');
  stdout.writeln('  suggest  Generate mentor match suggestions.');
  stdout.writeln('  record   Persist current suggestions as decisions.');
  stdout.writeln('');
  stdout.writeln('Environment variables:');
  stdout.writeln('  PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD');
  stdout.writeln('  Optional: PGSCHEMA (default mentor_matchmap), PGSSLMODE');
}
