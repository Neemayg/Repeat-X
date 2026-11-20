class Subject {
  const Subject({
    required this.id,
    required this.name,
    this.codes = const [],
    this.semester,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// Codes change between regulations (21CS2007 -> 23CSPE2007), so a subject
  /// keeps every code it has been known by.
  final List<String> codes;
  final int? semester;
  final DateTime createdAt;

  String get initials {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && w[0] != '&');
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'codes': codes.join(','),
        'semester': semester,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Subject.fromRow(Map<String, Object?> r) => Subject(
        id: r['id'] as String,
        name: r['name'] as String,
        codes: ((r['codes'] as String?) ?? '').split(',').where((c) => c.isNotEmpty).toList(),
        semester: r['semester'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      );
}
