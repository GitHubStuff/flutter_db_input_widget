import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_db_input_widget/src/db_project_bloc.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;

import 'generator.dart';

class SQLiteDeclarations {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  SQLiteDeclarations({this.callback, this.generatorIO, this.projectBloc});

  Future<dynamic> createSQLiteTable() async {
    List<String> additionalTables = List();
    generatorIO.newSection(name: 'SQLite methods', padding: Headers.classIndent);
    generatorIO.add(['static Future<void> createTable() async {'], padding: Headers.classIndent);
    generatorIO
        .add(["final create = '''CREATE TABLE IF NOT EXISTS ${generatorIO.rootFileName} {"], padding: Headers.parameterIntent);
    String previous = '$parentRowId INTEGER';
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final sqliteType = record.sqliteType();
      if (sqliteType == null) {
        additionalTables.add('await ${Strings.capitalize(record.target)}.createTable();');
      }
      generatorIO.add([previous + ','], padding: Headers.parameterIntent + 3);
      previous = '${Strings.lowercase(record.field)} $sqliteType';
    }
    generatorIO.add([previous, ")''';"], padding: Headers.parameterIntent + 3);
    generatorIO.blankLine;
    generatorIO.add(additionalTables, padding: Headers.parameterIntent);
    generatorIO.blankLine;
    generatorIO.add(['await DB.SqliteController.database.execute(create);'], padding: Headers.parameterIntent);
    generatorIO.add(['}'], padding: Headers.classIndent);
  }
}
