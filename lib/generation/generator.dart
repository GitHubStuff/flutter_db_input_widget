import 'dart:io' as IO;

import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/generation/generation_helpers.dart';
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_tracers/trace.dart' as Log;

const String suffix = '.g.txt';

typedef Callback = bool Function(String message);

class Generator {
  static const String zerk = 'ZERK';

  final Callback callback;
  final DBProjectBloc projectBloc;

  Generator({@required this.projectBloc, @required this.callback})
      : assert(projectBloc != null),
        assert(callback != null);

  Future<dynamic> start() async {
    final result = await _createLibraryFile();
    if (result != null) return result;
    final tables = projectBloc.tableNameList();
    for (String table in tables) {
      final result = await _writeTable(tableName: table);
      if (result != null) return result;
    }
    return null;
  }

  Future<dynamic> _createLibraryFile() async {
    try {
      var library = await _generateLibrary(projectBloc: projectBloc);
      final s = (library as GeneratorIO).content;
      await (library as GeneratorIO).write(s);
      return null;
    } catch (error) {
      Log.e('go() (error): ${error.toString()}');
      return error;
    }
  }

  Future<dynamic> _writeTable({String tableName}) async {
    try {
      final GeneratorIO generatorIO = GeneratorIO(rootFileName: tableName, suffix: suffix);
      generatorIO.add([Headers.tableHeader()]);
      generatorIO.add(['class $tableName {']);
      generatorIO.add(['/// *** BODY ***']);
      generatorIO.add(['}']);
      final path = await generatorIO.createTableFilePath(dbProjectBloc: projectBloc);
      final file = IO.File(path);
      await file.writeAsString(generatorIO.content, flush: true);
      callback('Created class $tableName');
      await Future.delayed(Duration(milliseconds: 150));
      return null;
    } catch (error) {
      Log.e('_writeTable (error): ${error.toString()}');
      throw FailedToWrite('Failed to write "$tableName": ${error.toString()}');
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
      for (String tableName in tableNameList) {
        final asFlutterFilename = Strings.flutterFilenameStyle(using: tableName);
        if (!callback('Created path for $asFlutterFilename$suffix')) {
          Log.w('Callback stopped code generation');
          throw CallbackStoppedGeneration('generateLibrary: stopped while creating paths', HelperErrors.userStop);
        }
        final line =
            "export 'package:${projectBloc.asLibraryRootName}/${DBProjectBloc.tablePrefix}$asFlutterFilename/$asFlutterFilename$suffix';";
        generatorIO.add([line]);
        await Future.delayed(Duration(milliseconds: 100));
      }
      return generatorIO;
    } catch (error) {
      Log.e('generateLibrary (error): ${error.toString()}');
    }
  }

  List<String> _generateTableNameConstString(List<String> tableNames) =>
      tableNames.map((name) => 'const String table${Strings.capitalize(name)};').toList(growable: true)..add('');
}
