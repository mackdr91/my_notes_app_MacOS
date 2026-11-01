import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';

/// Embedded interactive table widget matching Apple Notes with row/column handles and context menus.
class NoteTableWidget extends StatelessWidget {
  final NoteTable table;
  final Function(int row, int col, String value) onCellChanged;
  final VoidCallback onAddRow;
  final VoidCallback onAddColumn;
  final VoidCallback onDeleteTable;
  final Function(int rowIndex) onDeleteRow;
  final Function(int colIndex) onDeleteColumn;
  final Function(int atIndex) onInsertRow;
  final Function(int atIndex) onInsertColumn;

  const NoteTableWidget({
    super.key,
    required this.table,
    required this.onCellChanged,
    required this.onAddRow,
    required this.onAddColumn,
    required this.onDeleteTable,
    required this.onDeleteRow,
    required this.onDeleteColumn,
    required this.onInsertRow,
    required this.onInsertColumn,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);
    final borderColor = NotesTheme.divider(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0E) : Colors.white,
        border: Border.all(color: borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Table Top Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141416) : const Color(0xFFF7F7F8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0)),
              border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.table,
                    size: 13,
                    color: NotesTheme.accentGold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Table (${table.rowCount} × ${table.colCount})',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: NotesTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _SmallTableButton(
                    icon: CupertinoIcons.add,
                    label: 'Row',
                    tooltip: 'Add row to bottom',
                    onPressed: onAddRow,
                  ),
                  const SizedBox(width: 6),
                  _SmallTableButton(
                    icon: CupertinoIcons.add,
                    label: 'Column',
                    tooltip: 'Add column to right',
                    onPressed: onAddColumn,
                  ),
                  const SizedBox(width: 12),
                  _SmallTableButton(
                    icon: CupertinoIcons.trash,
                    label: 'Delete Table',
                    tooltip: 'Delete entire table',
                    color: CupertinoColors.destructiveRed,
                    onPressed: onDeleteTable,
                  ),
                ],
              ),
            ),
          ),

          // 2. Interactive Table with Row & Column Handles
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(26.0), // Row Handle Column
              for (int c = 0; c < table.colCount; c++) (c + 1): const FlexColumnWidth(1.0),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: borderColor, width: 0.8),
              verticalInside: BorderSide(color: borderColor, width: 0.8),
            ),
            children: [
              // Top Column Handles Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181A) : const Color(0xFFF0F0F3),
                ),
                children: [
                  // Corner spacing
                  const SizedBox(height: 22, width: 26),
                  for (int c = 0; c < table.colCount; c++)
                    _ColumnHeaderHandle(
                      colIndex: c,
                      canDelete: table.colCount > 1,
                      onDelete: () => onDeleteColumn(c),
                      onInsertLeft: () => onInsertColumn(c),
                      onInsertRight: () => onInsertColumn(c + 1),
                    ),
                ],
              ),

              // Data Rows with Row Handles
              for (int r = 0; r < table.rowCount; r++)
                TableRow(
                  decoration: BoxDecoration(
                    color: r == 0
                        ? (isDark ? const Color(0xFF1C1C1F) : const Color(0xFFFAFAFC))
                        : Colors.transparent,
                  ),
                  children: [
                    // Row Handle on the left
                    _RowHeaderHandle(
                      rowIndex: r,
                      canDelete: table.rowCount > 1,
                      onDelete: () => onDeleteRow(r),
                      onInsertAbove: () => onInsertRow(r),
                      onInsertBelow: () => onInsertRow(r + 1),
                    ),

                    // Cells for this row
                    for (int c = 0; c < table.colCount; c++)
                      _TableCellItem(
                        value: (r < table.cells.length && c < table.cells[r].length)
                            ? table.cells[r][c]
                            : '',
                        isHeader: r == 0,
                        onChanged: (newVal) => onCellChanged(r, c, newVal),
                        onSecondaryTap: (details) {
                          _showCellContextMenu(
                            context,
                            details.globalPosition,
                            rowIndex: r,
                            colIndex: c,
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCellContextMenu(
    BuildContext context,
    Offset position, {
    required int rowIndex,
    required int colIndex,
  }) {
    final canDeleteRow = table.rowCount > 1;
    final canDeleteCol = table.colCount > 1;
    final isDark = NotesTheme.isDark(context);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 320),
      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: NotesTheme.divider(context), width: 0.8),
      ),
      items: [
        PopupMenuItem(
          value: 'delete_row',
          enabled: canDeleteRow,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.trash,
                size: 13,
                color: canDeleteRow ? CupertinoColors.destructiveRed : NotesTheme.textTertiary(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Row ${rowIndex + 1}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: canDeleteRow ? CupertinoColors.destructiveRed : NotesTheme.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete_col',
          enabled: canDeleteCol,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.trash,
                size: 13,
                color: canDeleteCol ? CupertinoColors.destructiveRed : NotesTheme.textTertiary(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Column ${colIndex + 1}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: canDeleteCol ? CupertinoColors.destructiveRed : NotesTheme.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 6),
        PopupMenuItem(
          value: 'insert_row_above',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.arrow_up, size: 13, color: NotesTheme.textPrimary(context)),
              const SizedBox(width: 8),
              Text('Insert Row Above', style: TextStyle(fontSize: 12.5, color: NotesTheme.textPrimary(context))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'insert_row_below',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.arrow_down, size: 13, color: NotesTheme.textPrimary(context)),
              const SizedBox(width: 8),
              Text('Insert Row Below', style: TextStyle(fontSize: 12.5, color: NotesTheme.textPrimary(context))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'insert_col_left',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.arrow_left, size: 13, color: NotesTheme.textPrimary(context)),
              const SizedBox(width: 8),
              Text('Insert Column Left', style: TextStyle(fontSize: 12.5, color: NotesTheme.textPrimary(context))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'insert_col_right',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.arrow_right, size: 13, color: NotesTheme.textPrimary(context)),
              const SizedBox(width: 8),
              Text('Insert Column Right', style: TextStyle(fontSize: 12.5, color: NotesTheme.textPrimary(context))),
            ],
          ),
        ),
        const PopupMenuDivider(height: 6),
        PopupMenuItem(
          value: 'delete_table',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.trash_fill, size: 13, color: CupertinoColors.destructiveRed),
              SizedBox(width: 8),
              Text(
                'Delete Table',
                style: TextStyle(fontSize: 12.5, color: CupertinoColors.destructiveRed),
              ),
            ],
          ),
        ),
      ],
    ).then((choice) {
      if (choice == 'delete_row' && canDeleteRow) {
        onDeleteRow(rowIndex);
      } else if (choice == 'delete_col' && canDeleteCol) {
        onDeleteColumn(colIndex);
      } else if (choice == 'insert_row_above') {
        onInsertRow(rowIndex);
      } else if (choice == 'insert_row_below') {
        onInsertRow(rowIndex + 1);
      } else if (choice == 'insert_col_left') {
        onInsertColumn(colIndex);
      } else if (choice == 'insert_col_right') {
        onInsertColumn(colIndex + 1);
      } else if (choice == 'delete_table') {
        onDeleteTable();
      }
    });
  }
}

