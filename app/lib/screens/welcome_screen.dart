import 'package:flutter/material.dart';

import '../theme.dart';
import 'key_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Logo(),
              const SizedBox(height: 48),
              Text('Know what your exam will ask.', style: RX.serif(40)),
              const SizedBox(height: 14),
              const Text(
                'Add your syllabus, past papers and notes. RepeatX sorts them by unit, '
                'finds the questions your teachers keep repeating, and builds mock MST '
                'and End Sem papers from the evidence.',
                style: TextStyle(fontSize: 15, height: 1.55, color: RX.fg2),
              ),
              const SizedBox(height: 28),
              const _Step(n: '1', color: Color(0xFFDD5540), title: 'Upload anything', body: 'Photos, PDFs, slides, handwritten notes'),
              const _Step(n: '2', color: Color(0xFFC08A45), title: 'See what repeats', body: 'Unit by unit, with marks and where it was asked'),
              const _Step(n: '3', color: RX.accent, title: 'Practise the real format', body: 'MST-1, MST-2 and End Sem mock papers'),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const KeyScreen()),
                ),
                child: const Text('Get started'),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Free. Your files stay on your phone.',
                    style: TextStyle(fontSize: 12, color: RX.fg3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    Widget bar(double w, Color c) => Container(
          width: w,
          height: 6,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
        );
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        bar(30, RX.heat(5)),
        bar(24, RX.heat(3)),
        bar(18, RX.heat(1)),
      ]),
      const SizedBox(width: 10),
      const Text('REPEATX',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2.6, color: RX.fg2)),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.color, required this.title, required this.body});
  final String n;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RX.surface,
        border: Border.all(color: RX.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 22, child: Text(n, style: RX.serif(20, color: color))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(fontSize: 13, color: RX.fg2)),
          ]),
        ),
      ]),
    );
  }
}
