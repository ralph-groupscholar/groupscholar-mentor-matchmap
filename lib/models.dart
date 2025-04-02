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
