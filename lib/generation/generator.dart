import 'dart:io' as IO;

import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/generation/generation_helpers.dart';
import 'package:flutter_db_input_widget/generation/sqlite_declarations.dart';
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_tracers/trace.dart' as Log;

import 'column_declarations.dart';

const String parentRowId = 'parentRowId';
const String suffix = '.g.txt';

typedef Callback = bool Function(String message);

class Generator {
  final Callback callback;
  final DBProjectBloc projectBloc;

  Generator({@required this.projectBloc, @required this.callback})
      : assert(projectBloc != null),
        assert(callback != null);

  Future<dynamic> start() async {
    /// File at the root level that has all the 'export' statements and constants for table names
    final result = await _createLibraryFile();
    if (result != null) return result;

    /// Get all the table names for the project, and then create classes(class creations involves A LOT of phases) for each
    /// table in the project bloc.
    final tables = projectBloc.tableNameList();
    for (String tablename in tables) {
      final GeneratorIO generatorIO = GeneratorIO(rootFileName: tablename, suffix: suffix);
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
      generatorIO.add(['class $tablename {']);
      generatorIO.add(['/// *** BODY ***']);
      await _createColumnConstants(generatorIO: generatorIO);
      await _createColumnDeclarations(generatorIO: generatorIO);
      await _createConstructor(generatorIO: generatorIO);

      final sqLiteDeclarations = SQLiteDeclarations(callback: callback, generatorIO: generatorIO, projectBloc: projectBloc);
      sqLiteDeclarations.createSQLiteTable();

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
        generatorIO.add(['import ${projectBloc.pathForTable(record.field)}']);
      }
    }
    if (!first) generatorIO.blankLine;
  }

  /// Generates a list of 'static const String' for each column name, this is used to avoid using quoted strings
  /// (which are prone to typos) when other classes/methods need to reference a column
  Future<void> _createColumnConstants({@required GeneratorIO generatorIO}) async {
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    generatorIO.newSection(
        name: 'Column keys',
        body: [
          'static const String rowid;',
          'static const String $parentRowId;',
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
    generatorIO.newSection(name: 'Column declarations', padding: Headers.classIndent);
    for (DBRecord record in columnRecords) {
      List<String> declaration = ColumnDeclarations(record: record).columnDeclaration();
      generatorIO.add(declaration, padding: Headers.classIndent);
      generatorIO.blankLine;
    }
  }

  /// Creates the text of the Constructor for the table name (eg: "Alarms({int alarm, String alarmName....})"}
  Future<void> _createConstructor({@required GeneratorIO generatorIO}) async {
    final tablename = generatorIO.rootFileName;
    generatorIO.newSection(name: 'Constructor', body: ['$tablename({'], padding: Headers.classIndent);
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: tablename);
    List<String> assignments = List();
    assignments.add('}){');
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      generatorIO.add([declaration.constructorParameter], padding: Headers.parameterIntent);
      assignments.add(declaration.constructorParameterAssignment);
    }
    assignments.add('}');
    generatorIO.blankLine;
    generatorIO.add(assignments, padding: Headers.parameterIntent);
  }

  /// This creates the file: sqlite_{project}_library.g.dart
  /// At the 'root' of the generated class is the project root, with a file that contains
  /// string constants for each table name, and the 'export' states to the files paths
  /// with those files.
  Future<dynamic> _createLibraryFile() async {
    try {
      var library = await _generateLibrary(projectBloc: projectBloc);
      final s = (library as GeneratorIO).content;
      await (library as GeneratorIO).write(s);
      return null;
    } catch (error) {
      Log.e('_createLibraryFile (error): ${error.toString()}');
      return error;
    }
  }

  /// Creates a file named {project}.g.dart that will be the database file for the project,
  /// also builds a list to "_filePaths" that is a Map<String,String> with the table name
  /// as key and the path to the file (usable by Dart.io) to where the table file should be written
  Future<dynamic> _generateLibrary({@required DBProjectBloc projectBloc}) async {
    assert(projectBloc != null);
    try {
      final generatorIO = GeneratorIO(rootFileName: projectBloc.asLibraryRootName, suffix: suffix);
      final content = 'library ${projectBloc.asLibraryRootName};';
      final tableNameList = projectBloc.tableNameList();
      generatorIO.add([Headers.libraryHeader(), content, '']);
      final tableNameConstList = _generateTableNameConstString(tableNameList);
      generatorIO.add(tableNameConstList);
      for (String tablename in tableNameList) {
        if (!callback('Created path for ${projectBloc.pathForTable(tablename)}')) {
          Log.w('Callback stopped code generation');
          throw CallbackStoppedGeneration('generateLibrary: stopped while creating paths', HelperErrors.userStop);
        }
        final line = "export ${projectBloc.pathForTable(tablename)};";
        generatorIO.add([line]);
        await Future.delayed(Duration(milliseconds: 100));
      }
      return generatorIO;
    } catch (error) {
      Log.e('generateLibrary (error): ${error.toString()}');
    }
  }

  /// In the sqlite_{project}_library.g.dart file there are 'const String' values for each table name, this creates
  /// those strings to be written to the file;
  List<String> _generateTableNameConstString(List<String> tableNames) =>
      tableNames.map((name) => 'const String table${Strings.capitalize(name)};').toList(growable: true)..add('');

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
