import 'package:flutter_db_input_widget/generation/column_declarations.dart';
import 'package:flutter_db_input_widget/generation/fixed_headers.dart' as Headers;
import 'package:flutter_db_input_widget/io/db_project_io.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_db_input_widget/src/db_project_bloc.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;
import 'package:flutter_tracers/trace.dart' as Log;

import 'generator.dart';

class SQLiteDeclarations {
  final Callback callback;
  final GeneratorIO generatorIO;
  final DBProjectBloc projectBloc;
  SQLiteDeclarations({this.callback, this.generatorIO, this.projectBloc});

  Future<dynamic> createSQLiteTable() async {
    List<String> additionalTables = List();
    generatorIO.newSection(name: 'SQLite Create Table', padding: Headers.classIndent);
    generatorIO.add(['static Future<dynamic> createTable() async {'], padding: Headers.classIndent);
    generatorIO
        .add(["final create = '''CREATE TABLE IF NOT EXISTS ${generatorIO.rootFileName} {"], padding: Headers.parameterIntent);
    String previous = '${Headers.parentRowId} INTEGER DEFAULT 0';
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final sqliteType = record.sqliteType();
      if (sqliteType == null) {
        additionalTables.add('await ${Strings.capitalize(record.target)}.createTable();');
        continue;
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
    return null;
  }

  Future<dynamic> createSQLInsert() async {
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    List<String> keyList = List();
    List<String> valueList = List();
    String previousKey = '${Headers.parentRowId}';
    String previousValue = '\$_${Headers.parentRowId}';
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) continue;
      keyList.add(previousKey + ',');
      valueList.add(previousValue + ',');
      switch (record.columnType) {
        case ColumnTypes.array:
          continue;
        case ColumnTypes.clazz:
          continue;
        case ColumnTypes.date:
        case ColumnTypes.string:
          previousKey = '${declaration.columnName}';
          previousValue = '"\$_${declaration.columnName}"';
          continue;
        case ColumnTypes.boolean:
        case ColumnTypes.double:
        case ColumnTypes.integer:
          previousKey = '${declaration.columnName}';
          previousValue = '\$_${declaration.columnName}';
          continue;
        default:
          Log.f('sqlite_declartion: unknown type ${record.columnType}');
      }
    }
    keyList.add(previousKey);
    valueList.add(previousValue);

    generatorIO.newSection(name: '/// SQLite Insert Record', body: ['Future<int> insert() async {'], padding: Headers.classIndent);
    generatorIO.add(["final sql = '''INSERT INTO ${generatorIO.rootFileName}", "("], padding: Headers.levelIndent(1));
    generatorIO.add(keyList, padding: Headers.levelIndent(2));
    generatorIO.add([')', 'VALUES', '('], padding: Headers.levelIndent(1));
    generatorIO.add(valueList, padding: Headers.levelIndent(2));
    generatorIO.add([")''';", '', 'return await DB.rawInsert(sql);'], padding: Headers.levelIndent(1));
    generatorIO.add(['}'], padding: Headers.classIndent);
    callback('sqlite_declarations: completed sqlite insert');
    return null;
  }

  Future<void> createSQLSave() {
    generatorIO.newSection(
      name: '///- SQLite save record',
      body: ['Future<void> saveToSql() async {'],
      padding: Headers.classIndent,
    );
    generatorIO.add(['final theParentId = await insert();'], padding: Headers.levelIndent(1));
    generatorIO.blankLine;
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array) {
        String code = '''
    for (${declaration.targetName} item in ${declaration.columnName}) {
       item.setParentRowId(theParentId);
       item.save();
    }
        ''';
        continue;
      }
      TODO: Create the one for classes;
    }
  }
}
