import 'dart:io' as IO;

import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/generation/factory_declarations.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/generation/generation_helpers.dart';
import 'package:flutter_db_input_widget/generation/library_generator.dart';
import 'package:flutter_db_input_widget/generation/sqlite_declarations.dart';
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_tracers/trace.dart' as Log;

import 'column_declarations.dart';

typedef Callback = bool Function(String message);

class Generator {
  final Callback callback;
  final DBProjectBloc projectBloc;

  Generator({@required this.projectBloc, @required this.callback})
      : assert(projectBloc != null),
        assert(callback != null);

  Future<dynamic> start() async {
    /// File at the root level that has all the 'export' statements and constants for table names
    GeneratorIO libraryIO = GeneratorIO(rootFileName: projectBloc.filename, suffix: Headers.suffix);

    final LibraryGenerator libraryGenerator =
        LibraryGenerator(callback: callback, generatorIO: libraryIO, projectBloc: projectBloc);
    final result = await libraryGenerator.createLibraryFile();
    if (result != null) return result;

    /// Get all the table names for the project, and then create classes(class creations involves A LOT of phases) for each
    /// table in the project bloc.
    final tables = projectBloc.tableNameList();
    for (String tablename in tables) {
      final GeneratorIO generatorIO = GeneratorIO(rootFileName: tablename, suffix: Headers.suffix);
      final result = await _buildTableContent(generatorIO: generatorIO);
      if (result != null) return result;
      _writeTableFile(generatorIO: generatorIO);
    }
    return null;
  }

  /// Each table in the project will become a 'class' in code, followed by list of static constants for attribute names,
  /// the properties of the class come from the fields defined for a table, then a constructor to match input to fields.
  Future<dynamic> _buildTableContent({GeneratorIO generatorIO}) async {
    final tablename = generatorIO.rootFileName;
    try {
      generatorIO.add([Headers.tableHeader()]);
      _createImportList(generatorIO: generatorIO);

      /// Add 'import' for any fields that are class or arrays
      generatorIO.add(['class $tablename extends SQL.SQLParse<$tablename>{']);
      await _createColumnConstants(generatorIO: generatorIO);
      await _createColumnDeclarations(generatorIO: generatorIO);
      await _createConstructor(generatorIO: generatorIO);
      generatorIO.blankLine;
      final staticBuilders = Headers.createStaticBuilders(generatorIO.projectName);
      generatorIO.add([staticBuilders]);
      await FactoryDeclarations(callback: callback, generatorIO: generatorIO, projectBloc: projectBloc).makeFactories();

      final disposalMethod = _createDisposeMethod(tablename: tablename, generatorIO: generatorIO);
      generatorIO.add([disposalMethod]);

      final sqLiteDeclarations = SQLiteDeclarations(callback: callback, generatorIO: generatorIO, projectBloc: projectBloc);
      sqLiteDeclarations.createSQLiteTable();
      generatorIO.newSection(
          name: '///- Common SQL statements......',
          body: [Headers.createSQLSelectStatement(tablename)],
          padding: Headers.classIndent);

      sqLiteDeclarations.createSQLInsert();
      sqLiteDeclarations.createSQLRestore();
      sqLiteDeclarations.createSQLSave();

      generatorIO.add(['}']);
      return null;
    } catch (error) {
      Log.e('_buildTableContent (error): ${error.toString()}');
      throw FailedToWrite('Failed to create content for "$tablename": ${error.toString()}');
    }
  }

