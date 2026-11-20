/// Prompts and response schemas for the extraction pipeline.
///
/// Built from what real SRM CAO papers look like: phone photos with shadows,
/// two-column End Sem layouts, tables in MSTs, sub-part marks like (10+6),
/// (8+2*4), MCQ / fill-in / match questions, and filenames whose year is wrong.
library;

const paperExtractionPrompt = '''
You are reading photos of ONE university exam question paper (possibly several pages).
Transcribe it faithfully. Do not invent, merge, reword, or answer anything.

Rules:
- Take exam type, year and month from the printed header, never from the file name.
  Exam type: END_SEM ("End Term/End Semester Examination"), MST1 ("MST-1", "Internal Assessment Test-I"),
  MST2 ("MST-2", "Internal Assessment Test-II"), or OTHER.
- Copy the printed format: duration, max marks, and each part's question count, marks each,
  and choice rule ("any THREE", "(a) OR (b)", or all compulsory). If the header contradicts
  itself, report both in "warnings".
- The page may have two columns: finish the left column before the right one.
- One entry per answerable question. For "11 a) ... OR b) ...", output 11a and 11b with choiceGroup "11".
- marks: the total for that question. split: printed sub-marks such as (10+6) -> [10,6], (8+2*4) -> [8,2,2,2,2].
- type: theory | numerical | mixed | mcq | fillBlank | match. Keep MCQ options inside text.
- If any text is unreadable, write [unclear] in its place and set confidence below 0.7.
''';

const Map<String, Object?> paperExtractionSchema = {
  'type': 'OBJECT',
  'properties': {
    'examType': {'type': 'STRING', 'enum': ['END_SEM', 'MST1', 'MST2', 'OTHER']},
    'year': {'type': 'INTEGER', 'nullable': true},
    'month': {'type': 'INTEGER', 'nullable': true},
    'subjectCode': {'type': 'STRING', 'nullable': true},
    'subjectName': {'type': 'STRING', 'nullable': true},
    'durationMinutes': {'type': 'INTEGER', 'nullable': true},
    'maxMarks': {'type': 'INTEGER', 'nullable': true},
    'sections': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING'},
          'printedCount': {'type': 'INTEGER'},
          'marksEach': {'type': 'INTEGER'},
          'choice': {'type': 'STRING', 'enum': ['none', 'internalOr', 'anyOf']},
          'answerCount': {'type': 'INTEGER', 'nullable': true},
        },
        'required': ['name', 'printedCount', 'marksEach', 'choice'],
      },
    },
    'questions': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'section': {'type': 'STRING'},
          'number': {'type': 'STRING'},
          'choiceGroup': {'type': 'STRING', 'nullable': true},
          'marks': {'type': 'INTEGER'},
          'split': {'type': 'ARRAY', 'items': {'type': 'INTEGER'}},
          'type': {
            'type': 'STRING',
            'enum': ['theory', 'numerical', 'mixed', 'mcq', 'fillBlank', 'match'],
          },
          'text': {'type': 'STRING'},
          'confidence': {'type': 'NUMBER'},
        },
        'required': ['section', 'number', 'marks', 'type', 'text', 'confidence'],
      },
    },
    'warnings': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
  },
  'required': ['examType', 'sections', 'questions'],
};

/// Syllabus image/PDF -> unit/topic tree.
const syllabusPrompt = '''
This is a course syllabus. List every unit in order with its title and the topics
listed under it, split on the dashes or commas the syllabus uses. Keep the wording.
''';

const Map<String, Object?> syllabusSchema = {
  'type': 'OBJECT',
  'properties': {
    'units': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'number': {'type': 'INTEGER'},
          'title': {'type': 'STRING'},
          'topics': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
        },
        'required': ['number', 'title', 'topics'],
      },
    },
  },
  'required': ['units'],
};
