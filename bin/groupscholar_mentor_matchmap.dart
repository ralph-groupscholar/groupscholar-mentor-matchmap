import 'dart:io';

import 'package:args/args.dart';
import 'package:groupscholar_mentor_matchmap/analysis.dart';
import 'package:groupscholar_mentor_matchmap/config.dart';
import 'package:groupscholar_mentor_matchmap/db.dart';
import 'package:groupscholar_mentor_matchmap/matcher.dart';

void main(List<String> arguments) async {
  final gapCommand = ArgParser()
    ..addOption('threshold', defaultsTo: '3');
  final scorecardCommand = ArgParser()
    ..addOption('top', defaultsTo: '3')
    ..addOption('min-score', defaultsTo: '3');

  final parser = ArgParser()
    ..addCommand('seed')
    ..addCommand('suggest')
    ..addCommand('record')
    ..addCommand('report')
    ..addCommand('gap', gapCommand)
    ..addCommand('coverage')
    ..addCommand('scorecard', scorecardCommand)
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
        final mentorCounts = await db.fetchMentorDecisionCounts(connection);
        final engine = MatchEngine();
        final suggestions = engine.suggest(
          mentors: mentors,
          scholars: scholars,
          mentorDecisionCounts: mentorCounts,
        );

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
        final mentorCounts = await db.fetchMentorDecisionCounts(connection);
        final engine = MatchEngine();
        final suggestions = engine.suggest(
          mentors: mentors,
          scholars: scholars,
          mentorDecisionCounts: mentorCounts,
        );

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
    case 'report':
      await db.withConnection((connection) async {
        await db.createTables(connection);
        final utilization = await db.fetchMentorUtilization(connection);
        stdout.writeln('Mentor capacity report');
        stdout.writeln('');
        for (final entry in utilization) {
          stdout.writeln(
            '${entry.mentor.name} (${entry.mentor.region}) '
            '- ${entry.matchedCount}/${entry.mentor.capacity} matched '
            '(${entry.remainingCapacity} remaining)',
          );
        }
        stdout.writeln('');
        final recent = await db.fetchRecentDecisions(connection);
        if (recent.isEmpty) {
          stdout.writeln('No match decisions recorded yet.');
          return;
        }
        stdout.writeln('Recent decisions');
        for (final decision in recent) {
          stdout.writeln(
            '${decision.scholarName} -> ${decision.mentorName} '
            '| score ${decision.score.toStringAsFixed(1)} '
            '| ${decision.decidedAt.toIso8601String()}',
          );
        }
      });
      break;
    case 'gap':
      await db.withConnection((connection) async {
        await db.createTables(connection);
        final mentors = await db.fetchMentors(connection);
        final scholars = await db.fetchScholars(connection);
        final mentorCounts = await db.fetchMentorDecisionCounts(connection);
        final engine = MatchEngine();
        final threshold = double.tryParse(
              argResults.command?.option('threshold') ?? '3',
            ) ??
            3;
        final mentorTagSet = mentors.expand((mentor) => mentor.tags).toSet();

        stdout.writeln('Match gap report (score threshold ${threshold.toStringAsFixed(1)})');
        stdout.writeln('');

        var gapCount = 0;
        for (final scholar in scholars) {
          final ranked = engine.rankMentorsForScholar(
            mentors: mentors,
            scholar: scholar,
            mentorDecisionCounts: mentorCounts,
          );
          final topScore = ranked.isEmpty ? 0.0 : ranked.first.score;
          final missingTags = scholar.tags
              .where((tag) => !mentorTagSet.contains(tag))
              .toList();

          if (ranked.isEmpty || topScore < threshold) {
            gapCount++;
            stdout.writeln(
              '${scholar.name} (${scholar.region}) - best score ${topScore.toStringAsFixed(1)}',
            );
            if (ranked.isNotEmpty) {
              stdout.writeln(
                '  Top mentor: ${ranked.first.mentor.name} (${ranked.first.mentor.region})',
              );
              for (final reason in ranked.first.reasons) {
                stdout.writeln('  - $reason');
              }
            } else {
              stdout.writeln('  No mentors available within capacity.');
            }
            if (missingTags.isNotEmpty) {
              stdout.writeln('  Uncovered tags: ${missingTags.join(', ')}');
            }
          }
        }

        if (gapCount == 0) {
          stdout.writeln('No gaps detected based on the current threshold.');
        }
      });
      break;
    case 'coverage':
      await db.withConnection((connection) async {
        await db.createTables(connection);
        final mentors = await db.fetchMentors(connection);
        final scholars = await db.fetchScholars(connection);
        final mentorCounts = await db.fetchMentorDecisionCounts(connection);
        final report = buildCoverageReport(
          mentors: mentors,
          scholars: scholars,
          mentorDecisionCounts: mentorCounts,
        );

        stdout.writeln('Mentor match coverage');
        stdout.writeln('');
        stdout.writeln('Tag gaps');
        if (report.missingMentorTags.isEmpty) {
          stdout.writeln('  All scholar tags have mentor coverage.');
        } else {
          for (final gap in report.missingMentorTags) {
            stdout.writeln('  Missing mentor tag: ${gap.tag} (${gap.count} scholars)');
          }
        }
        stdout.writeln('');
        stdout.writeln('Unused mentor tags');
        if (report.unusedMentorTags.isEmpty) {
          stdout.writeln('  All mentor tags appear in scholar demand.');
        } else {
          for (final gap in report.unusedMentorTags) {
            stdout.writeln('  Unused mentor tag: ${gap.tag} (${gap.count} mentors)');
          }
        }
        stdout.writeln('');
        stdout.writeln('Region capacity');
        for (final region in report.regionCoverage) {
          stdout.writeln(
            '  ${region.region}: demand ${region.scholarDemand}, '
            'remaining ${region.remainingCapacity}, gap ${region.gap}',
          );
        }
      });
      break;
    case 'scorecard':
      await db.withConnection((connection) async {
        await db.createTables(connection);
        final mentors = await db.fetchMentors(connection);
        final scholars = await db.fetchScholars(connection);
        final mentorCounts = await db.fetchMentorDecisionCounts(connection);
        final top = int.tryParse(argResults.command?.option('top') ?? '3') ?? 3;
        final minScore = double.tryParse(
              argResults.command?.option('min-score') ?? '3',
            ) ??
            3;

        final scorecards = buildScholarScorecards(
          mentors: mentors,
          scholars: scholars,
          mentorDecisionCounts: mentorCounts,
          topN: top,
          minScore: minScore,
        );

        stdout.writeln(
          'Scholar scorecards (top $top, min score ${minScore.toStringAsFixed(1)})',
        );
        stdout.writeln('');

        for (final scorecard in scorecards) {
          stdout.writeln(
            '${scorecard.scholar.name} (${scorecard.scholar.region}) '
            '- top score ${scorecard.topScore.toStringAsFixed(1)}',
          );
          if (scorecard.belowThreshold) {
            stdout.writeln('  Status: below min score threshold');
          }
          if (scorecard.rankedSuggestions.isEmpty) {
            stdout.writeln('  No mentors available within capacity.');
            continue;
          }
          for (final suggestion in scorecard.rankedSuggestions) {
            stdout.writeln(
              '  ${suggestion.mentor.name} (${suggestion.mentor.region}) '
              '| score ${suggestion.score.toStringAsFixed(1)}',
            );
            for (final reason in suggestion.reasons) {
              stdout.writeln('    - $reason');
            }
          }
        }
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
  stdout.writeln('  report   Show mentor capacity and recent decisions.');
  stdout.writeln('  gap      Show scholars with low-scoring or no matches.');
  stdout.writeln('  coverage Show tag gaps and regional capacity balance.');
  stdout.writeln('  scorecard Show top mentor options per scholar.');
  stdout.writeln('');
  stdout.writeln('Environment variables:');
  stdout.writeln('  PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD');
  stdout.writeln('  Optional: PGSCHEMA (default mentor_matchmap), PGSSLMODE');
}
