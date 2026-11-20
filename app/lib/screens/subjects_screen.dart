import 'package:flutter/material.dart';

import '../main.dart';
import '../models/subject.dart';
import '../theme.dart';
import 'key_screen.dart';
import 'subject_home_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Subject>? _subjects;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final list = await ServicesScope.of(context).db.subjects();
    if (mounted) setState(() => _subjects = list);
  }

  Future<void> _addSubject() async {
    final name = await showDialog<String>(context: context, builder: (_) => const _AddSubjectDialog());
    if (name == null || name.trim().isEmpty || !mounted) return;
    final subject = Subject(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    await ServicesScope.of(context).db.upsertSubject(subject);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _subjects;
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPEATX',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.4, color: RX.fg3)),
        actions: [
          IconButton(
            tooltip: 'Gemini key',
            icon: const Icon(Icons.key_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const KeyScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Subjects', style: RX.serif(38)),
            const SizedBox(height: 6),
            Text(
              subjects == null ? '' : '${subjects.length} subject${subjects.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13.5, color: RX.fg2),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: subjects == null
                  ? const Center(child: CircularProgressIndicator())
                  : subjects.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          itemCount: subjects.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _SubjectCard(
                            subject: subjects[i],
                            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => SubjectHomeScreen(subject: subjects[i]),
                            )),
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: FilledButton.icon(
                onPressed: _addSubject,
                icon: const Icon(Icons.add),
                label: const Text('Add a subject'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Start with one subject', style: RX.serif(24)),
      const SizedBox(height: 10),
      const Text(
        'Add a subject, then drop in its syllabus, past MST and End Sem papers, '
        'question bank and notes.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, height: 1.5, color: RX.fg2),
      ),
    ]);
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});
  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RX.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: RX.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: RX.raised, borderRadius: BorderRadius.circular(10)),
              child: Text(subject.initials, style: RX.serif(15, color: RX.fg2)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(subject.name, style: RX.serif(19))),
            const Icon(Icons.chevron_right, color: RX.fg3),
          ]),
        ),
      ),
    );
  }
}

class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();
  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Enter a subject name');
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: RX.surface,
      title: const Text('New subject'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: 'Computer Architecture & Organization', errorText: _error),
        onChanged: (_) => setState(() => _error = null),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
