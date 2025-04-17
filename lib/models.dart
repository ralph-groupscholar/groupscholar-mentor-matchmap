class Mentor {
  Mentor({
    required this.id,
    required this.name,
    required this.email,
    required this.region,
    required this.capacity,
    required this.tags,
  });

  final int id;
  final String name;
  final String email;
  final String region;
  final int capacity;
  final List<String> tags;
}

class Scholar {
  Scholar({
    required this.id,
    required this.name,
    required this.email,
    required this.region,
    required this.tags,
  });

  final int id;
  final String name;
  final String email;
  final String region;
  final List<String> tags;
}

class MatchSuggestion {
  MatchSuggestion({
    required this.mentor,
    required this.scholar,
    required this.score,
    required this.reasons,
  });

  final Mentor mentor;
  final Scholar scholar;
  final double score;
  final List<String> reasons;
}

class MatchPlan {
  MatchPlan({
    required this.suggestions,
    required this.unassignedScholars,
  });

  final List<MatchSuggestion> suggestions;
  final List<Scholar> unassignedScholars;
}

class ScholarMatchRank {
  ScholarMatchRank({
    required this.scholar,
    required this.matches,
  });

  final Scholar scholar;
  final List<MatchSuggestion> matches;
}

class MentorUtilization {
  MentorUtilization({
    required this.mentor,
    required this.matchedCount,
    required this.remainingCapacity,
  });

  final Mentor mentor;
  final int matchedCount;
  final int remainingCapacity;
}

class DecisionSummary {
  DecisionSummary({
    required this.mentorName,
    required this.scholarName,
    required this.score,
    required this.decidedAt,
  });

  final String mentorName;
  final String scholarName;
  final double score;
  final DateTime decidedAt;
}
