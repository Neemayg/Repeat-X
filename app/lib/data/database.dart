import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/question.dart';
import '../models/subject.dart';

/// Everything lives on the phone. Tables are kept deliberately simple; nested
/// data (formats, sub-parts) is stored as JSON.
class AppDatabase {
  AppDatabase._(this._db);
  final Database _db;

  static Future<AppDatabase> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'repeatx.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE subjects(
            id TEXT PRIMARY KEY, name TEXT NOT NULL, codes TEXT,
            semester INTEGER, created_at INTEGER NOT NULL)''');
        await db.execute('''
          CREATE TABLE source_files(
            id TEXT PRIMARY KEY, subject_id TEXT NOT NULL, kind TEXT NOT NULL,
            path TEXT NOT NULL, original_name TEXT, unit_hint INTEGER,
            paper_id TEXT, status TEXT NOT NULL, meta TEXT,
            FOREIGN KEY(subject_id) REFERENCES subjects(id) ON DELETE CASCADE)''');
        await db.execute('''
          CREATE TABLE questions(
            id TEXT PRIMARY KEY, subject_id TEXT NOT NULL, json TEXT NOT NULL,
            reviewed INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(subject_id) REFERENCES subjects(id) ON DELETE CASCADE)''');
      },
    );
    return AppDatabase._(db);
  }

  Future<List<Subject>> subjects() async {
    final rows = await _db.query('subjects', orderBy: 'created_at ASC');
    return rows.map(Subject.fromRow).toList();
  }

  Future<void> upsertSubject(Subject s) =>
      _db.insert('subjects', s.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteSubject(String id) => _db.delete('subjects', where: 'id = ?', whereArgs: [id]);

  Future<List<Question>> questions(String subjectId) async {
    final rows = await _db.query('questions', where: 'subject_id = ?', whereArgs: [subjectId]);
    return rows
        .map((r) => Question.fromJson(jsonDecode(r['json'] as String) as Map<String, Object?>))
        .toList();
  }

  Future<void> saveQuestions(String subjectId, List<Question> qs) async {
    final batch = _db.batch();
    for (final q in qs) {
      batch.insert(
        'questions',
        {'id': q.id, 'subject_id': subjectId, 'json': jsonEncode(q.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
