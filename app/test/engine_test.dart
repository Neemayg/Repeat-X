import 'package:flutter_test/flutter_test.dart';
import 'package:repeatx/engine/paper_generator.dart';
import 'package:repeatx/models/exam_format.dart';
import 'package:repeatx/models/question.dart';

import 'ground_truth.dart';

void main() {
  group('Exam formats (confirmed SRM rules)', () {
    test('MST-1 and MST-2: 5×2 + any 4 of 5×5 = 30 marks, 90 min', () {
      for (final f in [ExamFormat.mst1, ExamFormat.mst2]) {
        expect(f.totalMarks, 30);
        expect(f.durationMinutes, 90);
        expect(f.questionsNeeded, 10);
      }
      expect(ExamFormat.mst1.units, [1, 2]);
      expect(ExamFormat.mst2.units, [3, 4]);
    });

    test('End Sem: 10×2 + 5×16 with (a)/(b) = 100 marks, 20 questions printed', () {
      expect(ExamFormat.endSem.totalMarks, 100);
      expect(ExamFormat.endSem.durationMinutes, 180);
      expect(ExamFormat.endSem.questionsNeeded, 20);
    });

    test('formats survive a JSON round trip', () {
      final back = ExamFormat.fromJson(ExamFormat.endSem.toJson());
      expect(back.totalMarks, 100);
      expect(back.sections[1].choice, ChoiceKind.internalOr);
    });
  });

  group('Ranking on real CAO papers', () {
    final clusters = clusterByKey(loadCaoGroundTruth());

    test('addressing modes is asked in 4 distinct papers and ranks first', () {
      final addressing = clusters.firstWhere((c) => c.key == 'addressing_modes');
      expect(addressing.paperCount, 4);
      final ranked = [...clusters]..sort((a, b) => b.score(2026).compareTo(a.score(2026)));
      expect(ranked.first.key, 'addressing_modes');
    });

    test('a question repeated inside one paper counts that paper once', () {
      final perf = clusters.firstWhere((c) => c.key == 'cpu_performance_equation');
      expect(perf.variants.length, 2);
      expect(perf.paperCount, 1);
    });

    test('provenance chips are one per paper', () {
      final ir = clusters.firstWhere((c) => c.key == 'instruction_register');
      expect(ir.chips, ['ES ’24', 'ES ’23']);
    });
  });

  group('Paper generation on real CAO papers', () {
    final clusters = clusterByKey(loadCaoGroundTruth());
    final generator = PaperGenerator(currentYear: 2026);

    test('End Sem Part B: Qn draws (a) and (b) from Unit n, no warnings', () {
      for (var seed = 0; seed < 20; seed++) {
        final paper = generator.generate(clusters: clusters, format: ExamFormat.endSem, seed: seed);
        final partB = paper.sections[1];
        expect(partB.slots.length, 5);
        for (var i = 0; i < 5; i++) {
          final slot = partB.slots[i];
          expect(slot.number, 11 + i);
          expect(slot.alternatives.map((a) => a.letter), ['a', 'b']);
          for (final alt in slot.alternatives) {
            expect(alt.needsDraft, isFalse, reason: 'seed $seed Q${slot.number}');
            expect(alt.unit, i + 1);
          }
        }
        expect(paper.warnings, isEmpty);
      }
    });

    test('no question appears twice in one paper', () {
      for (var seed = 0; seed < 20; seed++) {
        final paper = generator.generate(clusters: clusters, format: ExamFormat.endSem, seed: seed);
        final keys = paper.alternatives.where((a) => !a.needsDraft).map((a) => a.cluster!.key).toList();
        expect(keys.toSet().length, keys.length);
      }
    });

    test('short questions (2 or 5 marks only) never fill a 16-mark slot', () {
      for (var seed = 0; seed < 20; seed++) {
        final paper = generator.generate(clusters: clusters, format: ExamFormat.endSem, seed: seed);
        for (final alt in paper.sections[1].slots.expand((s) => s.alternatives)) {
          final c = alt.cluster!;
          expect(c.marksHistogram.containsKey(16) || c.typicalMarks * 3 >= 16, isTrue,
              reason: 'seed $seed: ${c.canonicalText}');
        }
      }
    });

    test('MST-1 stays inside Units 1–2 and MST-2 inside Units 3–4', () {
      for (var seed = 0; seed < 10; seed++) {
        final mst1 = generator.generate(clusters: clusters, format: ExamFormat.mst1, seed: seed);
        final mst2 = generator.generate(clusters: clusters, format: ExamFormat.mst2, seed: seed);
        for (final a in mst1.alternatives.where((a) => !a.needsDraft)) {
          expect([1, 2], contains(a.cluster!.unit));
        }
        for (final a in mst2.alternatives.where((a) => !a.needsDraft)) {
          expect([3, 4], contains(a.cluster!.unit));
        }
      }
    });

    test('same seed reproduces a paper; different seeds vary it', () {
      String fingerprint(GeneratedPaper p) =>
          p.alternatives.map((a) => a.cluster?.key ?? '-').join('|');
      final a = generator.generate(clusters: clusters, format: ExamFormat.endSem, seed: 7);
      final b = generator.generate(clusters: clusters, format: ExamFormat.endSem, seed: 7);
      expect(fingerprint(a), fingerprint(b));
      final variants = {
        for (var s = 0; s < 10; s++)
          fingerprint(generator.generate(clusters: clusters, format: ExamFormat.endSem, seed: s)),
      };
      expect(variants.length, greaterThan(1));
    });
  });
}
