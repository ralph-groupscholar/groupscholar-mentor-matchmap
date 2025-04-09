import 'package:groupscholar_mentor_matchmap/analysis.dart';
import 'package:groupscholar_mentor_matchmap/matcher.dart';
import 'package:groupscholar_mentor_matchmap/models.dart';
import 'package:test/test.dart';

void main() {
  test('match engine prioritizes shared tags and region', () {
    final mentors = [
      Mentor(
        id: 1,
        name: 'Mentor A',
        email: 'a@mentor.org',
        region: 'West',
        capacity: 2,
        tags: ['stem', 'internships'],
      ),
      Mentor(
        id: 2,
        name: 'Mentor B',
        email: 'b@mentor.org',
        region: 'South',
        capacity: 1,
        tags: ['arts'],
      ),
    ];

    final scholars = [
      Scholar(
        id: 10,
        name: 'Scholar X',
        email: 'x@scholar.org',
        region: 'West',
        tags: ['stem', 'research'],
      ),
    ];

    final engine = MatchEngine();
    final suggestions = engine.suggest(mentors: mentors, scholars: scholars);

    expect(suggestions, hasLength(1));
    expect(suggestions.first.mentor.id, 1);
    expect(suggestions.first.score, greaterThan(0));
  });

  test('match engine skips mentors at capacity', () {
    final mentors = [
      Mentor(
        id: 1,
        name: 'Mentor A',
        email: 'a@mentor.org',
        region: 'West',
        capacity: 1,
        tags: ['stem'],
      ),
      Mentor(
        id: 2,
        name: 'Mentor B',
        email: 'b@mentor.org',
        region: 'West',
        capacity: 2,
        tags: ['stem'],
      ),
    ];

    final scholars = [
      Scholar(
        id: 10,
        name: 'Scholar X',
        email: 'x@scholar.org',
        region: 'West',
        tags: ['stem'],
      ),
    ];

    final engine = MatchEngine();
    final suggestions = engine.suggest(
      mentors: mentors,
      scholars: scholars,
      mentorDecisionCounts: {1: 1},
    );

    expect(suggestions, hasLength(1));
    expect(suggestions.first.mentor.id, 2);
  });

  test('rankMentorsForScholar returns sorted suggestions', () {
    final mentors = [
      Mentor(
        id: 1,
        name: 'Mentor A',
        email: 'a@mentor.org',
        region: 'West',
        capacity: 1,
        tags: ['stem', 'internships'],
      ),
      Mentor(
        id: 2,
        name: 'Mentor B',
        email: 'b@mentor.org',
        region: 'South',
        capacity: 1,
        tags: ['arts'],
      ),
    ];

    final scholar = Scholar(
      id: 10,
      name: 'Scholar X',
      email: 'x@scholar.org',
      region: 'West',
      tags: ['stem', 'research'],
    );

    final engine = MatchEngine();
    final ranked = engine.rankMentorsForScholar(
      mentors: mentors,
      scholar: scholar,
    );

    expect(ranked, hasLength(2));
    expect(ranked.first.mentor.id, 1);
    expect(ranked.first.score, greaterThan(ranked.last.score));
  });

  test('suggest respects batch capacity across multiple scholars', () {
    final mentors = [
      Mentor(
        id: 1,
        name: 'Mentor A',
        email: 'a@mentor.org',
        region: 'West',
        capacity: 1,
        tags: ['stem', 'internships'],
      ),
      Mentor(
        id: 2,
        name: 'Mentor B',
        email: 'b@mentor.org',
        region: 'West',
        capacity: 1,
        tags: ['stem'],
      ),
    ];

    final scholars = [
      Scholar(
        id: 10,
        name: 'Scholar X',
        email: 'x@scholar.org',
        region: 'West',
        tags: ['stem', 'research'],
      ),
      Scholar(
        id: 11,
        name: 'Scholar Y',
        email: 'y@scholar.org',
        region: 'West',
        tags: ['stem'],
      ),
    ];

    final engine = MatchEngine();
    final suggestions = engine.suggest(
      mentors: mentors,
      scholars: scholars,
    );

    expect(suggestions, hasLength(2));
    expect(suggestions.first.mentor.id, 1);
    expect(suggestions.last.mentor.id, 2);
  });

  test('coverage report highlights missing tags and region gaps', () {
    final mentors = [
      Mentor(
        id: 1,
        name: 'Mentor A',
        email: 'a@mentor.org',
        region: 'West',
        capacity: 1,
        tags: ['stem'],
      ),
    ];

    final scholars = [
      Scholar(
        id: 10,
        name: 'Scholar X',
        email: 'x@scholar.org',
        region: 'West',
        tags: ['stem', 'arts'],
      ),
      Scholar(
        id: 11,
        name: 'Scholar Y',
        email: 'y@scholar.org',
        region: 'South',
        tags: ['health'],
      ),
    ];

    final report = buildCoverageReport(
      mentors: mentors,
      scholars: scholars,
      mentorDecisionCounts: {1: 1},
    );

    expect(report.missingMentorTags.map((gap) => gap.tag), contains('arts'));
    expect(report.missingMentorTags.map((gap) => gap.tag), contains('health'));
    final west = report.regionCoverage.firstWhere((entry) => entry.region == 'West');
    expect(west.remainingCapacity, 0);
    final south = report.regionCoverage.firstWhere((entry) => entry.region == 'South');
    expect(south.scholarDemand, 1);
    expect(south.remainingCapacity, 0);
  });
}
