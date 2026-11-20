import 'dart:math' as math;

import '../models/exam_format.dart';
import '../models/question.dart';

class PaperAlternative {
  const PaperAlternative({
    required this.letter,
    required this.marks,
    required this.unit,
    this.cluster,
  });

  /// "a" / "b" for internal choice, null otherwise.
  final String? letter;
  final int marks;
  final int? unit;

  /// The evidence behind this question; null means the slot needs an
  /// AI-drafted question (or more papers).
  final QuestionCluster? cluster;

  bool get needsDraft => cluster == null;
}

class PaperSlot {
  const PaperSlot({required this.number, required this.alternatives});
  final int number;
  final List<PaperAlternative> alternatives;
}

class GeneratedSection {
  const GeneratedSection({required this.rule, required this.slots});
  final SectionRule rule;
  final List<PaperSlot> slots;
}

class GeneratedPaper {
  const GeneratedPaper({
    required this.format,
    required this.seed,
    required this.sections,
    required this.warnings,
  });
  final ExamFormat format;
  final int seed;
  final List<GeneratedSection> sections;
  final List<String> warnings;

  Iterable<PaperAlternative> get alternatives =>
      sections.expand((s) => s.slots).expand((s) => s.alternatives);
}

/// Builds a mock paper from ranked clusters, obeying the format's rules.
///
/// Selection is weighted-random among the strongest candidates, so each seed
/// gives a different but evidence-based paper; the same seed reproduces it.
class PaperGenerator {
  PaperGenerator({
    required this.currentYear,
    this.marksTolerance = 3.0,
    this.exactMarksBonus = 1.6,
    this.candidatePool = 4,
  });

  final int currentYear;

  /// A question usually worth m may fill a slot worth up to m × tolerance
  /// (3.0: a 2-marker can fill a 5-mark slot, a 5-marker cannot fill a 16).
  final double marksTolerance;
  final double exactMarksBonus;

  /// How many top candidates the random draw chooses between.
  final int candidatePool;

  GeneratedPaper generate({
    required List<QuestionCluster> clusters,
    required ExamFormat format,
    int seed = 0,
  }) {
    final random = math.Random(seed);
    final used = <String>{};
    final warnings = <String>[];
    final sections = <GeneratedSection>[];
    var slotNumber = 1;
    final allowed = format.units.toSet();

    for (final rule in format.sections) {
      final slots = <PaperSlot>[];
      for (var i = 0; i < rule.printed; i++) {
        final int? targetUnit = switch (rule.unitPlan) {
          UnitPlan.onePerUnit => i < format.units.length ? format.units[i] : null,
          UnitPlan.spread => format.units[i % format.units.length],
          UnitPlan.pooled => null,
        };
        final alternatives = <PaperAlternative>[];
        for (var k = 0; k < rule.alternativesPerSlot; k++) {
          final letter = rule.alternativesPerSlot > 1 ? (k == 0 ? 'a' : 'b') : null;
          final picked = _pick(
            clusters: clusters,
            marks: rule.marks,
            allowedUnits: allowed,
            targetUnit: targetUnit,
            strictUnit: rule.unitPlan == UnitPlan.onePerUnit,
            used: used,
            random: random,
          );
          if (picked != null) used.add(picked.key);
          if (picked == null) {
            warnings.add('${rule.name} Q$slotNumber${letter ?? ''}: no unused '
                '${rule.marks}-mark question for '
                '${targetUnit == null ? 'these units' : 'Unit $targetUnit'}.');
          }
          alternatives.add(PaperAlternative(
            letter: letter,
            marks: rule.marks,
            unit: picked?.unit ?? targetUnit,
            cluster: picked,
          ));
        }
        slots.add(PaperSlot(number: slotNumber++, alternatives: alternatives));
      }
      sections.add(GeneratedSection(rule: rule, slots: slots));
    }
    return GeneratedPaper(format: format, seed: seed, sections: sections, warnings: warnings);
  }

  QuestionCluster? _pick({
    required List<QuestionCluster> clusters,
    required int marks,
    required Set<int> allowedUnits,
    required int? targetUnit,
    required bool strictUnit,
    required Set<String> used,
    required math.Random random,
  }) {
    final available = clusters
        .where((c) => !used.contains(c.key))
        .where((c) => c.unit != null && allowedUnits.contains(c.unit))
        .where((c) => _plausible(c, marks))
        .toList();

    List<QuestionCluster> tier = available;
    if (targetUnit != null) {
      final inUnit = available.where((c) => c.unit == targetUnit).toList();
      // End Sem Part B: slot n must come from unit n — never borrow.
      if (strictUnit || inUnit.isNotEmpty) tier = inUnit;
    }
    if (tier.isEmpty) return null;

    tier.sort((a, b) => _rank(b, marks).compareTo(_rank(a, marks)));
    final pool = tier.take(candidatePool).toList();
    final weights = pool.map((c) => _rank(c, marks)).toList();
    final total = weights.fold(0.0, (a, b) => a + b);
    var r = random.nextDouble() * total;
    for (var i = 0; i < pool.length; i++) {
      r -= weights[i];
      if (r <= 0) return pool[i];
    }
    return pool.last;
  }

  bool _plausible(QuestionCluster c, int marks) {
    if (c.marksHistogram.containsKey(marks)) return true;
    final t = c.typicalMarks;
    final ratio = math.max(t, marks) / math.max(1, math.min(t, marks));
    return ratio <= marksTolerance;
  }

  double _rank(QuestionCluster c, int marks) {
    var s = c.score(currentYear);
    if (c.marksHistogram.containsKey(marks)) {
      s *= exactMarksBonus;
    } else {
      final distance = (c.typicalMarks - marks).abs() / math.max(marks, 1);
      s *= math.max(0.35, 1.0 - 0.6 * distance);
    }
    return s;
  }
}
