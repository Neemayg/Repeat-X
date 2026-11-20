# RepeatX

Add a subject, drop in everything your teacher gave you — syllabus, past MST and
End Sem papers, question banks, notes — and RepeatX tells you, unit by unit, what
has been asked, how often, for how many marks, and where the answer is in your
notes. Then it builds mock MST-1, MST-2 and End Sem papers from that evidence.

Free for students. iOS and Android from one Flutter codebase. Each student uses
their own free Gemini key; everything else stays on the phone.

## Layout

| Path | What it is |
| --- | --- |
| `app/` | v2 — the Flutter app (in progress) |
| `eval/` | Hand-labelled real papers used to measure accuracy (`cao_ground_truth.json`: 5 CAO papers, 78 questions, repeat groups) |
| `legacy/` | v0 — the original SwiftUI app and Swift analysis engine (`RepeatKit`) |
| `.github/workflows/app.yml` | Free CI: analyse, test, build an Android APK on every push |

## Running v2

```bash
cd app
flutter create . --project-name repeatx --org com.neemaygupta --platforms android,ios   # first time only
flutter pub get
flutter test        # format rules + generator checked against real CAO papers
flutter run
```

## Exam formats (SRM Delhi-NCR, current)

- **MST-1** (Units 1–2) and **MST-2** (Units 3–4) — 90 min, 30 marks: Part A 5 × 2, Part B any 4 of 5 × 5
- **End Sem** (Units 1–5) — 3 hours, 100 marks: Part A 10 × 2, Part B Q11–Q15 one per unit, (a) OR (b), 16 marks each

Formats are data; older papers keep the format printed on them.

## Status

- [x] Product spec, UI design, real-data audit, ground-truth set
- [x] Flutter foundation: theme, Gemini key onboarding (BYOK), subjects, local DB, exam formats, evidence-based paper generator with tests
- [ ] Phase 2: import files, Gemini extraction, review screen
- [ ] Phase 3: unit/topic analysis screens
- [ ] Phase 4: link questions to notes
- [ ] Phase 5: mock paper screen + PDF export