  Future<void> _createImportList({@required GeneratorIO generatorIO}) async {
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    bool first = true;
    for (DBRecord record in columnRecords) {
      if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) {
        if (first) generatorIO.blankLine;
        first = false;
        generatorIO.add(["import '..${projectBloc.pathForTable(record.target)}';"]);
      }
    }
    if (!first) generatorIO.blankLine;
  }

  /// Generates a list of 'static const String' for each column name, this is used to avoid using quoted strings
  /// (which are prone to typos) when other classes/methods need to reference a column
  Future<void> _createColumnConstants({@required GeneratorIO generatorIO}) async {
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    generatorIO.newSection(
        name: '/// Column keys',
        body: [
          "static const String column${Strings.capitalize(Headers.sqlRowid)} = '${Headers.sqlRowid}';",
          "static const String column${Strings.capitalize(Headers.parentRowId)} = '${Headers.parentRowId}';",
        ],
        padding: Headers.classIndent);
    for (DBRecord record in columnRecords) {
      String text = "static const String ${Headers.columnPrefix}${Strings.capitalize(record.field)} = ";
      text += "'${Strings.lowercase(record.field)}';${record.trailingComment}";
      generatorIO.add([text], padding: Headers.classIndent);
    }
  }

  Future<void> _createColumnDeclarations({@required GeneratorIO generatorIO}) async {
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    generatorIO.newSection(name: '///- Column declarations', padding: Headers.classIndent);
    generatorIO.add([
      'int _${Headers.sqlRowid};   ///+ SQLite column',
      'int get ${Headers.sqlRowid} => _${Headers.sqlRowid} ?? 0;',
      'void set${Strings.capitalize(Headers.sqlRowid)}(int newValue) => _${Headers.sqlRowid} = newValue ?? 0;'
    ], padding: Headers.classIndent);
    generatorIO.blankLine;
    generatorIO.add([
      'int _${Headers.parentRowId};     ///+ To pair class to other classes and arrays',
      'int get ${Headers.parentRowId} => _${Headers.parentRowId} ?? 0;',
      'void set${Strings.capitalize(Headers.parentRowId)}(int newValue) => _${Headers.parentRowId} = newValue ?? 0;',
    ], padding: Headers.classIndent);
    generatorIO.blankLine;
    generatorIO.add([
      'String _${Headers.parentClassName};   ///+  Part of pairing class to other classes/arrays',
      "String get ${Headers.parentClassName} => _${Headers.parentClassName} ?? '';",
      "String set${Strings.capitalize(Headers.parentClassName)}(String newValue) => _${Headers.parentClassName} = newValue ?? '';",
    ], padding: Headers.classIndent);
    generatorIO.blankLine;
    for (DBRecord record in columnRecords) {
      List<String> declaration = ColumnDeclarations(record: record).columnDeclaration();
      generatorIO.add(declaration, padding: Headers.classIndent);
      generatorIO.blankLine;
    }
  }

  /// Creates the text of the Constructor for the table name (eg: "Alarms({int alarm, String alarmName....})"}
  Future<void> _createConstructor({@required GeneratorIO generatorIO}) async {
    final tablename = generatorIO.rootFileName;
    generatorIO.newSection(name: '///- Constructor', body: ['$tablename({'], padding: Headers.classIndent);
    generatorIO.add([
      'int ${Headers.sqlRowid},',
      'int ${Headers.parentRowId},',
      'String ${Headers.parentClassName},',
    ], padding: Headers.levelIndent(2));
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: tablename);
    List<String> assignments = List();
    assignments.add('set${Strings.capitalize(Headers.sqlRowid)}(${Headers.sqlRowid});');
    assignments.add('set${Strings.capitalize(Headers.parentRowId)}(${Headers.parentRowId});');
    assignments.add('set${Strings.capitalize(Headers.parentClassName)}(${Headers.parentClassName});');
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      generatorIO.add([declaration.constructorParameter], padding: Headers.levelIndent(2));
      assignments.add(declaration.constructorParameterAssignment);
    }
    generatorIO.add(['}){'], padding: Headers.levelIndent(1));
    generatorIO.add(assignments, padding: Headers.levelIndent(2));
    generatorIO.add(['}'], padding: Headers.classIndent);
  }

  String _createDisposeMethod({@required String tablename, @required GeneratorIO generatorIO}) {
    GeneratorIO localIO = GeneratorIO(rootFileName: 'fake');
    localIO.newSection(name: '///- Create dispose/delete method', body: ['void dispose() {'], padding: Headers.classIndent);
    localIO.add(["await SQL.SqliteController.database.rawDelete('DELETE FROM $tablename WHERE rowid = \$rowid');"],
        padding: Headers.classIndent + 3);
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      String declaration = ColumnDeclarations(record: record).columnDispose();
      if (declaration != null) localIO.add([declaration], padding: Headers.classIndent + 3);
    }
    localIO.add(['}'], padding: Headers.classIndent);
    return localIO.content;
  }

  /// After the table file has been composed with all the fields, the contents are written to
  /// the file {tablename}.g.dart, this will have the class definition and all the methods used to create and
  /// link to the sqlite database.
  Future<dynamic> _writeTableFile({@required GeneratorIO generatorIO}) async {
    final path = await generatorIO.createTableFilePath(dbProjectBloc: projectBloc);
    final file = IO.File(path);
    await file.writeAsString(generatorIO.content, flush: true);
    callback('Created class ${generatorIO.rootFileName}');
    await Future.delayed(Duration(milliseconds: 150));
  }
}
