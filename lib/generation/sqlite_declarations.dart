import 'package:flutter_db_input_widget/generation/column_declarations.dart';
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
    generatorIO.newSection(name: '///- **********', body: ['///- SQLite Create Table'], padding: Headers.classIndent);
    generatorIO.add(['static Future<dynamic> createTable() async {'], padding: Headers.classIndent);
    generatorIO.add([
      'if (!_createTableIfNeeded) return null;',
      '_createTableIfNeeded = false;',
      "final create = '''CREATE TABLE IF NOT EXISTS ${generatorIO.tableName} (",
    ], padding: Headers.parameterIntent);
    String firstRow = '${Headers.parentRowid} INTEGER DEFAULT 0,';
    generatorIO.add([firstRow], padding: Headers.parameterIntent + 3);
    String previous = "${Headers.parentTableName} TEXT DEFAULT ''";
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    for (DBRecord record in columnRecords) {
      final sqliteType = record.sqliteType();
      if (sqliteType == null) {
        continue;
      }
      generatorIO.add([previous + ','], padding: Headers.parameterIntent + 3);
      previous = '${Strings.lowercase(record.field)} $sqliteType';
    }
    generatorIO.add([previous, ")''';"], padding: Headers.parameterIntent + 3);
    generatorIO.blankLine;
    generatorIO.add([
      'await SQL.SqliteController.database.execute(create);',
      'return null;',
    ], padding: Headers.parameterIntent);
    generatorIO.add(['}'], padding: Headers.classIndent);
    return null;
  }

  Future<void> createSQLRestoreClass() async {
    generatorIO.newSection(
      name: '///- SQLite restore class (properties, arrays, classes)',
      body: ['static Future<List<Map<String, dynamic>>> restoreJsonFromSQL({String where}) async {'],
      padding: Headers.classIndent,
    );
    List<DBRecord> columnRecords = projectBloc.columnsInTable(name: generatorIO.rootFileName);
    generatorIO.add([
      "List<Map<String, dynamic>> result = await ${generatorIO.rootFileName}.readRecord(where: where);",
    ], padding: Headers.levelIndent(1));

    List<String> header = [
      "int parentId;",
      "String parentName;",
      "for (Map<String, dynamic> item in result) {",
      "   parentId = item['${Headers.parentRowid}'];",
      "   if (parentId == null || parentId == 0) throw Exception('Invalid state - parentId \$parentId');",
      "   parentName = item['${Headers.parentTableName}'];",
      "   if (parentName == null || parentName == '') throw Exception('Invalid state - parentName \"\$parentName\"');",
      "   String whereClause = \"(${Headers.parentRowid} = parentId AND ${Headers.parentTableName} = '\$parentName\')\";",
    ];
    bool first = true;
    for (DBRecord record in columnRecords) {
      final declaration = ColumnDeclarations(record: record);
      if (record.columnType == ColumnTypes.array) {
        if (first) generatorIO.add(header, padding: Headers.classIndent + 3);
        first = false;
        String code = '''
         item['${declaration.columnName}'] = await ${declaration.targetName}.restoreJsonFromSQL(where: whereClause);''';
        generatorIO.add([code]);
        continue;
      }
      if (record.columnType == ColumnTypes.clazz) {
        if (first) generatorIO.add(header, padding: Headers.classIndent + 3);
        first = false;
        String code = '''
        List<Map<String, dynamic>> tempList = await ${declaration.targetName}.restoreJsonFromSQL(where: whereClause);
        if (tempList.length > 1) debugPrint('⁉️: class property ${declaration.columnName} as \${tempList.length} records!');
        item['${declaration.columnName}'] = tempList.first;''';
        generatorIO.add([code]);
        continue;
      }
    }
    if (!first) generatorIO.add(['}'], padding: Headers.levelIndent(2));
    generatorIO.add(['    return result;', '}'], padding: Headers.classIndent);
  }
}
