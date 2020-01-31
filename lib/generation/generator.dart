import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_tracers/trace.dart' as Log;

const String suffix = '.g.txt';

typedef Callback = bool Function(String message);

class Generator {
  final DBProjectBloc projectBloc;
  final Callback callback;
  Generator({@required this.projectBloc, @required this.callback})
      : assert(projectBloc != null),
        assert(callback != null);

  Future<dynamic> go() async {
    try {
      var library = await generateLibrary(projectBloc: projectBloc);
      final s = library.content;
      await library.write(s);
      return s;
    } catch (error) {
      Log.e('go (error): ${error.toString()}');
      return error;
    }
  }

  /// Creates a file named {project}.g.dart that will be the database file for the project
  Future<dynamic> generateLibrary({@required DBProjectBloc projectBloc}) async {
    assert(projectBloc != null);
    try {
      final libraryName = 'sqlite_${projectBloc.name.toLowerCase()}_library';
      final generatorIO = GeneratorIO(rootFileName: libraryName, suffix: suffix);
      final content = 'library $libraryName;';
      final tableNameList = projectBloc.tableNameList();
      generatorIO.add([content, '']);
      final tableNameConst = _generateTableNameConstString(tableNameList);
      generatorIO.add(tableNameConst);
      for (String tableName in tableNameList) {
        final path = await generatorIO.createTableFilePath(libraryPath: '$tableName', tableFileName: '$tableName$suffix');
        Log.t('Table file path: ${path.toString()}');
        if (!(path is String)) {
          Log.e('generateLibrary (path): ${path.toString()}');
          return path;
        }
        final line = "export 'package:$libraryName/$tableName/$tableName$suffix';";
        generatorIO.add([line]);
      }
      return generatorIO;
    } catch (error) {
      Log.e('generateLibrary (error): ${error.toString()}');
      return error;
    }
  }

  List<String> _generateTableNameConstString(List<String> tableNames) =>
      tableNames.map((name) => 'const String table${Strings.capitalize(name)};').toList(growable: true)..add('');
}
