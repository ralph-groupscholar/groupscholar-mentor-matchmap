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
}
