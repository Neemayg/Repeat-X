import 'package:flutter/material.dart';

import '../models/exam_format.dart';
import '../models/subject.dart';
import '../theme.dart';

/// Subject overview. Phase 1 shows the structure; files, analysis and
/// generation fill in over Phases 2–5 (see the v2 spec).
class SubjectHomeScreen extends StatelessWidget {
  const SubjectHomeScreen({super.key, required this.subject});
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: RX.paperInk,
            unselectedLabelColor: RX.fg2,
            indicator: BoxDecoration(
              color: RX.paper,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: RX.line,
            tabs: [Tab(text: 'Overview'), Tab(text: 'Generate'), Tab(text: 'Files')],
          ),
        ),
        body: TabBarView(children: [
          _Overview(subject: subject),
          const _Formats(),
          const _Placeholder(
            title: 'Add material',
            body: 'Scan pages or pick PDFs, slides, Word files and photos. '
                'Coming in Phase 2: reading files with your Gemini key.',
          ),
        ]),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.subject});
  final Subject subject;
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(22), children: [
      Text(subject.name, style: RX.serif(27)),
      const SizedBox(height: 16),
      const _Placeholder(
        title: 'No papers yet',
        body: 'Once papers are read, each unit shows its most-asked topics and the 2 / 5 / 16-mark mix.',
      ),
    ]);
  }
}

class _Formats extends StatelessWidget {
  const _Formats();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        for (final f in ExamFormat.presets)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: RX.surface,
              border: Border.all(color: RX.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Units ${f.units.first}–${f.units.last} · ${f.totalMarks} marks · '
                '${f.durationMinutes % 60 == 0 ? '${f.durationMinutes ~/ 60} h' : '${f.durationMinutes} min'}',
                style: const TextStyle(fontSize: 12.5, color: RX.fg2),
              ),
              const SizedBox(height: 8),
              for (final s in f.sections)
                Text('${s.name} · ${s.printed} × ${s.marks}'
                    '${s.choice == ChoiceKind.anyOf ? ', any ${s.answer}' : ''}'
                    '${s.choice == ChoiceKind.internalOr ? ', (a) or (b)' : ''}'
                    ' = ${s.attemptableMarks}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFFC6CCDA))),
            ]),
          ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RX.surface,
        border: Border.all(color: RX.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: RX.serif(19)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(fontSize: 13.5, height: 1.5, color: RX.fg2)),
      ]),
    );
  }
}
