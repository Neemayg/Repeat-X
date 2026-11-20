import 'dart:convert';
import 'dart:io';

import 'package:repeatx/models/question.dart';

/// Loads the hand-labelled CAO papers from `eval/cao_ground_truth.json` as
/// app [Question]s, using the labelled repeat groups as cluster keys.
List<Question> loadCaoGroundTruth() {
  final file = File('../eval/cao_ground_truth.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final out = <Question>[];
  for (final paper in (data['papers'] as List).cast<Map<String, dynamic>>()) {
    final source = switch (paper['exam'] as String) {
      'END_SEM' => SourceKind.endSem,
      'MST1' => SourceKind.mst1,
      'MST2' => SourceKind.mst2,
      _ => SourceKind.other,
    };
    for (final q in (paper['questions'] as List).cast<Map<String, dynamic>>()) {
      out.add(Question(
        id: '${paper['id']}/${q['n']}',
        paperId: paper['id'] as String,
        source: source,
        number: q['n'] as String,
        marks: q['m'] as int,
        text: q['text'] as String,
        year: paper['year'] as int?,
        unit: q['u'] as int?,
        topic: q['topic'] as String?,
        type: _type(q['type'] as String),
        split: ((q['split'] as List?) ?? const []).cast<int>(),
        groupKey: q['g'] as String?,
      ));
    }
  }
  return out;
}

QuestionType _type(String t) => switch (t) {
      'numerical' => QuestionType.numerical,
      'mixed' => QuestionType.mixed,
      'mcq' => QuestionType.mcq,
      'match' => QuestionType.match,
      'fillBlank' => QuestionType.fillBlank,
      _ => QuestionType.theory,
    };