/// Column Header Handle displaying column identifier and options menu trigger
class _ColumnHeaderHandle extends StatefulWidget {
  final int colIndex;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onInsertLeft;
  final VoidCallback onInsertRight;

  const _ColumnHeaderHandle({
    required this.colIndex,
    required this.canDelete,
    required this.onDelete,
    required this.onInsertLeft,
    required this.onInsertRight,
  });

  @override
  State<_ColumnHeaderHandle> createState() => _ColumnHeaderHandleState();
}

class _ColumnHeaderHandleState extends State<_ColumnHeaderHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _showMenu(context, details.globalPosition),
        child: Container(
          height: 22,
          alignment: Alignment.center,
          color: _isHovered
              ? (isDark ? const Color(0xFF252528) : const Color(0xFFE5E5EA))
              : Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                String.fromCharCode(65 + widget.colIndex), // A, B, C, ...
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? NotesTheme.accentGold : NotesTheme.textTertiary(context),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                CupertinoIcons.chevron_down,
                size: 9.0,
                color: _isHovered ? NotesTheme.accentGold : NotesTheme.textTertiary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, Offset position) {
    final isDark = NotesTheme.isDark(context);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 320),
      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: NotesTheme.divider(context), width: 0.8),
      ),
      items: [
        PopupMenuItem(
          value: 'delete_col',
          enabled: widget.canDelete,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.trash,
                size: 13,
                color: widget.canDelete ? CupertinoColors.destructiveRed : NotesTheme.textTertiary(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Column',
                style: TextStyle(
                  fontSize: 12.5,
                  color: widget.canDelete ? CupertinoColors.destructiveRed : NotesTheme.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 6),
        PopupMenuItem(
          value: 'insert_left',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.arrow_left, size: 13, color: NotesTheme.textPrimary(context)),
              const SizedBox(width: 8),
              Text('Insert Column Left', style: TextStyle(fontSize: 12.5, color: NotesTheme.textPrimary(context))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'insert_right',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.arrow_right, size: 13, color: NotesTheme.textPrimary(context)),
              const SizedBox(width: 8),
              Text('Insert Column Right', style: TextStyle(fontSize: 12.5, color: NotesTheme.textPrimary(context))),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val == 'delete_col' && widget.canDelete) {
        widget.onDelete();
      } else if (val == 'insert_left') {
        widget.onInsertLeft();
      } else if (val == 'insert_right') {
        widget.onInsertRight();
      }
    });
  }
}

