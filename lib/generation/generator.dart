import 'dart:io' as IO;

import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/generation/factory_declarations.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/generation/generation_helpers.dart';
import 'package:flutter_db_input_widget/generation/library_generator.dart';
import 'package:flutter_db_input_widget/generation/sqlite_crud_operations.dart';
import 'package:flutter_db_input_widget/generation/sqlite_declarations.dart';
import 'package:flutter_db_input_widget/generation/sqlite_helpers.dart';
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
      /// Header at the top of every file with the files creation date
      /// and all the 'import' statements used by every created file
      generatorIO.add([Headers.tableHeader()]);

      /// If the new classes has any properties that are themselves classes (eg "List<something> items" or "FizzClass other"
      /// this creates 'import' statement for those target class(es).
      _createImportList(generatorIO: generatorIO);

      /// Start of class declaration
      generatorIO.add(['class $tablename extends SQL.SQLParse<$tablename>{']);

      /// 'static const String' for each column of the class/record to be used as helpers to avoid
      /// having code with hard-coded strings
      await _createColumnConstants(generatorIO: generatorIO);

      /// Creates the list of properties/columns with special getters/setter/updaters for properties that are classes or list<>
      await _createColumnDeclarations(generatorIO: generatorIO);

      /// Create the Map properties to get data from json(aka Map<String,dynamic>) and HTTP-GET
      final factoryDeclarations = FactoryDeclarations(callback: callback, generatorIO: generatorIO, projectBloc: projectBloc);
      factoryDeclarations.createInlineMapProperty();
      factoryDeclarations.createInlineCloudMapProperty();

      /// 'static' constructors to handle creation with either an instance of the class or a json object "Map<String,dynamic>"
      final staticBuilders = Headers.createStaticBuilders(generatorIO.projectName);
      generatorIO.newSection(name: '///- Static constructors', body: [staticBuilders]);

      /// The class constructor
      await _createConstructor(generatorIO: generatorIO);
      generatorIO.blankLine;

      /// Create the factory method to be able to create an object from json and json from HTTP-GET
      factoryDeclarations.factoryFromJson();
      factoryDeclarations.factoryFromJsonCloud();

      final sqliteCRUD = SQLiteCRUD(callback: callback, generatorIO: generatorIO, projectBloc: projectBloc);
      sqliteCRUD.createSQLCreate();
      sqliteCRUD.createSQLRead();
      sqliteCRUD.createSQLUpdate();
      sqliteCRUD.createSQLDelete();

      final sqLiteDeclarations = SQLiteDeclarations(callback: callback, generatorIO: generatorIO, projectBloc: projectBloc);
      sqLiteDeclarations.createSQLiteTable();
      //// TODO: Has bugs - waiting for use case sqLiteDeclarations.createSQLRestoreClass();
      sqLiteDeclarations.createSQLSaveClass();

      SQLiteHelpers.createSQLCount(generatorIO: generatorIO);
      SQLiteHelpers.createSQLGetFirstRecord(generatorIO: generatorIO);

      generatorIO.add(['}']);
      return null;
    } catch (error) {
      Log.e('_buildTableContent (error): ${error.toString()}');
      throw FailedToWrite('Failed to create content for "$tablename": ${error.toString()}');
    }
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
    generatorIO.newSection(name: '///- Property/Column declarations', padding: Headers.classIndent);
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

  /// The 'import' states of every class referenced as a "LIST<class> stuff" or "{class} otherStuff" by in the class/table
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
