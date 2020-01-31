import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;

import 'fixed_headers.dart' as Helpers;

const String suffix = '.txt';

typedef Callback = bool Function(String message);

class Generator {
  final DBProjectBloc projectBloc;
  final Callback callback;
  const Generator({@required this.projectBloc, @required this.callback})
      : assert(projectBloc != null),
        assert(callback != null);

  Future<String> go() async {
    return generateDatabase(usingName: projectBloc.name);
  }

  /// Creates a file named {project}.g.dart that will be the database file for the project
  Future<String> generateDatabase({String usingName}) async {
    usingName = Strings.lowercase(usingName ?? projectBloc.name) + '.g';
    final io = DBProjectIO(usingName, fileSuffix: suffix);
    final tableNamesString = generateTableNames();
    final content = Helpers.database(name: usingName, tableNamesAsString: tableNamesString);
    try {
      await io.writeProject(contents: content);
      if (!callback('Datebase $usingName.dart created')) return '..Stopped..';
    } catch (error) {
      return error.toString();
    }
    return null;
  }

  String generateTableNames({List<DBRecord> sortedRows, int indented = 3}) {
    sortedRows ??= projectBloc.sortedTableList();
    if (indented == null || indented < 0) return 'Improper indentation value: $indented';
    final space = Strings.pad(indented);
    String currentTableName;
    String result = '';
    String newLine = '';
    for (DBRecord record in sortedRows) {
      if (currentTableName == record.name) continue;
      currentTableName = Strings.capitalize(record.name);
      result += newLine + space + 'const String table$currentTableName;';
      newLine = '\n';
    }
    return result;
  }
}
