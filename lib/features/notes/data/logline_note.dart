class LogLineNote {
  const LogLineNote({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.content,
    required this.tag,
    required this.collaborators,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String content;
  final String tag;
  final List<String> collaborators;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? syncedAt;

  String get summary {
    final plain = content
        .replaceAll(RegExp(r'[#>*_`\-\[\]()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (plain.isEmpty) return 'Belum ada isi catatan.';
    return plain.length <= 96 ? plain : '${plain.substring(0, 96)}...';
  }

  LogLineNote copyWith({
    String? title,
    String? content,
    String? tag,
    List<String>? collaborators,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? syncedAt,
  }) {
    return LogLineNote(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      collaborators: collaborators ?? this.collaborators,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'content': content,
      'tag': tag,
      'collaborators': collaborators,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
    };
  }

  factory LogLineNote.fromMap(Map<String, dynamic> map) {
    return LogLineNote(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String? ?? 'local-user',
      title: map['title'] as String? ?? 'Tanpa judul',
      content: map['content'] as String? ?? '',
      tag: map['tag'] as String? ?? 'Personal',
      collaborators: (map['collaborators'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      isDeleted: map['isDeleted'] as bool? ?? false,
      syncedAt: DateTime.tryParse(map['syncedAt'] as String? ?? ''),
    );
  }
}
