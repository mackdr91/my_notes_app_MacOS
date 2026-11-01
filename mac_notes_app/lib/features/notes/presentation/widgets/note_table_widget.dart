import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';

/// Embedded interactive table widget matching Apple Notes.
class NoteTableWidget extends StatelessWidget {
  final NoteTable table;
  final Function(int row, int col, String value) onCellChanged;
  final VoidCallback onAddRow;
  final VoidCallback onAddColumn;
  final VoidCallback onDeleteTable;

  const NoteTableWidget({
    super.key,
    required this.table,
    required this.onCellChanged,
    required this.onAddRow,
    required this.onAddColumn,
    required this.onDeleteTable,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);
    final borderColor = NotesTheme.divider(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252528) : const Color(0xFFF7F7F8),
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
                    color: NotesTheme.textSecondary(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Table (${table.rowCount} × ${table.colCount})',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: NotesTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _SmallTableButton(
                    icon: CupertinoIcons.add,
                    label: 'Row',
                    onPressed: onAddRow,
                  ),
                  const SizedBox(width: 6),
                  _SmallTableButton(
                    icon: CupertinoIcons.add,
                    label: 'Column',
                    onPressed: onAddColumn,
                  ),
                  const SizedBox(width: 6),
                  _SmallTableButton(
                    icon: CupertinoIcons.trash,
                    label: '',
                    color: CupertinoColors.destructiveRed,
                    onPressed: onDeleteTable,
                  ),
                ],
              ),
            ),
          ),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: borderColor, width: 0.8),
              verticalInside: BorderSide(color: borderColor, width: 0.8),
            ),
            children: List.generate(table.rowCount, (rowIndex) {
              final isHeader = rowIndex == 0;
              final rowCells = rowIndex < table.cells.length ? table.cells[rowIndex] : <String>[];

              return TableRow(
                decoration: BoxDecoration(
                  color: isHeader
                      ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFAFAFC))
                      : Colors.transparent,
                ),
                children: List.generate(table.colCount, (colIndex) {
                  final cellValue = colIndex < rowCells.length ? rowCells[colIndex] : '';
                  return _TableCellField(
                    value: cellValue,
                    isHeader: isHeader,
                    onChanged: (val) => onCellChanged(rowIndex, colIndex, val),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SmallTableButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _SmallTableButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      minimumSize: const Size(20, 20),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color ?? NotesTheme.textSecondary(context)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: color ?? NotesTheme.textSecondary(context),
              ),
            ),
          ],
        ],
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
