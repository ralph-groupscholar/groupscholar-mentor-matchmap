import 'models.dart';

class MatchEngine {
  List<MatchSuggestion> suggest({
    required List<Mentor> mentors,
    required List<Scholar> scholars,
    Map<int, int> mentorDecisionCounts = const {},
  }) {
    final plan = buildPlan(
      mentors: mentors,
      scholars: scholars,
      mentorDecisionCounts: mentorDecisionCounts,
    );
    return plan.suggestions;
  }

  MatchPlan buildPlan({
    required List<Mentor> mentors,
    required List<Scholar> scholars,
    Map<int, int> mentorDecisionCounts = const {},
  }) {
    final suggestions = <MatchSuggestion>[];
    final unassigned = <Scholar>[];
    final remainingCapacity = <int, int>{};

    for (final mentor in mentors) {
      final used = mentorDecisionCounts[mentor.id] ?? 0;
      remainingCapacity[mentor.id] = mentor.capacity - used;
    }

    for (final scholar in scholars) {
      final ranked = rankMentorsForScholar(
        mentors: mentors,
        scholar: scholar,
        mentorDecisionCounts: mentorDecisionCounts,
        remainingCapacityOverrides: remainingCapacity,
      );

      if (ranked.isEmpty) {
        unassigned.add(scholar);
        continue;
      }

      final top = ranked.first;
      suggestions.add(top);
      final currentRemaining = remainingCapacity[top.mentor.id] ?? 0;
      remainingCapacity[top.mentor.id] = currentRemaining - 1;
    }

    return MatchPlan(
      suggestions: suggestions,
      unassignedScholars: unassigned,
    );
  }

  List<MatchSuggestion> rankMentorsForScholar({
    required List<Mentor> mentors,
    required Scholar scholar,
    Map<int, int> mentorDecisionCounts = const {},
    Map<int, int>? remainingCapacityOverrides,
  }) {
    final availableMentors = mentors.where((mentor) {
      final remaining = remainingCapacityOverrides?[mentor.id] ??
          (mentor.capacity - (mentorDecisionCounts[mentor.id] ?? 0));
      return remaining > 0;
    }).toList();

    final ranked = availableMentors
        .map((mentor) {
          final remaining = remainingCapacityOverrides?[mentor.id] ??
              (mentor.capacity - (mentorDecisionCounts[mentor.id] ?? 0));
          return _score(mentor, scholar, remaining);
        })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return ranked;
  }

  MatchSuggestion _score(Mentor mentor, Scholar scholar, int remainingCapacity) {
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

    if (remainingCapacity > 0) {
      score += 1;
      reasons.add('Mentor capacity available ($remainingCapacity slots)');
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
