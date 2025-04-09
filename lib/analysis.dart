import 'matcher.dart';
import 'models.dart';

class TagGap {
  TagGap({required this.tag, required this.count});

  final String tag;
  final int count;
}

class RegionCoverage {
  RegionCoverage({
    required this.region,
    required this.scholarDemand,
    required this.remainingCapacity,
  }) : gap = scholarDemand - remainingCapacity;

  final String region;
  final int scholarDemand;
  final int remainingCapacity;
  final int gap;
}

class CoverageReport {
  CoverageReport({
    required this.missingMentorTags,
    required this.unusedMentorTags,
    required this.regionCoverage,
  });

  final List<TagGap> missingMentorTags;
  final List<TagGap> unusedMentorTags;
  final List<RegionCoverage> regionCoverage;
}

class ScholarScorecard {
  ScholarScorecard({
    required this.scholar,
    required this.rankedSuggestions,
    required this.topScore,
    required this.belowThreshold,
  });

  final Scholar scholar;
  final List<MatchSuggestion> rankedSuggestions;
  final double topScore;
  final bool belowThreshold;
}

CoverageReport buildCoverageReport({
  required List<Mentor> mentors,
  required List<Scholar> scholars,
  Map<int, int> mentorDecisionCounts = const {},
}) {
  final mentorTagCounts = <String, int>{};
  for (final mentor in mentors) {
    for (final tag in mentor.tags) {
      mentorTagCounts[tag] = (mentorTagCounts[tag] ?? 0) + 1;
    }
  }

  final scholarTagCounts = <String, int>{};
  for (final scholar in scholars) {
    for (final tag in scholar.tags) {
      scholarTagCounts[tag] = (scholarTagCounts[tag] ?? 0) + 1;
    }
  }

  final mentorTagSet = mentorTagCounts.keys.toSet();
  final scholarTagSet = scholarTagCounts.keys.toSet();

  final missingMentorTags = scholarTagCounts.entries
      .where((entry) => !mentorTagSet.contains(entry.key))
      .map((entry) => TagGap(tag: entry.key, count: entry.value))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  final unusedMentorTags = mentorTagCounts.entries
      .where((entry) => !scholarTagSet.contains(entry.key))
      .map((entry) => TagGap(tag: entry.key, count: entry.value))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  final regionDemand = <String, int>{};
  for (final scholar in scholars) {
    regionDemand[scholar.region] = (regionDemand[scholar.region] ?? 0) + 1;
  }

  final regionCapacity = <String, int>{};
  for (final mentor in mentors) {
    final used = mentorDecisionCounts[mentor.id] ?? 0;
    final remaining = (mentor.capacity - used).clamp(0, mentor.capacity);
    regionCapacity[mentor.region] = (regionCapacity[mentor.region] ?? 0) + remaining;
  }

  final regions = <String>{...regionDemand.keys, ...regionCapacity.keys};
  final coverage = regions
      .map(
        (region) => RegionCoverage(
          region: region,
          scholarDemand: regionDemand[region] ?? 0,
          remainingCapacity: regionCapacity[region] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) {
      final gapCompare = b.gap.compareTo(a.gap);
      if (gapCompare != 0) {
        return gapCompare;
      }
      return a.region.compareTo(b.region);
    });

  return CoverageReport(
    missingMentorTags: missingMentorTags,
    unusedMentorTags: unusedMentorTags,
    regionCoverage: coverage,
  );
}

List<ScholarScorecard> buildScholarScorecards({
  required List<Mentor> mentors,
  required List<Scholar> scholars,
  Map<int, int> mentorDecisionCounts = const {},
  int topN = 3,
  double minScore = 3,
}) {
  final safeTopN = topN <= 0 ? 1 : topN;
  final engine = MatchEngine();

  return scholars.map((scholar) {
    final ranked = engine.rankMentorsForScholar(
      mentors: mentors,
      scholar: scholar,
      mentorDecisionCounts: mentorDecisionCounts,
    );
    final topScore = ranked.isEmpty ? 0.0 : ranked.first.score;
    return ScholarScorecard(
      scholar: scholar,
      rankedSuggestions: ranked.take(safeTopN).toList(),
      topScore: topScore,
      belowThreshold: topScore < minScore,
    );
  }).toList();
}
