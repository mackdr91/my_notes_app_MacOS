import 'package:flutter/cupertino.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';

/// Represents a folder or smart container in Apple Notes.
class Folder {
  final String id;
  final String name;
  final String account;
  final String? parentId;
  final bool isSystem;
  final String iconType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Folder({
    required this.id,
    required this.name,
    this.account = NotesConstants.accountICloud,
    this.parentId,
    this.isSystem = false,
    this.iconType = 'folder',
    required this.createdAt,
    required this.updatedAt,
  });

  Folder copyWith({
    String? id,
    String? name,
    String? account,
    String? parentId,
    bool? isSystem,
    String? iconType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      account: account ?? this.account,
      parentId: parentId ?? this.parentId,
      isSystem: isSystem ?? this.isSystem,
      iconType: iconType ?? this.iconType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'account': account,
      'parentId': parentId,
      'isSystem': isSystem,
      'iconType': iconType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      account: (json['account'] as String?) ?? NotesConstants.accountICloud,
      parentId: json['parentId'] as String?,
      isSystem: (json['isSystem'] as bool?) ?? false,
      iconType: (json['iconType'] as String?) ?? 'folder',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// System default folders seeded initially
  static List<Folder> get defaultFolders {
    final now = DateTime.now();
    return [
      Folder(
        id: NotesConstants.quickNotesFolderId,
        name: 'Quick Notes',
        account: NotesConstants.accountICloud,
        isSystem: true,
        iconType: 'quick_notes',
        createdAt: now,
        updatedAt: now,
      ),
      Folder(
        id: NotesConstants.allNotesFolderId,
        name: 'All iCloud',
        account: NotesConstants.accountICloud,
        isSystem: true,
        iconType: 'all_notes',
        createdAt: now,
        updatedAt: now,
      ),
      Folder(
        id: NotesConstants.defaultNotesFolderId,
        name: 'Notes',
        account: NotesConstants.accountICloud,
        isSystem: true,
        iconType: 'folder',
        createdAt: now,
        updatedAt: now,
      ),
      Folder(
        id: 'work_folder',
        name: 'Work & Projects',
        account: NotesConstants.accountICloud,
        isSystem: false,
        iconType: 'folder',
        createdAt: now,
        updatedAt: now,
      ),
      Folder(
        id: 'personal_folder',
        name: 'Personal & Ideas',
        account: NotesConstants.accountICloud,
        isSystem: false,
        iconType: 'folder',
        createdAt: now,
        updatedAt: now,
      ),
      Folder(
        id: NotesConstants.trashFolderId,
        name: 'Recently Deleted',
        account: NotesConstants.accountICloud,
        isSystem: true,
        iconType: 'trash',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Returns the corresponding Cupertino icon for this folder
  IconData get iconData {
    switch (iconType) {
      case 'quick_notes':
        return CupertinoIcons.bolt;
      case 'all_notes':
        return CupertinoIcons.square_stack_3d_up;
      case 'trash':
        return CupertinoIcons.trash;
      default:
        return CupertinoIcons.folder;
    }
  }
}
