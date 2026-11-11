// Author: Domonick Mack
// Date: 2026-11-10
// Description: Widget tests for NoteTableWidget row and column insertion, deletion, and editing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lusid/core/constants/notes_constants.dart';
import 'package:lusid/features/notes/models/note_model.dart';
import 'package:lusid/features/notes/presentation/widgets/note_table_widget.dart';
import 'package:lusid/features/notes/providers/notes_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Table Operations Provider Tests', () {
    test(
      'deleteTableRow deletes a specific row and updates rowCount',
      () async {
        final provider = NotesProvider();
        await Future.delayed(const Duration(milliseconds: 50));

        final note = await provider.createNote(
          folderId: NotesConstants.defaultNotesFolderId,
        );
        await provider.addTable(note.id); // Default 2x2 table

        // Add a 3rd row
        await provider.addTableRow(
          note.id,
          provider.selectedNote!.tables.first.id,
        );
        var currentTable = provider.selectedNote!.tables.first;
        expect(currentTable.rowCount, 3);
        expect(currentTable.cells.length, 3);

        // Populate cell data
        await provider.updateTableCell(
          note.id,
          currentTable.id,
          0,
          0,
          'Row 0 Data',
        );
        await provider.updateTableCell(
          note.id,
          currentTable.id,
          1,
          0,
          'Row 1 Data',
        );
        await provider.updateTableCell(
          note.id,
          currentTable.id,
          2,
          0,
          'Row 2 Data',
        );

        // Delete Row 1
        await provider.deleteTableRow(note.id, currentTable.id, 1);
        currentTable = provider.selectedNote!.tables.first;
        expect(currentTable.rowCount, 2);
        expect(currentTable.cells.length, 2);
        expect(currentTable.cells[0][0], 'Row 0 Data');
        expect(
          currentTable.cells[1][0],
          'Row 2 Data',
        ); // Former row 2 shifted up
      },
    );

    test('deleteTableRow prevents deletion below minimum 1 row', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final note = await provider.createNote(
        folderId: NotesConstants.defaultNotesFolderId,
      );
      await provider.addTable(note.id); // 2 rows

      final tableId = provider.selectedNote!.tables.first.id;

      // Delete 1 row -> now 1 row remaining
      await provider.deleteTableRow(note.id, tableId, 1);
      var table = provider.selectedNote!.tables.first;
      expect(table.rowCount, 1);

      // Attempt to delete last row -> must be prevented (kept at 1)
      await provider.deleteTableRow(note.id, tableId, 0);
      table = provider.selectedNote!.tables.first;
      expect(table.rowCount, 1);
      expect(table.cells.length, 1);
    });

    test('deleteTableColumn deletes a specific column and updates colCount across all rows', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final note = await provider.createNote(
        folderId: NotesConstants.defaultNotesFolderId,
      );
      await provider.addTable(note.id); // Default 2x2 table
      final tableId = provider.selectedNote!.tables.first.id;

      // Add 3rd column
      await provider.addTableColumn(note.id, tableId);
      var currentTable = provider.selectedNote!.tables.first;
      expect(currentTable.colCount, 3);

      // Populate columns
      await provider.updateTableCell(note.id, tableId, 0, 0, 'Col A');
      await provider.updateTableCell(note.id, tableId, 0, 1, 'Col B');
      await provider.updateTableCell(note.id, tableId, 0, 2, 'Col C');

      // Delete Column 1 ('Col B')
      await provider.deleteTableColumn(note.id, tableId, 1);
      currentTable = provider.selectedNote!.tables.first;
      expect(currentTable.colCount, 2);
      expect(currentTable.cells[0][0], 'Col A');
      expect(currentTable.cells[0][1], 'Col C'); // Former col 2 shifted left
    });

    test(
      'deleteTableColumn prevents deletion below minimum 1 column',
      () async {
        final provider = NotesProvider();
        await Future.delayed(const Duration(milliseconds: 50));

        final note = await provider.createNote(
          folderId: NotesConstants.defaultNotesFolderId,
        );
        await provider.addTable(note.id); // 2 columns
        final tableId = provider.selectedNote!.tables.first.id;

        // Delete 1 column -> 1 column remaining
        await provider.deleteTableColumn(note.id, tableId, 1);
        var table = provider.selectedNote!.tables.first;
        expect(table.colCount, 1);

        // Attempt to delete last column -> must be prevented
        await provider.deleteTableColumn(note.id, tableId, 0);
        table = provider.selectedNote!.tables.first;
        expect(table.colCount, 1);
        expect(table.cells.first.length, 1);
      },
    );

    test(
      'insertTableRow and insertTableColumn insert at specific index',
      () async {
        final provider = NotesProvider();
        await Future.delayed(const Duration(milliseconds: 50));

        final note = await provider.createNote(
          folderId: NotesConstants.defaultNotesFolderId,
        );
        await provider.addTable(note.id);
        final tableId = provider.selectedNote!.tables.first.id;

        // Insert Row at index 0 (Above)
        await provider.insertTableRow(note.id, tableId, 0);
        var table = provider.selectedNote!.tables.first;
        expect(table.rowCount, 3);

        // Insert Column at index 0 (Left)
        await provider.insertTableColumn(note.id, tableId, 0);
        table = provider.selectedNote!.tables.first;
        expect(table.colCount, 3);
      },
    );
  });

  group('NoteTableWidget UI Tests', () {
    testWidgets('renders table handles and triggers delete actions', (
      tester,
    ) async {
      int? deletedRowIndex;
      int? deletedColIndex;

      final testTable = NoteTable(
        id: 'table_1',
        rowCount: 3,
        colCount: 3,
        cells: [
          ['A1', 'B1', 'C1'],
          ['A2', 'B2', 'C2'],
          ['A3', 'B3', 'C3'],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NoteTableWidget(
                table: testTable,
                onCellChanged: (_, _, _) {},
                onAddRow: () {},
                onAddColumn: () {},
                onDeleteTable: () {},
                onDeleteRow: (r) => deletedRowIndex = r,
                onDeleteColumn: (c) => deletedColIndex = c,
                onInsertRow: (_) {},
                onInsertColumn: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check column header handles (A, B, C)
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      // Check row header handles (1, 2, 3)
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Click column handle B (column 1)
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      // Menu pops up with 'Delete Column'
      expect(find.text('Delete Column'), findsOneWidget);
      await tester.tap(find.text('Delete Column'));
      await tester.pumpAndSettle();
      expect(deletedColIndex, 1);

      // Click row handle 2 (row 1)
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Menu pops up with 'Delete Row'
      expect(find.text('Delete Row'), findsOneWidget);
      await tester.tap(find.text('Delete Row'));
      await tester.pumpAndSettle();
      expect(deletedRowIndex, 1);
    });
  });
}
