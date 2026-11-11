import 'package:lusid/core/utils/notes_utils.dart';

/// Represents a single checklist item inside an Apple Note.
class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }
}

/// Represents an interactive table inside an Apple Note.
class NoteTable {
  final String id;
  final int rowCount;
  final int colCount;
  final List<List<String>> cells;

  const NoteTable({
    required this.id,
    required this.rowCount,
    required this.colCount,
    required this.cells,
  });

  NoteTable copyWith({
    String? id,
    int? rowCount,
    int? colCount,
    List<List<String>>? cells,
  }) {
    return NoteTable(
      id: id ?? this.id,
      rowCount: rowCount ?? this.rowCount,
      colCount: colCount ?? this.colCount,
      cells: cells ?? this.cells,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rowCount': rowCount,
      'colCount': colCount,
      'cells': cells,
    };
  }

  factory NoteTable.fromJson(Map<String, dynamic> json) {
    final rawCells = json['cells'] as List<dynamic>? ?? [];
    final List<List<String>> parsedCells = rawCells.map((row) {
      final rowList = row as List<dynamic>;
      return rowList.map((c) => c.toString()).toList();
    }).toList();

    return NoteTable(
      id: json['id'] as String,
      rowCount: (json['rowCount'] as int?) ?? parsedCells.length,
      colCount: (json['colCount'] as int?) ?? (parsedCells.isNotEmpty ? parsedCells.first.length : 2),
      cells: parsedCells,
    );
  }

  factory NoteTable.createDefault(String id) {
    return NoteTable(
      id: id,
      rowCount: 2,
      colCount: 2,
      cells: [
        ['Header 1', 'Header 2'],
        ['Item 1', 'Item 2'],
      ],
    );
  }
}

/// Represents an attachment attached to a note.
class NoteAttachment {
  final String id;
  final String name;
  final String fileType;
  final String localPath;
  final int fileSize;

  const NoteAttachment({
    required this.id,
    required this.name,
    required this.fileType,
    required this.localPath,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fileType': fileType,
      'localPath': localPath,
      'fileSize': fileSize,
    };
  }

  factory NoteAttachment.fromJson(Map<String, dynamic> json) {
    return NoteAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      fileType: json['fileType'] as String,
      localPath: json['localPath'] as String,
      fileSize: (json['fileSize'] as int?) ?? 0,
    );
  }
}

/// Represents an interactive multi-line code block inside a note.
class NoteCodeBlock {
  final String id;
  final String code;
  final String language;

  const NoteCodeBlock({
    required this.id,
    required this.code,
    this.language = 'dart',
  });

  NoteCodeBlock copyWith({
    String? id,
    String? code,
    String? language,
  }) {
    return NoteCodeBlock(
      id: id ?? this.id,
      code: code ?? this.code,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'language': language,
    };
  }

  factory NoteCodeBlock.fromJson(Map<String, dynamic> json) {
    return NoteCodeBlock(
      id: json['id'] as String,
      code: (json['code'] as String?) ?? '',
      language: (json['language'] as String?) ?? 'dart',
    );
  }
}

/// Core Apple Note model
class Note {
  final String id;
  final String folderId;
  final String title;
  final String body;
  final String? richTextJson;
  final List<String> tags;
  final bool isPinned;
  final bool isLocked;
  final String? passwordHash;
  final List<ChecklistItem> checklists;
  final List<NoteTable> tables;
  final List<NoteAttachment> attachments;
  final List<NoteCodeBlock> codeBlocks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.folderId,
    required this.title,
    required this.body,
    this.richTextJson,
    this.tags = const [],
    this.isPinned = false,
    this.isLocked = false,
    this.passwordHash,
    this.checklists = const [],
    this.tables = const [],
    this.attachments = const [],
    this.codeBlocks = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get snippet => NotesUtils.extractSnippet('$title\n$body');

  String get fullContent => title.isEmpty ? body : '$title\n$body';

  Note copyWith({
    String? id,
    String? folderId,
    String? title,
    String? body,
    String? richTextJson,
    List<String>? tags,
    bool? isPinned,
    bool? isLocked,
    String? passwordHash,
    List<ChecklistItem>? checklists,
    List<NoteTable>? tables,
    List<NoteAttachment>? attachments,
    List<NoteCodeBlock>? codeBlocks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      body: body ?? this.body,
      richTextJson: richTextJson ?? this.richTextJson,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      passwordHash: passwordHash ?? this.passwordHash,
      checklists: checklists ?? this.checklists,
      tables: tables ?? this.tables,
      attachments: attachments ?? this.attachments,
      codeBlocks: codeBlocks ?? this.codeBlocks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'body': body,
      'richTextJson': richTextJson,
      'tags': tags,
      'isPinned': isPinned,
      'isLocked': isLocked,
      'passwordHash': passwordHash,
      'checklists': checklists.map((c) => c.toJson()).toList(),
      'tables': tables.map((t) => t.toJson()).toList(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'codeBlocks': codeBlocks.map((cb) => cb.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    final rawChecklists = (json['checklists'] as List<dynamic>?) ?? [];
    final rawTables = (json['tables'] as List<dynamic>?) ?? [];
    final rawAttachments = (json['attachments'] as List<dynamic>?) ?? [];
    final rawCodeBlocks = (json['codeBlocks'] as List<dynamic>?) ??
        (json['code_blocks'] as List<dynamic>?) ??
        [];
    final rawTags = (json['tags'] as List<dynamic>?) ?? [];

    return Note(
      id: json['id'] as String,
      folderId: json['folderId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      richTextJson: json['richTextJson'] as String?,
      tags: rawTags.map((t) => t.toString()).toList(),
      isPinned: (json['isPinned'] as bool?) ?? false,
      isLocked: (json['isLocked'] as bool?) ?? false,
      passwordHash: json['passwordHash'] as String?,
      checklists: rawChecklists.map((c) => ChecklistItem.fromJson(c as Map<String, dynamic>)).toList(),
      tables: rawTables.map((t) => NoteTable.fromJson(t as Map<String, dynamic>)).toList(),
      attachments: rawAttachments.map((a) => NoteAttachment.fromJson(a as Map<String, dynamic>)).toList(),
      codeBlocks: rawCodeBlocks.map((cb) => NoteCodeBlock.fromJson(cb as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