/// Row Header Handle displaying row index and options menu trigger
class _RowHeaderHandle extends StatefulWidget {
  final int rowIndex;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onInsertAbove;
  final VoidCallback onInsertBelow;

  const _RowHeaderHandle({
    required this.rowIndex,
    required this.canDelete,
    required this.onDelete,
    required this.onInsertAbove,
    required this.onInsertBelow,
  });

  @override
  State<_RowHeaderHandle> createState() => _RowHeaderHandleState();
}

class _RowHeaderHandleState extends State<_RowHeaderHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _showMenu(context, details.globalPosition),
        child: Container(
          width: 26,
          height: 32,
          alignment: Alignment.center,
          color: _isHovered
              ? (isDark ? const Color(0xFF252528) : const Color(0xFFE5E5EA))
              : (isDark ? const Color(0xFF141416) : const Color(0xFFF7F7F9)),
          child: _isHovered
              ? Icon(
                  CupertinoIcons.ellipsis,
                  size: 12,
                  color: NotesTheme.accentGold,
                )
              : Text(
                  '${widget.rowIndex + 1}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: NotesTheme.textTertiary(context),
                  ),
                ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, Offset position) {
    final isDark = NotesTheme.isDark(context);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 320),
      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: NotesTheme.divider(context), width: 0.8),
      ),
      items: [
        PopupMenuItem(
          value: 'delete_row',
          enabled: widget.canDelete,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.trash,
                size: 13,
                color: widget.canDelete ? CupertinoColors.destructiveRed : NotesTheme.textTertiary(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Row',
                style: TextStyle(
                  fontSize: 12.5,
                  color: widget.canDelete ? CupertinoColors.destructiveRed : NotesTheme.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 6),
        PopupMenuItem(
          value: 'insert_above',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.arrow_up, size: 13, color: NotesTheme.textPrimary(context)),
              const SizedBox(width: 8),
              Text('Insert Row Above', style: TextStyle(fontSize: 12.5, color: NotesTheme.textPrimary(context))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'insert_below',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.arrow_down, size: 13, color: NotesTheme.textPrimary(context)),
              const SizedBox(width: 8),
              Text('Insert Row Below', style: TextStyle(fontSize: 12.5, color: NotesTheme.textPrimary(context))),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val == 'delete_row' && widget.canDelete) {
        widget.onDelete();
      } else if (val == 'insert_above') {
        widget.onInsertAbove();
      } else if (val == 'insert_below') {
        widget.onInsertBelow();
      }
    });
  }
}

class _SmallTableButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _SmallTableButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        minimumSize: const Size(20, 20),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color ?? NotesTheme.textSecondary(context)),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w500,
                  color: color ?? NotesTheme.textSecondary(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TableCellItem extends StatelessWidget {
  final String value;
  final bool isHeader;
  final ValueChanged<String> onChanged;
  final GestureTapUpCallback onSecondaryTap;

  const _TableCellItem({
    required this.value,
    required this.isHeader,
    required this.onChanged,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap,
      child: _TableCellField(
        value: value,
        isHeader: isHeader,
        onChanged: onChanged,
      ),
    );
  }
}

class _TableCellField extends StatefulWidget {
  final String value;
  final bool isHeader;
  final ValueChanged<String> onChanged;

  const _TableCellField({
    required this.value,
    required this.isHeader,
    required this.onChanged,
  });

  @override
  State<_TableCellField> createState() => _TableCellFieldState();
}

class _TableCellFieldState extends State<_TableCellField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TableCellField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: CupertinoTextField(
        controller: _controller,
        decoration: null,
        padding: EdgeInsets.zero,
        style: TextStyle(
          fontSize: 13.0,
          fontWeight: widget.isHeader ? FontWeight.w600 : FontWeight.normal,
          color: NotesTheme.textPrimary(context),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
