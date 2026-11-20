import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/gemini_client.dart';
import '../main.dart';
import '../theme.dart';
import 'subjects_screen.dart';

/// Step 1 of onboarding: the student pastes their own free Gemini key.
class KeyScreen extends StatefulWidget {
  const KeyScreen({super.key});

  @override
  State<KeyScreen> createState() => _KeyScreenState();
}

class _KeyScreenState extends State<KeyScreen> {
  final _controller = TextEditingController();
  KeyCheck? _status;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!.trim();
      setState(() => _status = null);
    }
  }

  Future<void> _continue() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _status = KeyCheck.invalid);
      return;
    }
    setState(() => _checking = true);
    final result = await GeminiClient(apiKey: key).checkKey();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = result;
    });
    if (result == KeyCheck.ok || result == KeyCheck.quotaExhausted) {
      await ServicesScope.of(context).keys.saveKey(key);
      if (!mounted) return;
      _goToSubjects();
    }
  }

  void _goToSubjects() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SubjectsScreen()),
      (_) => false,
    );
  }

  String? get _message => switch (_status) {
        null => null,
        KeyCheck.ok => 'Key works · Gemini ready',
        KeyCheck.invalid => 'That key didn’t work. Copy it again from AI Studio.',
        KeyCheck.quotaExhausted => 'Key saved. Today’s free limit is used up; it resets tomorrow.',
        KeyCheck.networkError => 'Couldn’t reach Google. Check your internet and try again.',
      };

  @override
  Widget build(BuildContext context) {
    final good = _status == KeyCheck.ok;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 1 of 2', style: TextStyle(fontSize: 13, color: RX.fg3))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text('Connect your free Gemini key', style: RX.serif(32)),
            const SizedBox(height: 10),
            const Text(
              'RepeatX uses Google Gemini to read your papers and notes. You use your own '
              'free key, so the app stays free for everyone.',
              style: TextStyle(fontSize: 14, height: 1.55, color: RX.fg2),
            ),
            const SizedBox(height: 20),
            const _HowTo(),
            const SizedBox(height: 20),
            const Text('Gemini API key', style: TextStyle(fontSize: 13, color: RX.fg2)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(hintText: 'AIza…'),
                  onChanged: (_) => setState(() => _status = null),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _paste, child: const Text('Paste')),
            ]),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(_message!, style: TextStyle(fontSize: 12.5, color: good ? RX.ok : RX.warn)),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF17202B),
                border: Border.all(color: const Color(0xFF2B3A44)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Your key is stored only in this phone’s secure storage. On Google’s free '
                'tier, what you send may be used by Google to improve its products.',
                style: TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFFC6CCDA)),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _checking ? null : _continue,
              child: _checking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
            ),
            TextButton(
              onPressed: _goToSubjects,
              child: const Text('Skip for now — basic analysis only', style: TextStyle(color: RX.fg2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowTo extends StatelessWidget {
  const _HowTo();

  @override
  Widget build(BuildContext context) {
    Widget step(String n, String t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 20,
                child: Text(n, style: TextStyle(color: RX.heat(3), fontWeight: FontWeight.w600))),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5, height: 1.45))),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RX.surface,
        border: Border.all(color: RX.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('GET A KEY IN A MINUTE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: RX.fg3)),
        const SizedBox(height: 12),
        step('1', 'Open aistudio.google.com/apikey and sign in with your Google account'),
        step('2', 'Tap “Create API key”'),
        step('3', 'Copy it and paste it below'),
      ]),
    );
  }
}
