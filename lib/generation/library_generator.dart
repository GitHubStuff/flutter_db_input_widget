import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/generation/generation_helpers.dart';
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/src/db_project_bloc.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_tracers/trace.dart' as Log;

class LibraryGenerator {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  const LibraryGenerator({@required this.callback, @required this.generatorIO, @required this.projectBloc});

  /// This creates the file: sqlite_{project}_library.g.dart
  /// At the 'root' of the generated class is the project root, with a file that contains
  /// string constants for each table name, and the 'export' states to the files paths
  /// with those files.
  Future<dynamic> createLibraryFile() async {
    try {
      var library = await _generateLibrary(projectBloc: projectBloc);
      final s = (library as GeneratorIO).content;
      await (library as GeneratorIO).write(s);
      callback('library_generator: created libary file!');
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
      final content = 'library ${projectBloc.asLibraryRootName};';
      final tableNameList = projectBloc.tableNameList();
      generatorIO.add([Headers.libraryHeader(), content, '']);
      for (String tablename in tableNameList) {
        if (!callback('Created path for ${projectBloc.pathForTable(tablename)}')) {
          Log.w('Callback stopped code generation');
          throw CallbackStoppedGeneration('generateLibrary: stopped while creating paths', HelperErrors.userStop);
        }
        final line = "export '${projectBloc.filename}${projectBloc.pathForTable(tablename)}';";
        generatorIO.add([line]);
        await Future.delayed(Duration(milliseconds: 100));
      }
      final tableNameConstList = _generateTableNameConstString(tableNameList);
      generatorIO.newSection(name: '///- Constants to refer to table name', body: tableNameConstList);
      _generateListOfTables(projectBloc: projectBloc);
      return generatorIO;
    } catch (error) {
      Log.e('generateLibrary (error): ${error.toString()}');
    }
  }

  Future<dynamic> _generateListOfTables({@required DBProjectBloc projectBloc}) async {
    final tableNameList = projectBloc.tableNameList();
    generatorIO.newSection(name: '///- Helper: Collection of all table names in the project', body: [
      'final List<String> listOfTables = [',
    ]);
    for (String name in tableNameList) {
      generatorIO.add(["'$name'" + ','], padding: Headers.classIndent);
    }
    generatorIO.add(['];']);
  }

  /// In the sqlite_{project}_library.g.dart file there are 'const String' values for each table name, this creates
  /// those strings to be written to the file;
  List<String> _generateTableNameConstString(List<String> tableNames) => tableNames
      .map((name) => "const String table${Strings.capitalize(name)} = '${Strings.capitalize(name)}';")
      .toList(growable: true)
        ..add('');
}
