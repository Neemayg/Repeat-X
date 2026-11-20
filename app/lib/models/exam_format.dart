/// Exam formats are data, not code. These presets are SRM Delhi-NCR's current
/// formats as confirmed by Neemay (Nov 2026); every field stays editable, and
/// old papers carry whatever format their own header printed.
library;

enum ChoiceKind { none, internalOr, anyOf }

/// How slots in a section are assigned to units.
enum UnitPlan {
  /// Round-robin over the format's units (End Sem Part A).
  spread,

  /// Slot i belongs to unit i (End Sem Q11 = Unit 1 … Q15 = Unit 5).
  onePerUnit,

  /// Any question from the format's units, best first (MSTs).
  pooled,
}

class SectionRule {
  const SectionRule({
    required this.name,
    required this.instruction,
    required this.printed,
    required this.marks,
    this.choice = ChoiceKind.none,
    this.answer,
    this.unitPlan = UnitPlan.spread,
  });

  final String name;
  final String instruction;

  /// Number of numbered slots printed (Q11–Q15 is 5 even though 10 questions appear).
  final int printed;
  final int marks;
  final ChoiceKind choice;

  /// For [ChoiceKind.anyOf]: how many of [printed] the candidate answers.
  final int? answer;
  final UnitPlan unitPlan;

  int get alternativesPerSlot => choice == ChoiceKind.internalOr ? 2 : 1;

  int get questionsNeeded => printed * alternativesPerSlot;

  int get attemptableMarks =>
      choice == ChoiceKind.anyOf ? (answer ?? printed) * marks : printed * marks;

  Map<String, Object?> toJson() => {
        'name': name,
        'instruction': instruction,
        'printed': printed,
        'marks': marks,
        'choice': choice.name,
        'answer': answer,
        'unitPlan': unitPlan.name,
      };

  factory SectionRule.fromJson(Map<String, Object?> j) => SectionRule(
        name: j['name'] as String,
        instruction: j['instruction'] as String? ?? '',
        printed: j['printed'] as int,
        marks: j['marks'] as int,
        choice: ChoiceKind.values.byName(j['choice'] as String? ?? 'none'),
        answer: j['answer'] as int?,
        unitPlan: UnitPlan.values.byName(j['unitPlan'] as String? ?? 'spread'),
      );
}

class ExamFormat {
  const ExamFormat({
    required this.id,
    required this.name,
    required this.units,
    required this.durationMinutes,
    required this.sections,
  });

  final String id;
  final String name;
  final List<int> units;
  final int durationMinutes;
  final List<SectionRule> sections;

  int get totalMarks => sections.fold(0, (sum, s) => sum + s.attemptableMarks);

  int get questionsNeeded => sections.fold(0, (sum, s) => sum + s.questionsNeeded);

  static ExamFormat mst({required int number, required List<int> units}) => ExamFormat(
        id: 'mst$number',
        name: 'MST-$number',
        units: units,
        durationMinutes: 90,
        sections: const [
          SectionRule(
            name: 'Part A',
            instruction: 'Answer ALL questions.',
            printed: 5,
            marks: 2,
            unitPlan: UnitPlan.spread,
          ),
          SectionRule(
            name: 'Part B',
            instruction: 'Answer any FOUR of the following five questions.',
            printed: 5,
            marks: 5,
            choice: ChoiceKind.anyOf,
            answer: 4,
            unitPlan: UnitPlan.pooled,
          ),
        ],
      );

  static final ExamFormat mst1 = mst(number: 1, units: const [1, 2]);
  static final ExamFormat mst2 = mst(number: 2, units: const [3, 4]);

  static const ExamFormat endSem = ExamFormat(
    id: 'endsem',
    name: 'End Semester',
    units: [1, 2, 3, 4, 5],
    durationMinutes: 180,
    sections: [
      SectionRule(
        name: 'Part A',
        instruction: 'Answer ALL questions.',
        printed: 10,
        marks: 2,
        unitPlan: UnitPlan.spread,
      ),
      SectionRule(
        name: 'Part B',
        instruction: 'Answer ALL questions, choosing either (a) or (b).',
        printed: 5,
        marks: 16,
        choice: ChoiceKind.internalOr,
        unitPlan: UnitPlan.onePerUnit,
      ),
    ],
  );

  static List<ExamFormat> get presets => [mst1, mst2, endSem];

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'units': units,
        'durationMinutes': durationMinutes,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory ExamFormat.fromJson(Map<String, Object?> j) => ExamFormat(
        id: j['id'] as String,
        name: j['name'] as String,
        units: (j['units'] as List).cast<int>(),
        durationMinutes: j['durationMinutes'] as int,
        sections: (j['sections'] as List)
            .map((s) => SectionRule.fromJson((s as Map).cast<String, Object?>()))
            .toList(),
      );
}
