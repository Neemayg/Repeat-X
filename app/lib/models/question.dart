import 'dart:math' as math;

/// What kind of document a question came from. The weight is how much one
/// sighting counts when ranking.
enum SourceKind {
  endSem(1.0, 'ES'),
  mst1(0.9, 'MST-1'),
  mst2(0.9, 'MST-2'),
  teacherImp(0.8, 'IMP'),
  questionBank(0.5, 'QB'),
  other(0.6, 'Other');

  const SourceKind(this.weight, this.short);
  final double weight;
  final String short;
}

enum QuestionType { theory, numerical, mixed, mcq, fillBlank, match }

/// One question exactly as it appeared in one paper.
class Question {
  const Question({
    required this.id,
    required this.paperId,
    required this.source,
    required this.number,
    required this.marks,
    required this.text,
    this.year,
    this.unit,
    this.topic,
    this.type = QuestionType.theory,
    this.split = const [],
    this.groupKey,
  });

  final String id;

  /// Unique paper this came from (duplicate photos of one paper share it).
  final String paperId;
  final SourceKind source;

  /// As printed: "3", "11a", "B2".
  final String number;
  final int marks;
  final String text;
  final int? year;
  final int? unit;
  final String? topic;
  final QuestionType type;

  /// Sub-part marks, e.g. [8, 8] or [10, 6]. Empty when not split.
  final List<int> split;

  /// Cluster key: questions with the same key are "the same question".
  final String? groupKey;

  /// "ES ’24", "MST-1 ’23", "QB".
  String get chip {
    if (year == null) return source.short;
    final yy = (year! % 100).toString().padLeft(2, '0');
    return '${source.short} ’$yy';
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'paperId': paperId,
        'source': source.name,
        'number': number,
        'marks': marks,
        'text': text,
        'year': year,
        'unit': unit,
        'topic': topic,
        'type': type.name,
        'split': split,
        'groupKey': groupKey,
      };

  factory Question.fromJson(Map<String, Object?> j) => Question(
        id: j['id'] as String,
        paperId: j['paperId'] as String,
        source: SourceKind.values.byName(j['source'] as String),
        number: j['number'] as String,
        marks: j['marks'] as int,
        text: j['text'] as String,
        year: j['year'] as int?,
        unit: j['unit'] as int?,
        topic: j['topic'] as String?,
        type: QuestionType.values.byName(j['type'] as String? ?? 'theory'),
        split: ((j['split'] as List?) ?? const []).cast<int>(),
        groupKey: j['groupKey'] as String?,
      );
}

/// Questions that are the same question asked again (possibly reworded).
class QuestionCluster {
  QuestionCluster({required this.key, required List<Question> variants})
      : variants = List.unmodifiable(
            [...variants]..sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0)));

  final String key;
  final List<Question> variants;

  /// Distinct papers it appeared in — the honest repeat count.
  int get paperCount => variants.map((q) => q.paperId).toSet().length;

  /// Most recent, then longest wording.
  String get canonicalText {
    final sorted = [...variants]..sort((a, b) {
        final byYear = (b.year ?? 0).compareTo(a.year ?? 0);
        return byYear != 0 ? byYear : b.text.length.compareTo(a.text.length);
      });
    return sorted.first.text;
  }

  int? get unit {
    final counts = <int, int>{};
    for (final q in variants) {
      if (q.unit != null) counts[q.unit!] = (counts[q.unit!] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  String? get topic => variants.map((q) => q.topic).whereType<String>().firstOrNull;

  QuestionType get type => variants.first.type;

  /// How often each mark value was carried: {16: 2, 5: 1}.
  Map<int, int> get marksHistogram {
    final m = <int, int>{};
    for (final q in variants) {
      m[q.marks] = (m[q.marks] ?? 0) + 1;
    }
    return m;
  }

  int get typicalMarks =>
      marksHistogram.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  /// Compact provenance chips, one per paper, newest first.
  List<String> get chips {
    final seen = <String>{};
    final out = <String>[];
    for (final q in variants) {
      if (seen.add(q.paperId)) out.add(q.chip);
    }
    return out;
  }

  /// Ranking score: each distinct paper counts once, weighted by source and
  /// recency. Unknown years are treated as six years old.
  double score(int currentYear) {
    final bestPerPaper = <String, double>{};
    for (final q in variants) {
      final age = q.year == null ? 6.0 : math.max(0, currentYear - q.year!).toDouble();
      final s = q.source.weight * (0.4 + 0.6 * math.exp(-age / 5.0));
      final prev = bestPerPaper[q.paperId];
      if (prev == null || s > prev) bestPerPaper[q.paperId] = s;
    }
    return bestPerPaper.values.fold(0.0, (a, b) => a + b);
  }
}

/// Groups questions by [Question.groupKey]. Questions without a key stand alone.
List<QuestionCluster> clusterByKey(Iterable<Question> questions) {
  final groups = <String, List<Question>>{};
  for (final q in questions) {
    final key = q.groupKey ?? 'solo:${q.id}';
    groups.putIfAbsent(key, () => []).add(q);
  }
  return [
    for (final e in groups.entries) QuestionCluster(key: e.key, variants: e.value),
  ];
}
