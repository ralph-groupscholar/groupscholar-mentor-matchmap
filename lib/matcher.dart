import 'models.dart';

class MatchEngine {
  List<MatchSuggestion> suggest({
    required List<Mentor> mentors,
    required List<Scholar> scholars,
  }) {
    final suggestions = <MatchSuggestion>[];

    for (final scholar in scholars) {
      final ranked = mentors
          .map((mentor) => _score(mentor, scholar))
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      if (ranked.isNotEmpty) {
        suggestions.add(ranked.first);
      }
    }

    return suggestions;
  }

  MatchSuggestion _score(Mentor mentor, Scholar scholar) {
    double score = 0;
    final reasons = <String>[];

    final sharedTags = mentor.tags.toSet().intersection(scholar.tags.toSet());
    if (sharedTags.isNotEmpty) {
      score += sharedTags.length * 3;
      reasons.add('Shared focus: ${sharedTags.join(', ')}');
    }

    if (mentor.region == scholar.region) {
      score += 2;
      reasons.add('Same region (${mentor.region})');
    }

    if (mentor.capacity > 0) {
      score += 1;
      reasons.add('Mentor capacity available');
    }

    if (reasons.isEmpty) {
      reasons.add('General availability match');
    }

    return MatchSuggestion(
      mentor: mentor,
      scholar: scholar,
      score: score,
      reasons: reasons,
    );
  }
}
